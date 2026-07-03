function Ensure-BICTRegistryKey {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-BICTStringValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowEmptyString()][Parameter(Mandatory = $true)][string]$Value
    )
    Ensure-BICTRegistryKey -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
}

function Set-BICTDwordValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$Value
    )
    Ensure-BICTRegistryKey -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

function Test-BICTRegistryKey {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Test-Path $Path)
}

function Get-BICTRegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )
    if (-not (Test-Path $Path)) { return $null }
    $item = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
    return $item.$Name
}

Export-ModuleMember -Function Ensure-BICTRegistryKey, Set-BICTStringValue, Set-BICTDwordValue, Test-BICTRegistryKey, Get-BICTRegistryValue
