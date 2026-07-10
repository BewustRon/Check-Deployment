[CmdletBinding()]
param(
    [switch]$EnableCippReporting,
    [string]$CippTenantId = '',
    [switch]$ConfigureChrome,
    [switch]$ForceUpdate
)

$ErrorActionPreference = 'Stop'
$BootstrapVersion = [version]'0.2.0'
$Root = 'C:\ProgramData\BewustICT\Check'
$Work = Join-Path $Root 'Current'
$Backup = Join-Path $Root 'Previous'
$LogDir = Join-Path $Root 'Logs'
$Zip = Join-Path $env:TEMP 'Check-Deployment-main.zip'
$RepoZip = 'https://github.com/BewustRon/Check-Deployment/archive/refs/heads/main.zip'
$OnlineVersionUrl = 'https://raw.githubusercontent.com/BewustRon/Check-Deployment/main/version.json'
$LocalVersionFile = Join-Path $Root 'version.json'
$Log = Join-Path $LogDir 'Bootstrap.log'

function Write-BootstrapLog {
    param([string]$Message,[string]$Level='INFO')
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $Log -Value $line
    Write-Output $line
}

function Get-VersionMetadata {
    param([string]$Uri)
    return Invoke-RestMethod -Uri $Uri -UseBasicParsing
}

try {
    Write-BootstrapLog "Starting Bewust ICT Check bootstrap v$BootstrapVersion."

    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

    $onlineMetadata = Get-VersionMetadata -Uri $OnlineVersionUrl
    $onlineVersion = [version]$onlineMetadata.version
    $localVersion = [version]'0.0.0'

    if (Test-Path $LocalVersionFile) {
        try {
            $localMetadata = Get-Content -Path $LocalVersionFile -Raw | ConvertFrom-Json
            $localVersion = [version]$localMetadata.version
        }
        catch {
            Write-BootstrapLog 'Local version metadata is invalid; forcing refresh.' 'WARN'
        }
    }

    Write-BootstrapLog "Local version: $localVersion; online version: $onlineVersion."

    $needsDownload = $ForceUpdate -or -not (Test-Path $Work) -or ($onlineVersion -gt $localVersion)

    if ($needsDownload) {
        Write-BootstrapLog "Downloading repository from $RepoZip"
        Invoke-WebRequest -Uri $RepoZip -OutFile $Zip -UseBasicParsing

        if (Test-Path $Backup) { Remove-Item -Path $Backup -Recurse -Force }
        if (Test-Path $Work) { Rename-Item -Path $Work -NewName 'Previous' -Force }

        New-Item -ItemType Directory -Force -Path $Work | Out-Null
        Expand-Archive -Path $Zip -DestinationPath $Work -Force

        $downloadedVersion = Join-Path $Work 'Check-Deployment-main\version.json'
        if (Test-Path $downloadedVersion) {
            Copy-Item -Path $downloadedVersion -Destination $LocalVersionFile -Force
        }

        Write-BootstrapLog "Repository updated to version $onlineVersion."
    }
    else {
        Write-BootstrapLog 'Local repository is current; skipping download.'
    }

    $RepoRoot = Get-ChildItem -Path $Work -Directory | Where-Object { $_.Name -like 'Check-Deployment-*' } | Select-Object -First 1
    if (-not $RepoRoot) { throw 'Repository root not found.' }

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
    }
    else {
        Write-BootstrapLog 'Bootstrap completed with validation failures.' 'ERROR'
    }

    exit $testExit
}
catch {
    Write-BootstrapLog "Bootstrap failed: $($_.Exception.Message)" 'ERROR'
    exit 1
}
