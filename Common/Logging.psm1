function Initialize-BICTLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogDirectory,

        [Parameter(Mandatory = $true)]
        [string]$LogName
    )

    if (-not (Test-Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }

    $script:BICTLogFile = Join-Path $LogDirectory $LogName
    return $script:BICTLogFile
}

function Write-BICTLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )

    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"

    if ($script:BICTLogFile) {
        Add-Content -Path $script:BICTLogFile -Value $line
    }

    Write-Output $line
}

Export-ModuleMember -Function Initialize-BICTLog, Write-BICTLog
