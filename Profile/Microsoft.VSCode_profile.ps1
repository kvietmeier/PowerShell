###=====================================================================###
#   Visual Studio Code uses a seperate profile for the integrated 
#   PS terminal
#
#   Not always a good thing to do - 
#
###=====================================================================###

# Use the system profile for a common shell experience.
#. $PSscriptroot\Microsoft.PowerShell_profile.ps1
$OneDriveVastPath = "C:\Users\karl.vietmeier\OneDrive - Vast Data\Documents\WindowsPowerShell"
$ProfilePath      = Join-Path $OneDriveVastPath "Microsoft.PowerShell_profile.ps1"

. $ProfilePath



# Set some vSCode specififc settings
# TBD
