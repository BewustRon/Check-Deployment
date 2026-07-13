Import-Module (Join-Path $PSScriptRoot 'BrowserConfig.psm1') -Force

function Test-BICTBrowserPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Edge','Chrome')]
        [string]$Browser,
        [switch]$RequireCippReporting
    )

    $config = Get-BICTBrowserConfig -Browser $Browser
    $extensionSettings = Join-Path $config.PolicyRoot "ExtensionSettings\$($config.ExtensionId)"
    $policy = Join-Path $config.PolicyRoot "3rdparty\extensions\$($config.ExtensionId)\policy"
    $branding = Join-Path $policy 'customBranding'
    $failures = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path $extensionSettings)) { $failures.Add("Missing $Browser ExtensionSettings policy") }
    if (-not (Test-Path $policy)) { $failures.Add("Missing $Browser 3rdparty policy") }
    if (-not (Test-Path $branding)) { $failures.Add("Missing $Browser custom branding policy") }

    if ($failures.Count -eq 0) {
        $ext = Get-ItemProperty -Path $extensionSettings
        $pol = Get-ItemProperty -Path $policy
        $brand = Get-ItemProperty -Path $branding

        if ($ext.installation_mode -ne 'force_installed') { $failures.Add("$Browser extension is not force_installed") }
        if ($ext.update_url -ne $config.UpdateUrl) { $failures.Add("$Browser update URL mismatch") }
        if ($null -ne $ext.toolbar_state) { $failures.Add("$Browser toolbar_state must be absent so the icon is not force-pinned") }
        if ($brand.companyName -ne 'Bewust ICT') { $failures.Add("$Browser branding companyName mismatch") }
        if ($brand.productName -ne 'Bewust ICT Security Check') { $failures.Add("$Browser branding productName mismatch") }
        if ($brand.primaryColor -ne '#63B1BC') { $failures.Add("$Browser branding primaryColor mismatch") }
        if ($brand.supportUrl -ne 'https://bewustict.nl/support/') { $failures.Add("$Browser branding supportUrl mismatch") }
        if ($brand.logoUrl -ne 'https://raw.githubusercontent.com/BewustRon/Check-Deployment/main/Assets/Bewust-ICT-beeldmerk-wit.svg') { $failures.Add("$Browser branding logoUrl mismatch") }
        if ([int]$pol.enablePageBlocking -ne 1) { $failures.Add("$Browser page blocking is not enabled") }

        if ($RequireCippReporting) {
            if ([int]$pol.enableCippReporting -ne 1) { $failures.Add("$Browser CIPP reporting is not enabled") }
            if ($pol.cippServerUrl -ne 'https://cipp.bewustcloud.nl') { $failures.Add("$Browser CIPP server URL mismatch") }
            if ([string]::IsNullOrWhiteSpace($pol.cippTenantId)) { $failures.Add("$Browser CIPP tenant ID is empty") }
        }
    }

    [pscustomobject]@{
        Browser = $Browser
        ExtensionId = $config.ExtensionId
        Compliant = ($failures.Count -eq 0)
        Failures = @($failures)
    }
}

function Test-BICTEdgePolicy {
    [CmdletBinding()]
    param([switch]$RequireCippReporting)
    Test-BICTBrowserPolicy -Browser Edge -RequireCippReporting:$RequireCippReporting
}

function Test-BICTChromePolicy {
    [CmdletBinding()]
    param([switch]$RequireCippReporting)
    Test-BICTBrowserPolicy -Browser Chrome -RequireCippReporting:$RequireCippReporting
}

Export-ModuleMember -Function Test-BICTBrowserPolicy, Test-BICTEdgePolicy, Test-BICTChromePolicy
