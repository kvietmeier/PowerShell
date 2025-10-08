#Begin Azure PowerShell alias import
#Import-Module Az.Accounts -ErrorAction SilentlyContinue -ErrorVariable importError
#if ($importerror.Count -eq 0) { 
#    Enable-AzureRmAlias -Module Az.Accounts -ErrorAction SilentlyContinue; 
#}
##End Azure PowerShell alias import

###=====================================================================###
#
#   Just map to main profile.
#
###=====================================================================###

# Use the system profile for a common shell experience.
. $PSscriptroot\Microsoft.PowerShell_profile.ps1

# Set some vSCode specififc settings
# TBD
