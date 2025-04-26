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


###================== System Paths ======================###
function get-path { ($Env:Path).Split(";") }
function cd...  { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }
function cdhome { Set-Location $HOME }

function CDRepos { Set-Location $Repos }
Set-Alias repos CDRepos

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
    $profileFolder = Split-Path -Parent $PROFILE
    $ps1Files = Get-ChildItem -Path $profileFolder -Filter '*.ps1' -File

    $results = @()

    foreach ($file in $ps1Files) {
        $content = Get-Content $file.FullName

        $functions = $content | Select-String -Pattern '^\s*function\s+([a-zA-Z0-9_]+)' | ForEach-Object {
            ($_ -match 'function\s+([a-zA-Z0-9_]+)') | Out-Null
            $matches[1]
        }

        $aliases = $content | Select-String -Pattern '^\s*(Set-Alias|New-Alias)\s+([a-zA-Z0-9_]+)\s+([^\s]+)' | ForEach-Object {
            ($_ -match '(Set-Alias|New-Alias)\s+([a-zA-Z0-9_]+)\s+([^\s]+)') | Out-Null
            [PSCustomObject]@{
                Alias   = $matches[2]
                Command = $matches[3]
            }
        }

        $results += [PSCustomObject]@{
            File      = $file.Name
            Functions = $functions
            Aliases   = $aliases
        }
    }

    foreach ($item in $results) {
        Write-Host "`n=== $($item.File) ===" -ForegroundColor Cyan

        if ($item.Functions.Count -gt 0) {
            Write-Host "-- Functions --" -ForegroundColor Green
            $item.Functions | ForEach-Object { Write-Host $_ }
        }

        if ($item.Aliases.Count -gt 0) {
            Write-Host "-- Aliases --" -ForegroundColor Yellow
            foreach ($alias in $item.Aliases) {
                Write-Host ("{0} -> {1}" -f $alias.Alias, $alias.Command)
            }
        }
    }
}

Set-Alias spfa Show-ProfileFunctionsAndAliases
