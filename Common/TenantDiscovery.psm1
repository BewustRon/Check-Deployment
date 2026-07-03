function Get-BICTDsregStatus {
    [CmdletBinding()]
    param()

    $result = [ordered]@{
        AzureAdJoined = $null
        DomainJoined  = $null
        TenantName    = $null
        TenantId      = $null
        MdmUrl        = $null
        Raw           = $null
    }

    $dsreg = Get-Command dsregcmd.exe -ErrorAction SilentlyContinue
    if (-not $dsreg) {
        return [pscustomobject]$result
    }

    $raw = & dsregcmd.exe /status 2>$null
    $result.Raw = ($raw -join [Environment]::NewLine)

    foreach ($line in $raw) {
        if ($line -match '^\s*AzureAdJoined\s*:\s*(.+)$') { $result.AzureAdJoined = $Matches[1].Trim() }
        if ($line -match '^\s*DomainJoined\s*:\s*(.+)$') { $result.DomainJoined = $Matches[1].Trim() }
        if ($line -match '^\s*TenantName\s*:\s*(.+)$') { $result.TenantName = $Matches[1].Trim() }
        if ($line -match '^\s*TenantId\s*:\s*(.+)$') { $result.TenantId = $Matches[1].Trim() }
        if ($line -match '^\s*MdmUrl\s*:\s*(.+)$') { $result.MdmUrl = $Matches[1].Trim() }
    }

    return [pscustomobject]$result
}

function Get-BICTTenantIdentifier {
    [CmdletBinding()]
    param(
        [ValidateSet('TenantId', 'TenantName', 'Auto')]
        [string]$Preferred = 'Auto'
    )

    $dsreg = Get-BICTDsregStatus

    if ($Preferred -eq 'TenantId' -and -not [string]::IsNullOrWhiteSpace($dsreg.TenantId)) {
        return [pscustomobject]@{ Identifier = $dsreg.TenantId; Source = 'dsregcmd TenantId'; Dsreg = $dsreg }
    }

    if ($Preferred -eq 'TenantName' -and -not [string]::IsNullOrWhiteSpace($dsreg.TenantName)) {
        return [pscustomobject]@{ Identifier = $dsreg.TenantName; Source = 'dsregcmd TenantName'; Dsreg = $dsreg }
    }

    if (-not [string]::IsNullOrWhiteSpace($dsreg.TenantId)) {
        return [pscustomobject]@{ Identifier = $dsreg.TenantId; Source = 'dsregcmd TenantId'; Dsreg = $dsreg }
    }

    if (-not [string]::IsNullOrWhiteSpace($dsreg.TenantName)) {
        return [pscustomobject]@{ Identifier = $dsreg.TenantName; Source = 'dsregcmd TenantName'; Dsreg = $dsreg }
    }

    return [pscustomobject]@{ Identifier = ''; Source = 'none'; Dsreg = $dsreg }
}

Export-ModuleMember -Function Get-BICTDsregStatus, Get-BICTTenantIdentifier
