[CmdletBinding()]
param(
    [switch]$RequireChrome,
    [switch]$RequireCippReporting
)

$ErrorActionPreference = 'Stop'
$ValidationModule = Join-Path $PSScriptRoot '..\Common\Validation.psm1'

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
        Write-Output "PASS - Bewust ICT Check is compliant for $browsers."
        exit 0
    }

    Write-Output 'FAIL - Configuration issues found:'
    $failures | ForEach-Object { Write-Output "- $_" }
    exit 1
}
catch {
    Write-Output "FAIL - Validation failed: $($_.Exception.Message)"
    exit 1
}
