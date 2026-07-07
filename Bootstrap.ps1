[CmdletBinding()]
param(
    [switch]$EnableCippReporting,
    [string]$CippTenantId = '',
    [switch]$ConfigureChrome
)

$ErrorActionPreference = 'Stop'
$Root = 'C:\ProgramData\BewustICT\Check'
$Work = Join-Path $Root 'Current'
$Backup = Join-Path $Root 'Previous'
$LogDir = Join-Path $Root 'Logs'
$Zip = Join-Path $env:TEMP 'Check-Deployment-main.zip'
$Repo = 'https://github.com/BewustRon/Check-Deployment/archive/refs/heads/main.zip'
$Log = Join-Path $LogDir 'Bootstrap.log'

function Write-BootstrapLog {
    param([string]$Message,[string]$Level='INFO')
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $Log -Value $line
    Write-Output $line
}

try {
    Write-BootstrapLog 'Starting Bewust ICT Check bootstrap.'

    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

    Write-BootstrapLog "Downloading repository from $Repo"
    Invoke-WebRequest -Uri $Repo -OutFile $Zip -UseBasicParsing

    if (Test-Path $Backup) { Remove-Item -Path $Backup -Recurse -Force }
    if (Test-Path $Work) { Rename-Item -Path $Work -NewName 'Previous' -Force }

    New-Item -ItemType Directory -Force -Path $Work | Out-Null
    Expand-Archive -Path $Zip -DestinationPath $Work -Force

    $RepoRoot = Get-ChildItem -Path $Work -Directory | Where-Object { $_.Name -like 'Check-Deployment-*' } | Select-Object -First 1
    if (-not $RepoRoot) { throw 'Repository root not found after extraction.' }

    $Install = Join-Path $RepoRoot.FullName 'NinjaOne\Install-BewustICT-Check-vNext.ps1'
    $Test = Join-Path $RepoRoot.FullName 'Tests\Test-BewustICT-Check.ps1'

    if (-not (Test-Path $Install)) { throw "Install script not found: $Install" }
    if (-not (Test-Path $Test)) { throw "Test script not found: $Test" }

    $installArgs = @()
    if ($EnableCippReporting) { $installArgs += '-EnableCippReporting' }
    if (-not [string]::IsNullOrWhiteSpace($CippTenantId)) { $installArgs += @('-CippTenantId', $CippTenantId) }
    if ($ConfigureChrome) { $installArgs += '-ConfigureChrome' }

    Write-BootstrapLog "Running install script: $Install"
    & $Install @installArgs
    $installExit = $LASTEXITCODE
    Write-BootstrapLog "Install script exit code: $installExit"
    if ($installExit -ne 0) { exit $installExit }

    Write-BootstrapLog "Running validation script: $Test"
    & $Test
    $testExit = $LASTEXITCODE
    Write-BootstrapLog "Validation exit code: $testExit"

    if ($testExit -eq 0) {
        Write-BootstrapLog 'Bootstrap completed successfully.'
    } else {
        Write-BootstrapLog 'Bootstrap completed with validation failures.' 'ERROR'
    }

    exit $testExit
}
catch {
    Write-BootstrapLog "Bootstrap failed: $($_.Exception.Message)" 'ERROR'
    exit 1
}
