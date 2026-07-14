<#
.SYNOPSIS
    Detects and remediates Bewust ICT Security Check in one NinjaOne automation.

.DESCRIPTION
    Runs local compliance detection when the current repository is present.
    When the device is missing, outdated, or non-compliant, the script downloads
    Bootstrap.ps1, performs remediation, and validates the device again.

    Exit code 0 means the device is compliant.
    Exit code 1 means detection or remediation failed.

.NOTES
    Designed for NinjaOne SYSTEM context.
#>

[CmdletBinding()]
param(
    [switch]$Enable