<#
.SYNOPSIS
    Detects whether Bewust ICT Security Check policies are present.

.DESCRIPTION
    Returns exit code 0 when Edge policy is correctly configured.
    Returns exit code 1 when remediation/install is required.

.NOTES
    Designed for NinjaOne condition/detection.
#>

[CmdletBinding()]
param(
    [switch]$RequireChrome,
    [switch]$RequireCippReporting
)

$ErrorActionPreference = 'Stop'
$ExtensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
$ExpectedCompany = 'Bewust ICT'
$ExpectedProduct = 'Bewust ICT Security Check'
$ExpectedColor = '#63B1BC'
$ExpectedCippUrl = 'https://cipp.bewustcloud.nl'

function Test-BrowserPolicy {
    param(
        [ValidateSet('Edge', 'Chrome')]
        [string]$Browser
    )

    switch ($Browser) {
        'Edge' { $PolicyRoot = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' }
        'Chrome' { $PolicyRoot = 'HKLM:\SOFTWARE\Policies\Google\Chrome' }
    }

    $ExtensionSettingsPath = Join-Path $PolicyRoot "ExtensionSettings\$ExtensionId"
    $PolicyPath = Join-Path $PolicyRoot "3rdparty\extensions\$ExtensionId\policy"
    $BrandingPath = Join-Path $PolicyPath 'customBranding'

    $failures = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path $ExtensionSettingsPath)) { $failures.Add("$Browser missing ExtensionSettings") }
    if (-not (Test-Path $PolicyPath)) { $failures.Add("$Browser missing 3rdparty policy") }
    if (-not (Test-Path $BrandingPath)) { $failures.Add("$Browser missing customBranding") }

    if ($failures.Count -eq 0) {
        $extensionSettings = Get-ItemProperty -Path $ExtensionSettingsPath
        $policy = Get-ItemProperty -Path $PolicyPath
        $branding = Get-ItemProperty -Path $BrandingPath

        if ($extensionSettings.installation_mode -ne 'force_installed') { $failures.Add("$Browser installation_mode is not force_installed") }
        if ($extensionSettings.toolbar_state -ne 'force_shown') { $failures.Add("$Browser toolbar_state is not force_shown") }
        if ($branding.companyName -ne $ExpectedCompany) { $failures.Add("$Browser companyName mismatch") }
        if ($branding.productName -ne $ExpectedProduct) { $failures.Add("$Browser productName mismatch") }
        if ($branding.primaryColor -ne $ExpectedColor) { $failures.Add("$Browser primaryColor mismatch") }
        if ([int]$policy.enablePageBlocking -ne 1) { $failures.Add("$Browser page blocking is not enabled") }

        if ($RequireCippReporting) {
            if ([int]$policy.enableCippReporting -ne 1) { $failures.Add("$Browser CIPP reporting is not enabled") }
            if ($policy.cippServerUrl -ne $ExpectedCippUrl) { $failures.Add("$Browser CIPP URL mismatch") }
            if ([string]::IsNullOrWhiteSpace($policy.cippTenantId)) { $failures.Add("$Browser CIPP tenant ID is empty") }
        }
    }

    return $failures
}

try {
    $allFailures = New-Object System.Collections.Generic.List[string]

    foreach ($failure in (Test-BrowserPolicy -Browser 'Edge')) { $allFailures.Add($failure) }

    if ($RequireChrome) {
        foreach ($failure in (Test-BrowserPolicy -Browser 'Chrome')) { $allFailures.Add($failure) }
    }

    if ($allFailures.Count -eq 0) {
        Write-Output 'Compliant: Bewust ICT Security Check policy is configured.'
        exit 0
    }

    Write-Output 'Non-compliant:'
    $allFailures | ForEach-Object { Write-Output "- $_" }
    exit 1
}
catch {
    Write-Output "Detection failed: $($_.Exception.Message)"
    exit 1
}
