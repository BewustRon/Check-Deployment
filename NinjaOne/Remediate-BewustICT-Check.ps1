<#
.SYNOPSIS
    Repairs Bewust ICT Security Check through the public Bootstrap script.

.DESCRIPTION
    Designed for NinjaOne SYSTEM context. The script first runs local detection when available.
    Detection and Bootstrap both automatically include Google Chrome when it is installed.
#>

[CmdletBinding()]
param(
    [switch]$RequireChrome,
    [switch]$EnableCippReporting,
    [string]$CippTenantId = '',
    [switch]$ForceUpdate
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Detect = Join-Path $ScriptRoot 'Detect-BewustICT-Check.ps1'
$BootstrapUrl = 'https://raw.githubusercontent.com/BewustRon/Check-Deployment/main/Bootstrap.ps1'
$TempBootstrap = Join-Path $env:TEMP 'BewustICT-Check-Bootstrap.ps1'

try {
    if (Test-Path $Detect) {
        Write-Output 'Running compliance detection.'

        $detectParams = @{}
        if ($RequireChrome) { $detectParams.RequireChrome = $true }
        if ($EnableCippReporting) { $detectParams.RequireCippReporting = $true }

        & $Detect @detectParams
        $detectExitCode = $LASTEXITCODE
        Write-Output "Detection exit code: $detectExitCode"

        if ($detectExitCode -eq 0 -and -not $ForceUpdate) {
            Write-Output 'Device is already compliant.'
            exit 0
        }
    }

    Write-Output "Downloading Bootstrap from $BootstrapUrl"
    Invoke-WebRequest -Uri $BootstrapUrl -OutFile $TempBootstrap -UseBasicParsing

    if (-not (Test-Path $TempBootstrap)) {
        throw 'Bootstrap download failed.'
    }

    $bootstrapParams = @{}
    if ($RequireChrome) { $bootstrapParams.ConfigureChrome = $true }
    if ($EnableCippReporting) { $bootstrapParams.EnableCippReporting = $true }
    if (-not [string]::IsNullOrWhiteSpace($CippTenantId)) {
        $bootstrapParams.CippTenantId = $CippTenantId
    }
    if ($ForceUpdate) { $bootstrapParams.ForceUpdate = $true }

    Write-Output 'Starting Bootstrap remediation.'
    & $TempBootstrap @bootstrapParams
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Output 'Remediation completed successfully.'
    }
    else {
        Write-Output "Remediation failed with exit code $exitCode."
    }

    exit $exitCode
}
catch {
    Write-Output "Remediation failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Remove-Item -Path $TempBootstrap -Force -ErrorAction SilentlyContinue
}
