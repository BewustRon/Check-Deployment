<#
.SYNOPSIS
    Detects whether Bewust ICT Security Check policies are compliant.

.DESCRIPTION
    Returns exit code 0 when the required browser policies are compliant.
    Returns exit code 1 when remediation is required.

    Microsoft Edge is always checked. Google Chrome is checked automatically
    when Chrome is installed, or explicitly when -RequireChrome is supplied.
