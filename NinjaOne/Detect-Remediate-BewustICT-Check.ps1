<#
.SYNOPSIS
    Detects and remediates Bewust ICT Security Check in one NinjaOne automation.

.DESCRIPTION
    This script is intended to be scheduled frequently from NinjaOne, for example hourly.
    It stores the timestamp of the last successful compliance check locally and only runs
    the full detection/remediation workflow when the configured interval has elapsed.

    This means devices that were offline at the nominal weekly moment are checked shortly
    after they come online again, while compliant devices avoid unnecessary repeated checks.

    Exit code 0 means the device is compliant or a check is not due yet.
    Exit code 1 means detection or remediation failed.

.NOTES
    Designed for NinjaOne SYSTEM context.
#>

[CmdletBinding()]
param(
    [switch]$EnableCippReporting,
    [string]$CippTenantId = '',
    [ValidateRange(1, 90)]
    [int]$CheckIntervalDays = 7,
    [switch]$ForceCheck,
    [switch]$ForceUpdate
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Root = 'C:\ProgramData\BewustICT\Check'
$MinimumVersion = [version]'0.9.6'
$BootstrapUrl = 'https://raw.githubusercontent.com/BewustRon/Check-Deployment/main/Bootstrap.ps1'
$BootstrapFile = Join-Path $env:TEMP "BewustICT-Check-Bootstrap-$([guid]::NewGuid().ToString('N')).ps1"
$StatePath = 'HKLM:\SOFTWARE\BewustICT\SecurityCheck'
$StateName = 'LastSuccessfulCheckUtc'

$PowerShellExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
if ($env:PROCESSOR_ARCHITEW6432) {
    $PowerShellExe = "$env:SystemRoot\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
}

function Get-LastSuccessfulCheckUtc {
    if (-not