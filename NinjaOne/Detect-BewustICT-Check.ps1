<#
.SYNOPSIS
    Detects whether Bewust ICT Security Check policies are compliant.

.DESCRIPTION
    Returns exit code 0 when the required browser policies are compliant.
    Returns exit code 1 when remediation is required.

.NOTES
    Designed for NinjaOne condition/detection and SYSTEM context.
#>

[CmdletBinding()]
param(
    [switch]$RequireChrome,
    [switch]$RequireCippReporting
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot
$ValidationModule = Join-Path $RepoRoot 'Common\Validation.psm1'

try {
    if (-not (Test-Path $ValidationModule)) {
        throw "Validation module not found: $ValidationModule"
    }

    Import-Module $ValidationModule -Force

    $results = New-Object System.Collections.Generic.List[object]
    $results.Add((Test-BICTEdgePolicy -RequireCippReporting:$RequireCippReporting))

    if ($RequireChrome) {
        $results.Add((Test-BICTChromePolicy -RequireCippReporting:$RequireCippReporting))
    }

    $failures = @($results | ForEach-Object { $_.Failures })

    if ($failures.Count -eq 0) {
        $browsers = ($results | ForEach-Object { $_.Browser }) -join ', '
        Write-Output "Compliant: Bewust ICT Security Check policy is configured for $browsers."
        exit 0
    }

    Write-Output 'Non-compliant:'
    $failures | ForEach-Object { Write-Output "- $_" }
    exit 1
}
catch {
    Write-Output "Detection failed: $($_.Exception.Message)"
    exit 1
}
