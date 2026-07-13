function Get-BICTBrowserConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Edge','Chrome')]
        [string]$Browser
    )

    switch ($Browser) {
        'Edge' {
            return [pscustomobject]@{
                BrowserName = 'Microsoft Edge'
                PolicyRoot  = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
                ExtensionId = 'knepjpocdagponkonnbggpcnhnaikajg'
                UpdateUrl   = 'https://edge.microsoft.com/extensionwebstorebase/v1/crx'
            }
        }
        'Chrome' {
            return [pscustomobject]@{
                BrowserName = 'Google Chrome'
                PolicyRoot  = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
                ExtensionId = 'benimdeioplgkhanklclahllklceahbe'
                UpdateUrl   = 'https://clients2.google.com/service/update2/crx'
            }
        }
    }
}

Export-ModuleMember -Function Get-BICTBrowserConfig
