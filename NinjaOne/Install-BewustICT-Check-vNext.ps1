<#
.SYNOPSIS
    Installs and configures Bewust ICT Security Check for Microsoft Edge and Google Chrome.
#>

[CmdletBinding()]
param(
    [switch]$ConfigureChrome,
    [switch]$EnableCippReporting,
    [switch]$AutoDiscoverTenant = $true,
    [string]$CippServerUrl = 'https://cipp.bewustcloud.nl',
    [string]$CippTenantId = '',
    [string]$ProductName = 'Bewust ICT Security Check'
)

$ErrorActionPreference = 'Stop'

$LogDirectory = 'C:\ProgramData\BewustICT\Check\Logs'
$LogFile = Join-Path $LogDirectory 'Install-BewustICT-Check-vNext.log'

$Branding = [pscustomobject]@{
    CompanyName      = 'Bewust ICT'
    ProductName      = $ProductName
    CompanyUrl       = 'https://www.bewustict.nl'
    SupportEmail     = 'noc@bewustict.nl'
    SupportUrl       = 'https://bewustict.nl/support/'
    PrivacyPolicyUrl = 'https://bewustict.nl/privacy_verklaring/'
    AboutUrl         = 'https://www.bewustict.nl'
    PrimaryColor     = '#63B1BC'
    LogoUrl          = 'https://raw.githubusercontent.com/BewustRon/Check-Deployment/main/Assets/Bewust-ICT-beeldmerk-wit.svg'
}

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    if (-not (Test-Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $LogFile -Value $line
    Write-Output $line
}

function Ensure-Key {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-Str {
    param([string]$Path, [string]$Name, [string]$Value)
    Ensure-Key $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
}

function Set-Dword {
    param([string]$Path, [string]$Name, [int]$Value)
    Ensure-Key $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

function Remove-Key {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Log "Removing key: $Path"
        Remove-Item -Path $Path -Recurse -Force
    }
}

function Remove-RegValue {
    param([string]$Path, [string]$Name)
    if (Test-Path $Path) {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    }
}

function Get-BICTBrowserConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Edge', 'Chrome')]
        [string]$Browser
    )

    if ($Browser -eq 'Edge') {
        return [pscustomobject]@{
            BrowserName = 'Microsoft Edge'
            PolicyRoot  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
            ExtensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
            UpdateUrl   = 'https://edge.microsoft.com/extensionwebstorebase/v1/crx'
        }
    }

    return [pscustomobject]@{
        BrowserName = 'Google Chrome'
        PolicyRoot  = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
        ExtensionId = 'benimdeioplgkhanklclahllklceahbe'
        UpdateUrl   = 'https://clients2.google.com/service/update2/crx'
    }
}

function Get-TenantFromDsregFallback {
    $result = [ordered]@{ TenantId = ''; TenantName = ''; Source = 'none' }
    if (-not (Get-Command dsregcmd.exe -ErrorAction SilentlyContinue)) {
        return [pscustomobject]$result
    }

    $raw = & dsregcmd.exe /status 2>$null
    foreach ($line in $raw) {
        if ($line -match '^\s*TenantId\s*:\s*(.+)$') {
            $result.TenantId = $Matches[1].Trim()
        }
        if ($line -match '^\s*TenantName\s*:\s*(.+)$') {
            $result.TenantName = $Matches[1].Trim()
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($result.TenantId)) {
        $result.Source = 'dsregcmd TenantId'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($result.TenantName)) {
        $result.Source = 'dsregcmd TenantName'
    }

    return [pscustomobject]$result
}

function Set-CheckPolicyValues {
    param([string]$PolicyPath, [string]$BrandingPath)

    Set-Dword $PolicyPath 'showNotifications' 1
    Set-Dword $PolicyPath 'enableValidPageBadge' 0
    Set-Dword $PolicyPath 'enablePageBlocking' 1
    Set-Dword $PolicyPath 'enableDebugLogging' 0
    Set-Dword $PolicyPath 'updateInterval' 1
    Set-Str $PolicyPath 'customRulesUrl' ''

    if ($EnableCippReporting) {
        Set-Dword $PolicyPath 'enableCippReporting' 1
        Set-Str $PolicyPath 'cippServerUrl' $CippServerUrl
        Set-Str $PolicyPath 'cippTenantId' $CippTenantId
    }
    else {
        Set-Dword $PolicyPath 'enableCippReporting' 0
        Set-Str $PolicyPath 'cippServerUrl' ''
        Set-Str $PolicyPath 'cippTenantId' ''
    }

    Set-Str $BrandingPath 'companyName' $Branding.CompanyName
    Set-Str $BrandingPath 'productName' $Branding.ProductName
    Set-Str $BrandingPath 'companyURL' $Branding.CompanyUrl
    Set-Str $BrandingPath 'supportEmail' $Branding.SupportEmail
    Set-Str $BrandingPath 'supportUrl' $Branding.SupportUrl
    Set-Str $BrandingPath 'privacyPolicyUrl' $Branding.PrivacyPolicyUrl
    Set-Str $BrandingPath 'aboutUrl' $Branding.AboutUrl
    Set-Str $BrandingPath 'primaryColor' $Branding.PrimaryColor
    Set-Str $BrandingPath 'logoUrl' $Branding.LogoUrl
}

function Configure-BrowserPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Edge', 'Chrome')]
        [string]$Browser
    )

    $config = Get-BICTBrowserConfig -Browser $Browser
    $extPath = Join-Path $config.PolicyRoot "ExtensionSettings\$($config.ExtensionId)"
    $policyPath = Join-Path $config.PolicyRoot "3rdparty\extensions\$($config.ExtensionId)\policy"
    $brandingPath = Join-Path $policyPath 'customBranding'

    Write-Log "Configuring $($config.BrowserName) policy."

    Remove-Key $extPath
    Remove-Key (Join-Path $config.PolicyRoot "3rdparty\extensions\$($config.ExtensionId)")

    if ($Browser -eq 'Chrome') {
        $legacyEdgeExtensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
        Remove-Key (Join-Path $config.PolicyRoot "ExtensionSettings\$legacyEdgeExtensionId")
        Remove-Key (Join-Path $config.PolicyRoot "3rdparty\extensions\$legacyEdgeExtensionId")
    }

    Set-Str $extPath 'installation_mode' 'force_installed'
    Set-Str $extPath 'update_url' $config.UpdateUrl
    Remove-RegValue $extPath 'toolbar_state'
    Set-CheckPolicyValues -PolicyPath $policyPath -BrandingPath $brandingPath

    Write-Log "$($config.BrowserName) policy configured."
}

function Test-BICTBrowserPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Edge', 'Chrome')]
        [string]$Browser,
        [switch]$RequireCippReporting
    )

    $config = Get-BICTBrowserConfig -Browser $Browser
    $extensionSettings = Join-Path $config.PolicyRoot "ExtensionSettings\$($config.ExtensionId)"
    $policy = Join-Path $config.PolicyRoot "3rdparty\extensions\$($config.ExtensionId)\policy"
    $branding = Join-Path $policy 'customBranding'
    $failures = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path $extensionSettings)) {
        $failures.Add("Missing $Browser ExtensionSettings policy")
    }
    if (-not (Test-Path $policy)) {
        $failures.Add("Missing $Browser 3rdparty policy")
    }
    if (-not (Test-Path $branding)) {
        $failures.Add("Missing $Browser custom branding policy")
    }

    if ($failures.Count -eq 0) {
        $ext = Get-ItemProperty -Path $extensionSettings
        $pol = Get-ItemProperty -Path $policy
        $brand = Get-ItemProperty -Path $branding

        if ($ext.installation_mode -ne 'force_installed') {
            $failures.Add("$Browser extension is not force_installed")
        }
        if ($ext.update_url -ne $config.UpdateUrl) {
            $failures.Add("$Browser update URL mismatch")
        }
        if ($null -ne $ext.toolbar_state) {
            $failures.Add("$Browser toolbar_state must be absent so the icon is not force-pinned")
        }
        if ($brand.companyName -ne 'Bewust ICT') {
            $failures.Add("$Browser branding companyName mismatch")
        }
        if ($brand.productName -ne $ProductName) {
            $failures.Add("$Browser branding productName mismatch")
        }
        if ($brand.primaryColor -ne '#63B1BC') {
            $failures.Add("$Browser branding primaryColor mismatch")
        }
        if ($brand.supportUrl -ne 'https://bewustict.nl/support/') {
            $failures.Add("$Browser branding supportUrl mismatch")
        }
        if ($brand.logoUrl -ne 'https://raw.githubusercontent.com/BewustRon/Check-Deployment/main/Assets/Bewust-ICT-beeldmerk-wit.svg') {
            $failures.Add("$Browser branding logoUrl mismatch")
        }
        if ([int]$pol.enablePageBlocking -ne 1) {
            $failures.Add("$Browser page blocking is not enabled")
        }

        if ($RequireCippReporting) {
            if ([int]$pol.enableCippReporting -ne 1) {
                $failures.Add("$Browser CIPP reporting is not enabled")
            }
            if ($pol.cippServerUrl -ne 'https://cipp.bewustcloud.nl') {
                $failures.Add("$Browser CIPP server URL mismatch")
            }
            if ([string]::IsNullOrWhiteSpace($pol.cippTenantId)) {
                $failures.Add("$Browser CIPP tenant ID is empty")
            }
        }
    }

    return [pscustomobject]@{
        Browser   = $Browser
        Compliant = ($failures.Count -eq 0)
        Failures  = @($failures)
    }
}

try {
    Write-Log 'Starting Bewust ICT Check deployment.'
    Write-Log 'Using embedded browser configuration and validation.'

    if ($EnableCippReporting -and $AutoDiscoverTenant -and [string]::IsNullOrWhiteSpace($CippTenantId)) {
        $tenant = Get-TenantFromDsregFallback
        if (-not [string]::IsNullOrWhiteSpace($tenant.TenantId)) {
            $CippTenantId = $tenant.TenantId
        }
        elseif (-not [string]::IsNullOrWhiteSpace($tenant.TenantName)) {
            $CippTenantId = $tenant.TenantName
        }

        Write-Log "Tenant discovery result: $CippTenantId ($($tenant.Source))"

        if ([string]::IsNullOrWhiteSpace($CippTenantId)) {
            Write-Log 'CIPP Reporting enabled, but tenant could not be auto discovered.' 'WARN'
        }
    }

    Configure-BrowserPolicy -Browser Edge

    if ($ConfigureChrome) {
        Configure-BrowserPolicy -Browser Chrome
    }

    $validationResults = New-Object System.Collections.Generic.List[object]
    $validationResults.Add((Test-BICTBrowserPolicy -Browser Edge -RequireCippReporting:$EnableCippReporting))

    if ($ConfigureChrome) {
        $validationResults.Add((Test-BICTBrowserPolicy -Browser Chrome -RequireCippReporting:$EnableCippReporting))
    }

    $validationFailures = @($validationResults | ForEach-Object { $_.Failures })
    if ($validationFailures.Count -gt 0) {
        $validationFailures | ForEach-Object { Write-Log "Validation failure: $_" 'ERROR' }
        exit 1
    }

    Write-Log 'Bewust ICT Check deployment finished successfully.'
    exit 0
}
catch {
    Write-Log "Deployment failed: $($_.Exception.Message)" 'ERROR'
    exit 1
}
