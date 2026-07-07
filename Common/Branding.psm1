function Get-BICTCheckBranding {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        CompanyName      = 'Bewust ICT'
        ProductName      = 'Bewust ICT Security Check'
        CompanyUrl       = 'https://www.bewustict.nl'
        SupportEmail     = 'noc@bewustict.nl'
        SupportUrl       = 'https://bewustict.nl/support/'
        PrivacyPolicyUrl = 'https://bewustict.nl/privacy_verklaring/'
        AboutUrl         = 'https://www.bewustict.nl'
        PrimaryColor     = '#63B1BC'
        LogoUrl          = 'https://raw.githubusercontent.com/BewustRon/Check-Deployment/main/Assets/Bewust-ICT-beeldmerk-wit.svg'
    }
}

Export-ModuleMember -Function Get-BICTCheckBranding
