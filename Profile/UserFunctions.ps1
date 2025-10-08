###====================================================================================================###
<#   
  FileName: UserFunctions.ps1
  Created By: Karl Vietmeier
  
   PowerShell Profile Configuration:
       Custom Environment Variables, Fast Directory Aliases, and 
       System Utility Functions (IP/Unzip/Profile-Explorer)
#>
###====================================================================================================###



###====================================================================================================###
#--        Paths, shortcuts, aliases, and system info
###====================================================================================================###

###-- Create path variables

# Make this portable - use OneDrive Documents path $env:OneDrive
$OneDriveDocsPath = Join-Path $env:OneDrive 'Documents'

# Base Repos Folder
$BaseRepos = Join-Path $env:USERPROFILE 'repos'

# Repos
$Repos       = $BaseRepos
$VastRepo    = Join-Path $BaseRepos 'Vast'
$VocRepo     = Join-Path $VastRepo 'karlv-vastoncloud'
$TFRepo      = Join-Path $BaseRepos 'Terraform'
$TFGCPRepo   = Join-Path $TFRepo 'gcp'
$TFAzureRepo = Join-Path $TFRepo 'azure'

###================== Moving Around ======================###

# Show each PATH entry on its own line
function Get-Path { ($Env:Path).Split(';') }

# Go up N directories
function up  { Set-Location .. }
function up2 { Set-Location ..\.. }
function up3 { Set-Location ..\..\.. }
function up4 { Set-Location ..\..\..\.. }

# Common folder shortcuts
function home   { Set-Location $HOME }
function repos  { Set-Location $Repos }
function docs   { Set-Location $OneDriveDocsPath }
function vast   { Set-Location $VastRepo }
function voc    { Set-Location $VocRepo }

<# 
Example usage
cdupN         # Same as `cd ..`
cdupN 2       # Same as `cd ..\..`
cdupN 4       # Same as `cd ..\..\..\..`
#>

function cdupN {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 20)]
        [int]$Levels = 1
    )

    $upPath = ('..' + ('\..' * ($Levels - 1)))
    Set-Location $upPath
}
Set-Alias up cdup


###================= Terraform Paths ====================###
function CDTerraformDir { Set-Location $TFRepo }
Set-Alias tfrepo CDTerraformDir

function CDVastRepoDir { Set-Location $VastRepo }
Set-Alias vastrepo CDVastRepoDir

function CDVoCRepoDir { Set-Location $VoCRepo }
Set-Alias vocrepo CDVoCRepoDir


###================= GCP Paths ====================###
function TerraformGCPDir { Set-Location $TFGCPRepo}
Set-Alias tfgcp TerraformGCPDir


###================= Azure Paths ====================###
function TerraformAzureDir { Set-Location $TFAzureRepo}
Set-Alias tfaz TerraformAzureDir

function AKS2Dir { Set-Location C:\Users\ksvietme\repos\Terraform\azure\AKS\aks-2}
Set-Alias aks2 AKS2Dir

function AKS1Dir { Set-Location C:\Users\ksvietme\repos\Terraform\azure\AKS\aks-1}
Set-Alias aks1 AKSDir

function AKSDir { Set-Location C:\Users\ksvietme\repos\Terraform\azure\AKS\aks-billrun}
Set-Alias billrun AKSDir



###====================================================================================================###
###--- Misc utilities
###====================================================================================================###

function GetMyIP {
  $RouterIP = Invoke-RestMethod -uri "https://ipinfo.io"
  
  # See it on the screen
  Write-Host ""
  Write-Host "Current Router/VPN IP: $($RouterIP.ip)"
  Write-Host ""
  
  # Create/Set an Environment variable for later use
  $env:MyIP  = $($RouterIP.ip)
}
# Run function to set variable
Set-Alias myip GetMyIP

function unzip ($file) {
    $dirname = (Get-Item $file).Basename
    Write-Output("Extracting", $file, "to", $dirname)
    New-Item -Force -ItemType directory -Path $dirname
    expand-archive $file -OutputPath $dirname -ShowProgress
}


##-  List functions and aliases
function Show-ProfileFunctionsAndAliases {
    # Get the folder path where the current PowerShell profile is located
    $profileFolder = Split-Path -Parent $PROFILE

    # Retrieve all .ps1 files in the profile folder (scripts with functions/aliases)
    $ps1Files = Get-ChildItem -Path $profileFolder -Filter '*.ps1' -File

    # Initialize an empty array to store results for each file
    $results = @()

    # Loop through each .ps1 file
    foreach ($file in $ps1Files) {
        # Read the content of the file
        $content = Get-Content $file.FullName

        # Extract functions by searching for lines that define them
        $functions = $content | Select-String -Pattern '^\s*function\s+([a-zA-Z0-9_]+)' | ForEach-Object {
            # Use regex to capture the function name and add it to the list
            ($_ -match 'function\s+([a-zA-Z0-9_]+)') | Out-Null
            $matches[1]
        }

        # Extract aliases defined in the file (Set-Alias or New-Alias)
        $aliases = $content | Select-String -Pattern '^\s*(Set-Alias|New-Alias)\s+([a-zA-Z0-9_]+)\s+([^\s]+)' | ForEach-Object {
            # Use regex to capture the alias name and its associated command
            ($_ -match '(Set-Alias|New-Alias)\s+([a-zA-Z0-9_]+)\s+([^\s]+)') | Out-Null
            [PSCustomObject]@{
                Alias   = $matches[2]  # The alias name
                Command = $matches[3]  # The command it points to
            }
        }

        # Add the results for this file to the results array
        $results += [PSCustomObject]@{
            File      = $file.Name       # File name
            Functions = $functions       # List of function names
            Aliases   = $aliases         # List of aliases with commands
        }
    }

    # Loop through the results and display functions and aliases for each file
    foreach ($item in $results) {
        Write-Host "`n=== $($item.File) ===" -ForegroundColor Cyan

        # Display functions if any were found
        if ($item.Functions.Count -gt 0) {
            Write-Host "-- Functions --" -ForegroundColor Green
            $item.Functions | ForEach-Object { Write-Host $_ }
        }

        # Display aliases if any were found
        if ($item.Aliases.Count -gt 0) {
            Write-Host "-- Aliases --" -ForegroundColor Yellow
            foreach ($alias in $item.Aliases) {
                Write-Host ("{0} -> {1}" -f $alias.Alias, $alias.Command)
            }
        }
    }
}

Set-Alias spfa Show-ProfileFunctionsAndAliases
