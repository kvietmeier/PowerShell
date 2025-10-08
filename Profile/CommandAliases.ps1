###====================================================================================###
<#   
  Section     : Basic Utility Functions
  Author      : Karl Vietmeier
  Created On  : <Insert Date>

  Purpose:
    Provides common utility and shortcut functions for PowerShell sessions:
      * System info (uptime, model, serial)
      * File searching and history utilities
      * App launchers and quick aliases
      * Fixes for Helm, WSL clock, and VSCode Insiders
      * Workstation lock shortcut
#>
###====================================================================================###


###====================================================================================###
###--- System Information Functions
###====================================================================================###

# Retrieve and display the last boot up time of the system
function uptime {
    Get-WmiObject win32_operatingsystem | Select-Object csname, @{LABEL='LastBootUpTime';
    EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}

# Laptop/system model and serial number
function Get-Model { (Get-WmiObject -Class:Win32_ComputerSystem).Model }
Set-Alias GModel Get-Model

function Get-SerialNumber { (Get-WmiObject -Class:Win32_BIOS).SerialNumber }
Set-Alias GSer Get-SerialNumber 

function WindowsBuild { systeminfo | Select-String "^OS Name","^OS Version" }
Set-Alias winbuild WindowsBuild


###====================================================================================###
###--- File and History Utilities
###====================================================================================###

# Recursively search for files with a specified name pattern
function find-file($name) {
    Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        $place_path = $_.DirectoryName
        Write-Output "$place_path\$($_.Name)"
    }
}

# Access full history across sessions
function hist { 
    $find = $args[0] 
    Write-Host "Finding in full history using *$find*"
    
    if ($find) {
        Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object {$_ -like "*$find*"} | Get-Unique | more
    } else {
        Write-Host "No search term provided. Displaying all unique history entries."
        Get-Content (Get-PSReadlineOption).HistorySavePath | Get-Unique | more
    }
}


###====================================================================================###
###--- App Launchers and Aliases
###====================================================================================###

function explore { explorer .  }

function tf { terraform }

function VSCodeInsiders {
    Param($file)
    & 'C:\Users\karl.vietmeier\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe' $file
}
Set-Alias code VSCodeInsiders


###====================================================================================###
###--- Fixes and Workarounds
###====================================================================================###

# Fix for Helm/AKS kubeconfig path issue
function FixHelm {
  [Environment]::SetEnvironmentVariable("KUBE_CONFIG_PATH", "~/.kube/config") 
}

# WSL clock sync workaround
function FixWSLClock { wsl.exe -d Ubuntu-20.04 -u root -- ntpdate time.windows.com }
Set-Alias hwclock FixWSLClock


###====================================================================================###
###--- Security and Session Shortcuts
###====================================================================================###

# Lock the workstation
function lock {
  $signature = @"
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool LockWorkStation();
"@

  $LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru
  $LockWorkStation::LockWorkStation()|Out-Null
}
