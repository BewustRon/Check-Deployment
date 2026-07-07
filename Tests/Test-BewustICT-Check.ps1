Import-Module "$PSScriptRoot\..\Common\Validation.psm1" -Force

$result = Test-BICTEdgePolicy

if ($result.Compliant) {
    Write-Host 'PASS - Bewust ICT Check configuration is compliant.' -ForegroundColor Green
    exit 0
}

Write-Host 'FAIL - Configuration issues found:' -ForegroundColor Red
$result.Failures | ForEach-Object { Write-Host " - $_" }
exit 1