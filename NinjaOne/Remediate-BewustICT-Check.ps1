[CmdletBinding()]
param()

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Detect = Join-Path $ScriptRoot 'Detect-BewustICT-Check.ps1'
$Install = Join-Path $ScriptRoot 'Install-BewustICT-Check-vNext.ps1'

Write-Host 'Running compliance detection...'

& $Detect

if ($LASTEXITCODE -eq 0) {
    Write-Host 'Device is already compliant.'
    exit 0
}

Write-Host 'Non-compliant. Starting remediation...'

& $Install

exit $LASTEXITCODE
