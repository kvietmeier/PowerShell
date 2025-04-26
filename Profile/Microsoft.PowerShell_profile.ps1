###====================================================================================###
<#   
  FileName: Microsoft.PowerShell_profile.ps1
  Created By: Karl Vietmeier
    
  Description:
    My customized PowerShell Profile
     * Detect VPN status and set proxies if required
     * Create a bunch of useful "Linux like" aliases.
     * Functions, aliases, and confidential variables are sourced from external files
     * Set the proxy in .gitconfig
     * Set Terraform env: variables

    To Do:

#>
###====================================================================================###

# Import some Modules
Import-Module Get-ChildItemColor
Import-Module PSColor
#Import-Module posh-git

# Run from the location of the script so I don't need full path
Set-Location $PSscriptroot

### Source files with functions and aliases
# Confidential variables
. 'C:\.info\miscinfo.ps1'


###--- Functions and Aliases
# Base folder path
$OneDriveVastPath = "C:\Users\karl.vietmeier\OneDrive - Vast Data\Documents\WindowsPowerShell"

# Individual Function Definition Files
$UserFunctionsPath         = Join-Path $OneDriveVastPath "UserFunctions.ps1"
$LinuxFunctionsPath        = Join-Path $OneDriveVastPath "LinuxFunctions.ps1"
$KubeCompletionPath        = Join-Path $OneDriveVastPath "kubecompletion.ps1"
$GCPFunctionPath           = Join-Path $OneDriveVastPath "GCPFunctions.ps1"
$AzureFunctionPath         = Join-Path $OneDriveVastPath "AzureFunctions.ps1"
$TerminAndPromptsPath      = Join-Path $OneDriveVastPath "TerminalAndPrompts.ps1"
$ProcessFunctionsPath      = Join-Path $OneDriveVastPath "ProcessFunctions.ps1"
$K8SAndGitPath             = Join-Path $OneDriveVastPath "K8SAndGit.ps1"
$TerrafromFunctionsPath    = Join-Path $OneDriveVastPath "TerraformFunctions.ps1"

# Load each script if it exists
foreach ($script in @(
    $UserFunctionsPath,
    $LinuxFunctionsPath,
    $KubeCompletionPath,
    $GCPFunctionPath,
    $TerminAndPromptsPath,
    $K8SAndGitPath,
    $ProcessFunctionsPath,
    $TerrafromFunctionsPath,
    $AzureFunctionPath
)) {
    if (Test-Path $script) {
        . $script
    } else {
        Write-Warning "Script not found: $script"
    }
}


# Git info
$GitConfig = "$env:USERPROFILE\.gitconfig"
$GitCreds  = "$env:USERPROFILE\.git-credentials"


# Safe way to load variables from another file.
# Never quite got this working
#$CompanyData = Join-Path -Path $PSscriptroot -ChildPath CompanyData.psd1
#if ( Test-Path -Path $CompanyData ) { Import-PowerShellDataFile -Path $CompanyData }


### Set some Variables (test)
# Find out if the current user identity is elevated (has admin rights)
# Find a way to use this :)
$Identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal $identity
$IsAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)


# We don't need these any more; they were just temporary variables to get to $isAdmin. 
# Delete them to prevent cluttering up the user profile. 
Remove-Variable Identity
Remove-Variable Principal

# Increase history
$MaximumHistoryCount = 10000

# Produce UTF-8 by default
$PSDefaultParameterValues["Out-File:Encoding"]="utf8"

# Show selection menu for tab - handy - might get irritating
Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

# Windows PoshGit w/PowerShell
#. (Resolve-Path "$env:LOCALAPPDATA\GitHub\shell.ps1")
#. $env:github_posh_git\profile.example.ps1

# Force a starting directory - overrides the Windows Terminal setting
$StartDir = join-path -path $env:HOMEPATH -childpath "repos"
Set-Location $StartDir

###=============================================================================###
###       Set some global environment variables
###=============================================================================###

### Terraform wants unique ENV variables (get info from other file)
# Azure:
$env:ARM_TENANT_ID       ="$TFM_TenantID"
$env:ARM_SUBSCRIPTION_ID ="$TFM_SubID"
$env:ARM_CLIENT_ID       ="$TFM_AppID"
$env:ARM_CLIENT_SECRET   ="$TFM_AppSecret"

# AWS
# TBD

# GCP


###---- GCP Service Accounts
#$env:GOOGLE_APPLICATION_CREDENTIALS     = "C:\Users\karl.vietmeier\AppData\Roaming\gcloud\application_default_credentials.json"
#$env:GOOGLE_IMPERSONATE_SERVICE_ACCOUNT = "karlv-servacct-tf@karlv-landingzone.iam.gserviceaccount.com"
#gcloud auth activate-service-account karlv-servacct-tf@karlv-landingzone.iam.gserviceaccount.com --key-file=karlv-landingzone-7fe3d1faded4.json


###---- Vast Labs
# Location of simulator pem file
$DRunPEM="C:\Users\karl.vietmeier\Documents\Projects\keys\vastdatarunners.pem"


# Connect to Azure Tenant
#azconn

#Write-Host "=== PowerShell profile loaded for $env:USERNAME ===" -ForegroundColor Cyan
#Write-Host "Starting in: $StartDir" -ForegroundColor Green
