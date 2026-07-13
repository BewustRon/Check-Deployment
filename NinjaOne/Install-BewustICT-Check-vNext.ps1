<#
.SYNOPSIS
    Installs and configures Bewust ICT Security Check for Microsoft Edge and Google Chrome.
#>

[CmdletBinding()]
param(
    [switch]$ConfigureChrome,
    [switch]$EnableCippReporting,
    [switch]$AutoDiscoverTenant = $true,
    [string]$CippServerUrl = 'https://cipp.bewustcloud.nl',
    [string]$CippTenantId = '',
    [string]$ProductName = 'Bewust ICT Security Check'
)