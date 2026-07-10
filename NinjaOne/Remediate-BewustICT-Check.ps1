<#
.SYNOPSIS
    Repairs Bewust ICT Security Check through the public Bootstrap script.

.DESCRIPTION
    Designed for NinjaOne SYSTEM context. The script first runs local detection when available.
    If remediation is needed, it downloads and runs Bootstrap.ps1 from GitHub with matching options.
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

        $detectArgs = @()
        if ($RequireChrome) { $detectArgs += '-RequireChrome' }
        if ($EnableCippReporting) { $detectArgs += '-RequireCippReporting' }

        & $Detect @detectArgs
        if ($LASTEXITCODE -eq 0 -and -not $ForceUpdate) {
            Write-Output 'Device is already compliant.'
            exit 0
        }
    }

    Write-Output "Downloading Bootstrap from $BootstrapUrl"
    Invoke-WebRequest -Uri $BootstrapUrl -OutFile $TempBootstrap -UseBasicParsing

    if (-not (Test-Path $TempBootstrap)) {
        throw 'Bootstrap download failed.'
    }

    $bootstrapArgs = @()
    if ($RequireChrome) { $bootstrapArgs += '-ConfigureChrome' }
    if ($EnableCippReporting) { $bootstrapArgs += '-EnableCippReporting' }
    if (-not [string]::IsNullOrWhiteSpace($CippTenantId)) {
        $bootstrapArgs += @('-CippTenantId', $CippTenantId)
    }
    if ($ForceUpdate) { $bootstrapArgs += '-ForceUpdate' }

    Write-Output 'Starting Bootstrap remediation.'
    & $TempBootstrap @bootstrapArgs
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
