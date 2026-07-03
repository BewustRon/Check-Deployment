<#
.SYNOPSIS
    vNext installer for Bewust ICT Security Check.

.DESCRIPTION
    Adds automatic tenant discovery using dsregcmd. This script is intended to replace the first Install script after testing.
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

$ExtensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
$EdgeUpdateUrl = 'https://edge.microsoft.com/extensionwebstorebase/v1/crx'
$ChromeUpdateUrl = 'https://clients2.google.com/service/update2/crx'
$LogDirectory = 'C:\ProgramData\BewustICT\Check'
$LogFile = Join-Path $LogDirectory 'Install-BewustICT-Check-vNext.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    if (-not (Test-Path $LogDirectory)) { New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null }
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $LogFile -Value $line
    Write-Output $line
}

function Get-TenantFromDsreg {
    $result = [ordered]@{ TenantId = ''; TenantName = ''; Source = 'none' }
    if (-not (Get-Command dsregcmd.exe -ErrorAction SilentlyContinue)) { return [pscustomobject]$result }

    $raw = & dsregcmd.exe /status 2>$null
    foreach ($line in $raw) {
        if ($line -match '^\s*TenantId\s*:\s*(.+)$') { $result.TenantId = $Matches[1].Trim() }
        if ($line -match '^\s*TenantName\s*:\s*(.+)$') { $result.TenantName = $Matches[1].Trim() }
    }

    if (-not [string]::IsNullOrWhiteSpace($result.TenantId)) {
        $result.Source = 'dsregcmd TenantId'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($result.TenantName)) {
        $result.Source = 'dsregcmd TenantName'
    }

    return [pscustomobject]$result
}

function Ensure-Key { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null } }
function Set-Str { param([string]$Path,[string]$Name,[string]$Value) Ensure-Key $Path; New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null }
function Set-Dword { param([string]$Path,[string]$Name,[int]$Value) Ensure-Key $Path; New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null }
function Remove-Key { param([string]$Path) if (Test-Path $Path) { Write-Log "Removing key: $Path"; Remove-Item -Path $Path -Recurse -Force } }

function Configure-Browser {
    param([ValidateSet('Edge','Chrome')][string]$Browser)

    if ($Browser -eq 'Edge') {
        $PolicyRoot = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
        $UpdateUrl = $EdgeUpdateUrl
    } else {
        $PolicyRoot = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
        $UpdateUrl = $ChromeUpdateUrl
    }

    $ExtPath = Join-Path $PolicyRoot "ExtensionSettings\$ExtensionId"
    $PolicyPath = Join-Path $PolicyRoot "3rdparty\extensions\$ExtensionId\policy"
    $BrandingPath = Join-Path $PolicyPath 'customBranding'

    Set-Str $ExtPath 'installation_mode' 'force_installed'
    Set-Str $ExtPath 'update_url' $UpdateUrl
    Set-Str $ExtPath 'toolbar_state' 'force_shown'

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

    Set-Str $BrandingPath 'companyName' 'Bewust ICT'
    Set-Str $BrandingPath 'productName' $ProductName
    Set-Str $BrandingPath 'companyURL' 'https://www.bewustict.nl'
    Set-Str $BrandingPath 'supportEmail' 'noc@bewustict.nl'
    Set-Str $BrandingPath 'supportUrl' 'https://www.bewustict.nl'
    Set-Str $BrandingPath 'privacyPolicyUrl' 'https://bewustict.nl/privacy_verklaring/'
    Set-Str $BrandingPath 'aboutUrl' 'https://www.bewustict.nl'
    Set-Str $BrandingPath 'primaryColor' '#63B1BC'
    Set-Str $BrandingPath 'logoUrl' 'https://bewustict.nl/wp-content/uploads/2025/10/Logo-zonder-beeldberk.svg'

    Write-Log "$Browser configured."
}

try {
    Write-Log 'Starting vNext deployment.'

    if ($EnableCippReporting -and $AutoDiscoverTenant -and [string]::IsNullOrWhiteSpace($CippTenantId)) {
        $tenant = Get-TenantFromDsreg
        if (-not [string]::IsNullOrWhiteSpace($tenant.TenantId)) {
            $CippTenantId = $tenant.TenantId
            Write-Log "Auto discovered CIPP tenant identifier: $CippTenantId ($($tenant.Source))"
        } elseif (-not [string]::IsNullOrWhiteSpace($tenant.TenantName)) {
            $CippTenantId = $tenant.TenantName
            Write-Log "Auto discovered CIPP tenant identifier: $CippTenantId ($($tenant.Source))"
        } else {
            Write-Log 'CIPP Reporting enabled, but tenant could not be auto discovered.' 'WARN'
        }
    }

    Remove-Key "HKLM:\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\$ExtensionId"
    Remove-Key "HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\extensions\$ExtensionId"

    Configure-Browser -Browser Edge
    if ($ConfigureChrome) { Configure-Browser -Browser Chrome }

    Write-Log 'vNext deployment finished successfully.'
    exit 0
} catch {
    Write-Log "vNext deployment failed: $($_.Exception.Message)" 'ERROR'
    exit 1
}
