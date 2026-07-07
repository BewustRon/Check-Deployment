function Test-BICTEdgePolicy {
    [CmdletBinding()]
    param(
        [switch]$RequireCippReporting
    )

    $extensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
    $root = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    $extensionSettings = Join-Path $root "ExtensionSettings\$extensionId"
    $policy = Join-Path $root "3rdparty\extensions\$extensionId\policy"
    $branding = Join-Path $policy 'customBranding'

    $failures = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path $extensionSettings)) { $failures.Add('Missing Edge ExtensionSettings policy') }
    if (-not (Test-Path $policy)) { $failures.Add('Missing Edge 3rdparty policy') }
    if (-not (Test-Path $branding)) { $failures.Add('Missing Edge custom branding policy') }

    if ($failures.Count -eq 0) {
        $ext = Get-ItemProperty -Path $extensionSettings
        $pol = Get-ItemProperty -Path $policy
        $brand = Get-ItemProperty -Path $branding

        if ($ext.installation_mode -ne 'force_installed') { $failures.Add('Edge extension is not force_installed') }
        if ($ext.toolbar_state -ne 'force_shown') { $failures.Add('Edge toolbar_state is not force_shown') }
        if ($brand.companyName -ne 'Bewust ICT') { $failures.Add('Branding companyName mismatch') }
        if ($brand.productName -ne 'Bewust ICT Security Check') { $failures.Add('Branding productName mismatch') }
        if ($brand.primaryColor -ne '#63B1BC') { $failures.Add('Branding primaryColor mismatch') }
        if ([int]$pol.enablePageBlocking -ne 1) { $failures.Add('Page blocking is not enabled') }

        if ($RequireCippReporting) {
            if ([int]$pol.enableCippReporting -ne 1) { $failures.Add('CIPP reporting is not enabled') }
            if ($pol.cippServerUrl -ne 'https://cipp.bewustcloud.nl') { $failures.Add('CIPP server URL mismatch') }
            if ([string]::IsNullOrWhiteSpace($pol.cippTenantId)) { $failures.Add('CIPP tenant ID is empty') }
        }
    }

    return [pscustomobject]@{
        Compliant = ($failures.Count -eq 0)
        Failures = @($failures)
    }
}

Export-ModuleMember -Function Test-BICTEdgePolicy
