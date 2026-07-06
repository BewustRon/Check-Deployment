function Get-BICTCheckBranding {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        CompanyName      = 'Bewust ICT'
        ProductName      = 'Bewust ICT Security Check'
        CompanyUrl       = 'https://www.bewustict.nl'
        SupportEmail     = 'noc@bewustict.nl'
        SupportUrl       = 'https://www.bewustict.nl'
        PrivacyPolicyUrl = 'https://bewustict.nl/privacy_verklaring/'
        AboutUrl         = 'https://www.bewustict.nl'
        PrimaryColor     = '#63B1BC'
        LogoUrl          = 'https://bewustict.nl/wp-content/uploads/2025/10/Logo-zonder-beeldberk.svg'
    }
}

Export-ModuleMember -Function Get-BICTCheckBranding
