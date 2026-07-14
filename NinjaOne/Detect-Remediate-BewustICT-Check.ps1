<#
.SYNOPSIS
    Detects and remediates Bewust ICT Security Check in one NinjaOne automation.

.DESCRIPTION
    Intended to be scheduled frequently from NinjaOne, for example hourly.
    The script stores the timestamp of the last successful compliance check locally and only
    runs the full detection/remediation workflow when the configured interval has elapsed.

    Devices that were offline are therefore checked shortly after they come online again,
    without running the complete validation workflow every hour.

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
    if (-not (Test-Path $StatePath)) {
        return $null
    }

    try {
        $rawValue = (Get-ItemProperty -Path $StatePath -Name $StateName -ErrorAction Stop).$StateName
        if ([string]::IsNullOrWhiteSpace([string]$rawValue)) {
            return $null
        }

        return [datetime]::Parse(
            [string]$rawValue,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind
        ).ToUniversalTime()
    }
    catch {
        Write-Output "Stored check timestamp is invalid and will be ignored: $($_.Exception.Message)"
        return $null
    }
}

function Set-LastSuccessfulCheckUtc {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$Timestamp
    )

    if (-not (Test-Path $StatePath)) {
        New-Item -Path $StatePath -Force | Out-Null
    }

    $value = $Timestamp.ToUniversalTime().ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
    New-ItemProperty -Path $StatePath -Name $StateName -PropertyType String -Value $value -Force | Out-Null
    Write-Output "Recorded successful check time: $value"
}

function Invoke-LocalDetection {
    $result = [ordered]@{
        ExitCode = 1
        Output   = @()
    }

    $versionFile = Join-Path $Root 'version.json'
    $currentPath = Join-Path $Root 'Current'

    if (-not (Test-Path $versionFile)) {
        $result.Output = @('NONCOMPLIANT - Bewust ICT Security Check is not installed.')
        return [pscustomobject]$result
    }

    try {
        $metadata = Get-Content -Path $versionFile -Raw | ConvertFrom-Json
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

    $repoRoot = Get-ChildItem -Path $currentPath -Directory -Filter 'Check-Deployment-*' -ErrorAction SilentlyContinue |
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
    $nowUtc = [datetime]::UtcNow
    $lastSuccessfulCheckUtc = Get-LastSuccessfulCheckUtc

    if ($lastSuccessfulCheckUtc) {
        $nextCheckUtc = $lastSuccessfulCheckUtc.AddDays($CheckIntervalDays)
        Write-Output "Last successful check: $($lastSuccessfulCheckUtc.ToString('o'))"
        Write-Output "Next full check due: $($nextCheckUtc.ToString('o'))"

        if (-not $ForceCheck -and -not $ForceUpdate -and $nowUtc -lt $nextCheckUtc) {
            $remaining = $nextCheckUtc - $nowUtc
            Write-Output ("SKIPPED - A new compliance check is not due yet. Remaining: {0} day(s), {1} hour(s)." -f [math]::Floor($remaining.TotalDays), $remaining.Hours)
            exit 0
        }
    }
    else {
        Write-Output 'No previous successful check is recorded. A full compliance check is required.'
    }

    if ($ForceCheck) {
        Write-Output 'ForceCheck requested. Ignoring the stored check timestamp.'
    }

    Write-Output 'Starting Bewust ICT Security Check compliance check.'

    $initialDetection = Invoke-LocalDetection
    $initialDetection.Output | ForEach-Object { Write-Output $_ }
    Write-Output "Initial detection exit code: $($initialDetection.ExitCode)"

    if ($initialDetection.ExitCode -eq 0 -and -not $ForceUpdate) {
        Set-LastSuccessfulCheckUtc -Timestamp $nowUtc
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

    Set-LastSuccessfulCheckUtc -Timestamp ([datetime]::UtcNow)
    Write-Output 'SUCCESS - Device is compliant after remediation.'
    exit 0
}
catch {
    Write-Output "FAILURE - $($_.Exception.Message)"
    Write-Output 'The successful-check timestamp was not updated, so the next scheduled run will retry.'
    exit 1
}
finally {
    Remove-Item -Path $BootstrapFile -Force -ErrorAction SilentlyContinue
}
