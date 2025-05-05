###=====================================================================###
#
#   Just map to main profile.
#   
#   No need to manually source the main profile; PowerShell does it automatically.
#
###=====================================================================###
<# 
Write-Host "=== PowerShell profile loaded for $env:USERNAME ===" -ForegroundColor Cyan

# Use the system profile for a common shell experience.
#. $PSscriptroot\Microsoft.PowerShell_profile.ps1
$OneDriveVastPath = "C:\Users\karl.vietmeier\OneDrive - Vast Data\Documents\WindowsPowerShell"
$ProfilePath      = Join-Path $OneDriveVastPath "Microsoft.PowerShell_profile.ps1"
#. $ProfilePath

#>

#Write-Host "=== PowerShell $profile sourced" 