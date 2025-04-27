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
. 'C:\.info\miscinfo.ps1'

#-------------------------------------------
# Load External Functions
#-------------------------------------------
$OneDriveVASTPath = "C:\Users\karl.vietmeier\OneDrive - Vast Data\Documents\WindowsPowerShell"

$FunctionFiles = @(
    "UserFunctions.ps1",
    "LinuxFunctions.ps1",
    "kubecompletion.ps1",
    "GCPFunctions.ps1",
    "AzureFunctions.ps1",
    "TerminalAndPrompts.ps1",
    "ProcessFunctions.ps1",
    "K8SAndGit.ps1",
    "TerraformFunctions.ps1"
)

foreach ($FunctionFile in $FunctionFiles) {
    $FullPath = Join-Path $OneDriveVASTPath $FunctionFile
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
$Identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal $Identity
$IsAdmin   = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Clean up temp variables
Remove-Variable Identity, Principal

#-------------------------------------------
# PowerShell Tuning
#-------------------------------------------
$MaximumHistoryCount = 10000
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

#-------------------------------------------
# Start Directory
#-------------------------------------------
$StartDir = Join-Path $env:HOMEPATH "repos"
Set-Location $StartDir

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
$env:DRunPEM = "C:\Users\karl.vietmeier\Documents\Projects\keys\vastdatarunners.pem"


#-------------------------------------------
# Status Messages (optional for clarity)
#-------------------------------------------
# Don't need these
#Write-Host "=== PowerShell profile loaded for $env:USERNAME ===" -ForegroundColor Cyan
#Write-Host "Starting Directory: $StartDir" -ForegroundColor Green

if ($IsAdmin) {
    Write-Host "Running as Administrator" -ForegroundColor Yellow
} else {
    Write-Host "Running as Standard User" -ForegroundColor DarkYellow
}