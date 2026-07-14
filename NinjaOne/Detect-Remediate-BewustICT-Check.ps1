<#
.SYNOPSIS
    Detects and remediates Bewust ICT Security Check in one NinjaOne automation.

.DESCRIPTION
    Runs local compliance detection when the current repository is present.
    When the device is missing, outdated, or non-compliant, the script downloads
    Bootstrap.ps1, performs remediation, and validates the device again.

    Exit code 0 means the device is compliant.
    Exit code 1 means detection or remediation failed.

.NOTES
    Designed for NinjaOne SYSTEM context.
#>

[CmdletBinding()]
param(
    [switch]$EnableCippReporting,
    [string]$CippTenantId = '',
    [switch]$ForceUpdate
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Root = 'C:\ProgramData\BewustICT\Check'
$MinimumVersion = [version]'0.9.6'
$BootstrapUrl = 'https://raw.githubusercontent.com/BewustRon/Check-Deployment/main/Bootstrap.ps1'
$BootstrapFile = Join-Path $env:TEMP "BewustICT-Check-Bootstrap-$([guid]::NewGuid().ToString('N')).ps1"

$PowerShellExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
if ($env:PROCESSOR_ARCHITEW6432) {
    $PowerShellExe = "$env:SystemRoot\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
}

function Invoke-LocalDetection {
    $result = [ordered]@{
        ExitCode = 1
        Output   = @()
    }

    $VersionFile = Join-Path $Root 'version.json'
    $CurrentPath = Join-Path $Root 'Current'

    if (-not (Test-Path $VersionFile)) {
        $result.Output = @('NONCOMPLIANT - Bewust ICT Security Check is not installed.')
        return [pscustomobject]$result
    }

    try {
        $metadata = Get-Content -Path $VersionFile -Raw | ConvertFrom-Json
        $installedVersion = [version]$metadata.version
    }
    catch {
        $result.Output = @('NONCOMPLIANT - Local version metadata is invalid.')
        return [pscustomobject]$result
    }

    if ($installedVersion -lt $MinimumVersion) {
        $result.Output = @("NONCOMPLIANT - Installed version $installedVersion is older than required version $MinimumVersion.")
        return [pscustomobject]$result
    }

    $repoRoot = Get-ChildItem -Path $CurrentPath -Directory -Filter 'Check-Deployment-*' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $repoRoot) {
        $result.Output = @('NONCOMPLIANT - Local repository is missing.')
        return [pscustomobject]$result
    }

    $detectScript = Join-Path $repoRoot.FullName 'NinjaOne\Detect-BewustICT-Check.ps1'
    if (-not (Test-Path $detectScript)) {
        $result.Output = @('NONCOMPLIANT - Local detection script is missing.')
        return [pscustomobject]$result
    }

    $detectionOutput = @(& $PowerShellExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $detectScript 2>&1)
    $result.ExitCode = [int]$LASTEXITCODE
    $result.Output = $detectionOutput | ForEach-Object { $_.ToString() }

    return [pscustomobject]$result
}

try {
    Write-Output 'Starting Bewust ICT Security Check compliance check.'

    $initialDetection = Invoke-LocalDetection
    $initialDetection.Output | ForEach-Object { Write-Output $_ }
    Write-Output "Initial detection exit code: $($initialDetection.ExitCode)"

    if ($initialDetection.ExitCode -eq 0 -and -not $ForceUpdate) {
        Write-Output 'COMPLIANT - No remediation is required.'
        exit 0
    }

    Write-Output 'NONCOMPLIANT - Starting remediation.'
    Write-Output "Downloading Bootstrap from $BootstrapUrl"

    Invoke-WebRequest -Uri $BootstrapUrl -OutFile $BootstrapFile -UseBasicParsing
    if (-not (Test-Path $BootstrapFile)) {
        throw 'Bootstrap download failed.'
    }

    $bootstrapArguments = @(
        '-NoProfile'
        '-NonInteractive'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        $BootstrapFile
        '-ForceUpdate'
    )

    if ($EnableCippReporting) {
        $bootstrapArguments += '-EnableCippReporting'
    }

    if (-not [string]::IsNullOrWhiteSpace($CippTenantId)) {
        $bootstrapArguments += @('-CippTenantId', $CippTenantId)
    }

    & $PowerShellExe @bootstrapArguments
    $remediationExitCode = [int]$LASTEXITCODE
    Write-Output "Remediation exit code: $remediationExitCode"

    if ($remediationExitCode -ne 0) {
        throw "Bootstrap remediation failed with exit code $remediationExitCode."
    }

    $finalDetection = Invoke-LocalDetection
    $finalDetection.Output | ForEach-Object { Write-Output $_ }
    Write-Output "Final detection exit code: $($finalDetection.ExitCode)"

    if ($finalDetection.ExitCode -ne 0) {
        throw 'Device is still non-compliant after remediation.'
    }

    Write-Output 'SUCCESS - Device is compliant after remediation.'
    exit 0
}
catch {
    Write-Output "FAILURE - $($_.Exception.Message)"
    exit 1
}
finally {
    Remove-Item -Path $BootstrapFile -Force -ErrorAction SilentlyContinue
}
