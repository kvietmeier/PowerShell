###====================================================================================###
<#   
  FileName: Microsoft.PowerShell_profile.ps1
  Created By: Karl Vietmeier

  Description:
    Customized PowerShell Profile:
     * Detect VPN status and set proxies if required
     * "Linux like" aliases
     * Load external functions and confidential variables
     * Set Git proxy if needed
     * Set Terraform environment variables
#>
###====================================================================================###
<# 
Use "join-path" everywhere - 
Handles Path Separators Correctly Across Platforms:
  On Windows, paths use backslashes \
  On Linux/macOS, paths use forward slashes /

Join-Path automatically uses the correct directory separator for the OS PowerShell is running on.
#>

#-------------------------------------------
# Ensure OneDrive Module Path is in PSModulePath
# Or install modules for all users
#-------------------------------------------
$OneDriveModulePath = Join-Path $env:OneDrive 'Documents\PowerShell\Modules'
if (-not ($env:PSModulePath -split ';' | Where-Object { $_ -eq $OneDriveModulePath })) {
    $env:PSModulePath += ";$OneDriveModulePath"
}

#-------------------------------------------
# Import Modules Safely
#-------------------------------------------
$ModulesToLoad = @('Get-ChildItemColor') # 'posh-git' optional

foreach ($Module in $ModulesToLoad) {
    try {
        Import-Module $Module -ErrorAction Stop
    }
    catch {
        Write-Warning "Module not found: $Module"
    }
}


<# 
#-------------------------------------------
# Import Modules Safely
#-------------------------------------------
$ModulesToLoad = @('Get-ChildItemColor', 'PSColor') # 'posh-git' optional

foreach ($Module in $ModulesToLoad) {
    Try {
        Import-Module $Module -ErrorAction Stop
    }
    Catch {
        Write-Warning "Module not found: $Module"
    }
}
#>


#-------------------------------------------
# Set Script Root if not already set
#-------------------------------------------
if (-not $PSscriptroot) {
    $PSscriptroot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
Set-Location $PSscriptroot

#-------------------------------------------
# Load Confidential Variables
#-------------------------------------------
. 'somewhere'

#-------------------------------------------
# Load External Functions
#-------------------------------------------
$UserProfile = [Environment]::GetFolderPath("UserProfile")
$OneDriveKarlPath = Join-Path $UserProfile "OneDrive - Karl\Documents\WindowsPowerShell"

#$OneDriveVASTPath = "C:\Users\karl.vietmeier\OneDrive - Vast Data\Documents\WindowsPowerShell"

$FunctionFiles = @(
    "UserFunctions.ps1",
    "LinuxFunctions.ps1",
    "GCPFunctions.ps1",
    "AWS-Functions.ps1",
    "AzureFunctions.ps1",
    "TerminalAndPrompts.ps1",
    "ProcessFunctions.ps1",
    "K8SAndGit.ps1",
    "TerraformFunctions.ps1"
)

foreach ($FunctionFile in $FunctionFiles) {
    $FullPath = Join-Path $OneDriveKarlPath $FunctionFile
    if (Test-Path $FullPath) {
        . $FullPath
    } else {
        Write-Warning "Function script not found: $FullPath"
    }
}

#-------------------------------------------
# Git Setup (optional future proxy config)
#-------------------------------------------
$GitConfigPath = "$env:USERPROFILE\.gitconfig"
$GitCredsPath  = "$env:USERPROFILE\.git-credentials"


#-------------------------------------------
# Check Admin Rights
#-------------------------------------------
# Get the current Windows user identity (the user running the script)
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

# Create a principal object representing the current user’s security context
$Principal = New-Object Security.Principal.WindowsPrincipal $Identity

# Check if the principal (current user) belongs to the Administrator role
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Make this boolean available globally, so other parts of your script can check it
$global:IsAdmin = $IsAdmin

# Clean up temp variables
Remove-Variable Identity, Principal

#-------------------------------------------
# PowerShell Tuning
#-------------------------------------------
$MaximumHistoryCount = 10000
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

#-------------------------------------------
# Start Directory - overrides Windows Terminal profiles
#-------------------------------------------
$StartDir = Join-Path $env:HOMEPATH "repos"
Set-Location $StartDir

<# 
# Check if we're in Windows Terminal (you could also check if it's PowerShell Core or others)
if ($env:WT_SESSION) {
    # Avoid overriding the starting directory in Windows Terminal
    Write-Host "Starting Directory in Windows Terminal is not being overridden" -ForegroundColor Green
} else {
    # Set the directory for non-terminal sessions
    $StartDir = Join-Path $env:HOMEPATH "repos"
    Set-Location $StartDir
}
#>

#-------------------------------------------
# Set Environment Variables
#-------------------------------------------
# Azure Terraform
$env:ARM_TENANT_ID       = "$TFM_TenantID"
$env:ARM_SUBSCRIPTION_ID = "$TFM_SubID"
$env:ARM_CLIENT_ID       = "$TFM_AppID"
$env:ARM_CLIENT_SECRET   = "$TFM_AppSecret"

# AWS (TBD)
# GCP (TBD)

# VAST Labs Keys

# Engineering Lab Key
$DRunPemPath = Join-Path $env:OneDrive "Documents/Projects/keys/vastdatarunners.pem"
if (Test-Path $DRunPemPath) {
    $env:DRunPEM = $DRunPemPath
}

# AWS Keys
$PemPath = Join-Path $HOME ".ssh\other_keys\aws.karlv-poc.pem"
if (Test-Path $PemPath) {
    $env:AWSPem = $PemPath
}


###====================================================================================###
<# 
#-------------------------------------------
# Status Messages Use for debugging
#-------------------------------------------
# Don't need these
Write-Host "=== PowerShell profile loaded for $env:USERNAME ===" -ForegroundColor Cyan
Write-Host "Starting Directory: $StartDir" -ForegroundColor Green

if ($IsAdmin) {
    Write-Host "Running as Administrator" -ForegroundColor Yellow
} else {
    Write-Host "Running as Standard User" -ForegroundColor DarkYellow
}
#>
#Write-Host "=== Core PowerShell profile sourced" 
#Write-Host "=== PowerShell profile loaded for $env:USERNAME ===" -ForegroundColor Cyan

#$PSModuleAutoLoadingPreference = 'AllModules'