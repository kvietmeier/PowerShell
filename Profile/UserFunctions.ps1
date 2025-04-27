###====================================================================================================###
<#   
  FileName: UserFunctions.ps1
  Created By: Karl Vietmeier
    
  Description:
    Stripped down to basic functions like setting paths and cd etc.

#>
###====================================================================================================###



###====================================================================================================###
#--        Paths, shortcuts, aliases, and system info
###====================================================================================================###
# Create path variables
#"C:\Users\" + $env:UserName + '\bin'
$Repos       = "C:\Users\" + $env:UserName + "\repos"
$VastRepo    = "C:\Users\" + $env:UserName + "\repos\Vast"
$VocRepo     = "C:\Users\" + $env:UserName + "\repos\Vast\karlv-vastoncloud\5_3\"
$TFRepo      = "C:\Users\" + $env:UserName + "\repos\Terraform\"
$TFGCPRepo   = "C:\Users\" + $env:UserName + "\repos\Terraform\gcp"
$TFAzureRepo = "C:\Users\" + $env:UserName + "\repos\Terraform\azure"
$OneDriveDocsPath = "C:\Users\karl.vietmeier\OneDrive - Vast Data\Documents\"

###================== System Paths ======================###
function get-path { ($Env:Path).Split(";") }
function cdup1  { Set-Location ..\.. }
function cdup2 { Set-Location ..\..\.. }
function cdup3 { Set-Location ..\..\..\.. }
function cdhome { Set-Location $HOME }
function cdrepos { Set-Location $Repos }
function cddocs { Set-Location $OneDriveDocsPath }

###================= Terraform Paths ====================###
function TerraformDir { Set-Location $TFRepo }
Set-Alias tfrepo TerraformDir

function TerraformGCPDir { Set-Location $TFGCPRepo}
Set-Alias tfgcp TerraformGCPDir

function VastRepoDir { Set-Location $VastRepo }
Set-Alias vastrepo VastRepoDir

function VoCRepoDir { Set-Location $VoCRepo }
Set-Alias vocrepo VoCRepoDir

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
