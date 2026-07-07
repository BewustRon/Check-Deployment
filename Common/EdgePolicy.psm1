function Get-BICTEdgePolicyRoot { 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' }

function Get-BICTExtensionId { 'knepjpocdagponkonnbggpcnhnaikajg' }

function Get-BICTEdgePolicyPaths {
 $root=Get-BICTEdgePolicyRoot; $id=Get-BICTExtensionId
 [pscustomobject]@{
  ExtensionSettings=Join-Path $root "ExtensionSettings\$id"
  Policy=Join-Path $root "3rdparty\extensions\$id\policy"
  Branding=Join-Path $root "3rdparty\extensions\$id\policy\customBranding"
 }
}
Export-ModuleMember -Function Get-BICTEdgePolicyRoot,Get-BICTExtensionId,Get-BICTEdgePolicyPaths