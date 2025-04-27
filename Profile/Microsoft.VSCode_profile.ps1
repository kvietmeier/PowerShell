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

# Set vSCode specififc settings
if ($env:TERM_PROGRAM -eq "vscode") {
    Write-Host "Running in VSCode - apply editor-specific settings..." -ForegroundColor Yellow
    # Add your VSCode-specific config here
}
