<#
.SYNOPSIS
    Installs and configures Bewust ICT Security Check for Microsoft Edge.

.DESCRIPTION
    Beta installer used by Bootstrap.ps1 and NinjaOne. Edge is the primary supported browser in this beta.
    Chrome support remains parameterized but is not production-ready yet.
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

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot
$LogDirectory = 'C:\ProgramData\BewustICT\Check\Logs'
$LogFile = Join-Path $LogDirectory 'Install-BewustICT-Check-vNext.log'

$ExtensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
$EdgeUpdateUrl = 'https://edge.microsoft.com/extensionwebstorebase/v1/crx'
$ChromeUpdateUrl = 'https://clients2.google.com/service/update2/crx'

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
    if (-not (Test-Path $LogDirectory)) { New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null }
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $LogFile -Value $line
    Write-Output $line
}

function Import-CommonModule {
    param([string]$Name)
    $path = Join-Path $RepoRoot "Common\$Name"
    if (Test-Path $path) {
        Import-Module $path -Force
        Write-Log "Imported module: $Name"
    } else {
        Write-Log "Module not found, using built-in fallback: $Name" 'WARN'
    }
}

function Ensure-Key { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null } }
function Set-Str { param([string]$Path,[string]$Name,[string]$Value) Ensure-Key $Path; New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null }
function Set-Dword { param([string]$Path,[string]$Name,[int]$Value) Ensure-Key $Path; New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null }
function Remove-Key { param([string]$Path) if (Test-Path $Path) { Write-Log "Removing key: $Path"; Remove-Item -Path $Path -Recurse -Force } }
function Remove-RegValue { param([string]$Path,[string]$Name) if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue } }

function Get-TenantFromDsregFallback {
    $result = [ordered]@{ TenantId = ''; TenantName = ''; Source = 'none' }
    if (-not (Get-Command dsregcmd.exe -ErrorAction SilentlyContinue)) { return [pscustomobject]$result }
    $raw = & dsregcmd.exe /status 2>$null
    foreach ($line in $raw) {
        if ($line -match '^\s*TenantId\s*:\s*(.+)$') { $result.TenantId = $Matches[1].Trim() }
        if ($line -match '^\s*TenantName\s*:\s*(.+)$') { $result.TenantName = $Matches[1].Trim() }
    }
    if (-not [string]::IsNullOrWhiteSpace($result.TenantId)) { $result.Source = 'dsregcmd TenantId' }
    elseif (-not [string]::IsNullOrWhiteSpace($result.TenantName)) { $result.Source = 'dsregcmd TenantName' }
    return [pscustomobject]$result
}

function Set-CheckPolicyValues {
    param([string]$PolicyPath,[string]$BrandingPath)

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
    } else {
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

function Configure-EdgePolicy {
    $PolicyRoot = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    $ExtPath = Join-Path $PolicyRoot "ExtensionSettings\$ExtensionId"
    $PolicyPath = Join-Path $PolicyRoot "3rdparty\extensions\$ExtensionId\policy"
    $BrandingPath = Join-Path $PolicyPath 'customBranding'

    Write-Log 'Configuring Microsoft Edge policy.'

    Set-Str $ExtPath 'installation_mode' 'force_installed'
    Set-Str $ExtPath 'update_url' $EdgeUpdateUrl
    Remove-RegValue $ExtPath 'toolbar_state'

    Set-CheckPolicyValues -PolicyPath $PolicyPath -BrandingPath $BrandingPath

    Write-Log 'Microsoft Edge policy configured.'
}

function Configure-ChromePolicyBeta {
    $PolicyRoot = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
    $ExtPath = Join-Path $PolicyRoot "ExtensionSettings\$ExtensionId"
    $PolicyPath = Join-Path $PolicyRoot "3rdparty\extensions\$ExtensionId\policy"
    $BrandingPath = Join-Path $PolicyPath 'customBranding'

    Write-Log 'Configuring Google Chrome policy beta.' 'WARN'

    Set-Str $ExtPath 'installation_mode' 'force_installed'
    Set-Str $ExtPath 'update_url' $ChromeUpdateUrl
    Remove-RegValue $ExtPath 'toolbar_state'

    Set-CheckPolicyValues -PolicyPath $PolicyPath -BrandingPath $BrandingPath
}

try {
    Write-Log 'Starting vNext Edge beta deployment.'

    Import-CommonModule 'TenantDiscovery.psm1'
    Import-CommonModule 'Validation.psm1'

    if ($EnableCippReporting -and $AutoDiscoverTenant -and [string]::IsNullOrWhiteSpace($CippTenantId)) {
        if (Get-Command Get-BICTTenantIdentifier -ErrorAction SilentlyContinue) {
            $tenant = Get-BICTTenantIdentifier -Preferred Auto
            $CippTenantId = $tenant.Identifier
            Write-Log "Tenant discovery result: $CippTenantId ($($tenant.Source))"
        } else {
            $tenant = Get-TenantFromDsregFallback
            if (-not [string]::IsNullOrWhiteSpace($tenant.TenantId)) { $CippTenantId = $tenant.TenantId }
            elseif (-not [string]::IsNullOrWhiteSpace($tenant.TenantName)) { $CippTenantId = $tenant.TenantName }
            Write-Log "Tenant discovery fallback result: $CippTenantId ($($tenant.Source))"
        }

        if ([string]::IsNullOrWhiteSpace($CippTenantId)) {
            Write-Log 'CIPP Reporting enabled, but tenant could not be auto discovered.' 'WARN'
        }
    }

    Remove-Key "HKLM:\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\$ExtensionId"
    Configure-EdgePolicy

    if ($ConfigureChrome) {
        Remove-Key "HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\extensions\$ExtensionId"
        Configure-ChromePolicyBeta
    }

    if (Get-Command Test-BICTEdgePolicy -ErrorAction SilentlyContinue) {
        $validation = Test-BICTEdgePolicy -RequireCippReporting:$EnableCippReporting
        if (-not $validation.Compliant) {
            $validation.Failures | ForEach-Object { Write-Log "Validation failure: $_" 'ERROR' }
            exit 1
        }
    }

    Write-Log 'vNext Edge beta deployment finished successfully.'
    exit 0
} catch {
    Write-Log "vNext deployment failed: $($_.Exception.Message)" 'ERROR'
    exit 1
}
