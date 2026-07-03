<#
.SYNOPSIS
    Removes Bewust ICT Security Check managed policies.

.DESCRIPTION
    Removes Edge and optionally Chrome enterprise policy keys for the Check extension.
    This removes the managed force-install policy. Browser cleanup happens after browser policy refresh/restart.

.NOTES
    Run as Administrator / SYSTEM.
#>

[CmdletBinding()]
param(
    [switch]$RemoveChrome,
    [switch]$KillBrowsers
)

$ErrorActionPreference = 'Stop'
$ExtensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
$LogDirectory = 'C:\ProgramData\BewustICT\Check'
$LogFile = Join-Path $LogDirectory 'Uninstall-BewustICT-Check.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    if (-not (Test-Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $LogFile -Value $line
    Write-Output $line
}

function Remove-KeyIfExists {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Log "Removing key: $Path"
        Remove-Item -Path $Path -Recurse -Force
    }
}

try {
    Write-Log 'Starting Bewust ICT Security Check policy removal.'

    Remove-KeyIfExists -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionSettings\$ExtensionId"
    Remove-KeyIfExists -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\$ExtensionId"

    if ($RemoveChrome) {
        Remove-KeyIfExists -Path "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionSettings\$ExtensionId"
        Remove-KeyIfExists -Path "HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\extensions\$ExtensionId"
    }

    if ($KillBrowsers) {
        Get-Process msedge, chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Log 'Browser processes stopped.'
    }

    Write-Log 'Removal finished successfully.'
    exit 0
}
catch {
    Write-Log "Removal failed: $($_.Exception.Message)" 'ERROR'
    exit 1
}
