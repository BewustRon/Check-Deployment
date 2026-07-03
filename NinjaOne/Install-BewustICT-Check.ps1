<#
.SYNOPSIS
    Installs and configures Bewust ICT Security Check for Edge and optionally Chrome.

.DESCRIPTION
    This script writes Chrome/Edge enterprise policy registry keys for Check by CyberDrain.
    It removes legacy Theiner ICT custom branding/policy keys for the same extension ID and applies Bewust ICT branding.

.NOTES
    Run as Administrator / SYSTEM.
    Intended for NinjaOne, but also usable as a normal PowerShell script.

    CIPP Reporting:
    The available policy names are based on observed managed policy registry values.
    Validate with a real alert before large scale production rollout.
#>

[CmdletBinding()]
param(
    [switch]$ConfigureChrome,

    [switch]$EnableCippReporting,

    [string]$CippServerUrl = 'https://cipp.bewustcloud.nl',

    [string]$CippTenantId = '',

    [string]$ProductName = 'Bewust ICT Security Check'
)

$ErrorActionPreference = 'Stop'

$ExtensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
$EdgeUpdateUrl = 'https://edge.microsoft.com/extensionwebstorebase/v1/crx'
$ChromeUpdateUrl = 'https://clients2.google.com/service/update2/crx'
$LogDirectory = 'C:\ProgramData\BewustICT\Check'
$LogFile = Join-Path $LogDirectory 'Install-BewustICT-Check.log'

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

function Set-StringValue {
    param([string]$Path, [string]$Name, [string]$Value)
    Ensure-Key -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
}

function Set-DwordValue {
    param([string]$Path, [string]$Name, [int]$Value)
    Ensure-Key -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

function Remove-KeyIfExists {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Log "Removing key: $Path"
        Remove-Item -Path $Path -Recurse -Force
    }
}

function Configure-BrowserCheckPolicy {
    param(
        [ValidateSet('Edge', 'Chrome')]
        [string]$Browser
    )

    switch ($Browser) {
        'Edge' {
            $PolicyRoot = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
            $UpdateUrl = $EdgeUpdateUrl
        }
        'Chrome' {
            $PolicyRoot = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
            $UpdateUrl = $ChromeUpdateUrl
        }
    }

    $ExtensionSettingsPath = Join-Path $PolicyRoot "ExtensionSettings\$ExtensionId"
    $PolicyPath = Join-Path $PolicyRoot "3rdparty\extensions\$ExtensionId\policy"
    $BrandingPath = Join-Path $PolicyPath 'customBranding'

    Write-Log "Configuring $Browser policy root: $PolicyRoot"

    Ensure-Key -Path $ExtensionSettingsPath
    Set-StringValue -Path $ExtensionSettingsPath -Name 'installation_mode' -Value 'force_installed'
    Set-StringValue -Path $ExtensionSettingsPath -Name 'update_url' -Value $UpdateUrl
    Set-StringValue -Path $ExtensionSettingsPath -Name 'toolbar_state' -Value 'force_shown'

    Ensure-Key -Path $PolicyPath
    Set-DwordValue -Path $PolicyPath -Name 'showNotifications' -Value 1
    Set-DwordValue -Path $PolicyPath -Name 'enableValidPageBadge' -Value 0
    Set-DwordValue -Path $PolicyPath -Name 'enablePageBlocking' -Value 1
    Set-DwordValue -Path $PolicyPath -Name 'enableDebugLogging' -Value 0
    Set-DwordValue -Path $PolicyPath -Name 'updateInterval' -Value 1

    if ($EnableCippReporting) {
        Set-DwordValue -Path $PolicyPath -Name 'enableCippReporting' -Value 1
        Set-StringValue -Path $PolicyPath -Name 'cippServerUrl' -Value $CippServerUrl
        Set-StringValue -Path $PolicyPath -Name 'cippTenantId' -Value $CippTenantId
    }
    else {
        Set-DwordValue -Path $PolicyPath -Name 'enableCippReporting' -Value 0
        Set-StringValue -Path $PolicyPath -Name 'cippServerUrl' -Value ''
        Set-StringValue -Path $PolicyPath -Name 'cippTenantId' -Value ''
    }

    Set-StringValue -Path $PolicyPath -Name 'customRulesUrl' -Value ''

    Ensure-Key -Path $BrandingPath
    Set-StringValue -Path $BrandingPath -Name 'companyName' -Value 'Bewust ICT'
    Set-StringValue -Path $BrandingPath -Name 'productName' -Value $ProductName
    Set-StringValue -Path $BrandingPath -Name 'companyURL' -Value 'https://www.bewustict.nl'
    Set-StringValue -Path $BrandingPath -Name 'supportEmail' -Value 'noc@bewustict.nl'
    Set-StringValue -Path $BrandingPath -Name 'supportUrl' -Value 'https://www.bewustict.nl'
    Set-StringValue -Path $BrandingPath -Name 'privacyPolicyUrl' -Value 'https://bewustict.nl/privacy_verklaring/'
    Set-StringValue -Path $BrandingPath -Name 'aboutUrl' -Value 'https://www.bewustict.nl'
    Set-StringValue -Path $BrandingPath -Name 'primaryColor' -Value '#63B1BC'
    Set-StringValue -Path $BrandingPath -Name 'logoUrl' -Value 'https://bewustict.nl/wp-content/uploads/2025/10/Logo-zonder-beeldberk.svg'

    Write-Log "$Browser policy configured."
}

try {
    Write-Log 'Starting Bewust ICT Security Check deployment.'

    # Legacy cleanup for older Theiner branded policy values for this extension ID.
    # These are removed before applying the new Bewust ICT managed policy.
    Remove-KeyIfExists -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\$ExtensionId"
    Remove-KeyIfExists -Path "HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\extensions\$ExtensionId"

    Configure-BrowserCheckPolicy -Browser 'Edge'

    if ($ConfigureChrome) {
        Configure-BrowserCheckPolicy -Browser 'Chrome'
    }

    Write-Log 'Deployment finished successfully.'
    exit 0
}
catch {
    Write-Log "Deployment failed: $($_.Exception.Message)" 'ERROR'
    exit 1
}
