$ErrorActionPreference='Stop'
$Root='C:\ProgramData\BewustICT\Check'
$Zip=Join-Path $env:TEMP 'Check-Deployment.zip'
$Repo='https://github.com/BewustRon/Check-Deployment/archive/refs/heads/main.zip'

New-Item -ItemType Directory -Force -Path $Root | Out-Null
Invoke-WebRequest -Uri $Repo -OutFile $Zip
Expand-Archive -Path $Zip -DestinationPath $Root -Force
$Install=Get-ChildItem $Root -Filter 'Install-BewustICT-Check-vNext.ps1' -Recurse | Select-Object -First 1
if(-not $Install){throw 'Install script not found.'}
& $Install.FullName
exit $LASTEXITCODE