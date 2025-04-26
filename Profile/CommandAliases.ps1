###====================================================================================###
#      Basic functions to create aliased commands
###====================================================================================###

# This function retrieves and displays the last boot up time of the system.
function uptime {
	Get-WmiObject win32_operatingsystem | Select-Object csname, @{LABEL='LastBootUpTime';
	EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}

# This function searches for files with a specified name pattern recursively.
function find-file($name) {
    # Recursively get all items that match the name pattern and handle errors silently
    Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        # Store the directory path of the current item
        $place_path = $_.DirectoryName
        # Output the full path of the current item
        Write-Output "$place_path\$($_.Name)"
    }
}

# Access full history across sessions - search is broken
function hist { 
    $find = $args[0] 
    Write-Host "Finding in full history using *$find*"
    
    # Check if a search term is provided
    if ($find) {
        Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object {$_ -like "*$find*"} | Get-Unique | more
    }
    else {
        Write-Host "No search term provided. Displaying all unique history entries."
        Get-Content (Get-PSReadlineOption).HistorySavePath | Get-Unique | more
    }
}

###====================================================================================================###
###--- Apps
###====================================================================================================###

function explore { explorer .  }

function tf { terraform }

function FixHelm {
  # Need this for a Helm/AKS issue
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1234
  [Environment]::SetEnvironmentVariable("KUBE_CONFIG_PATH", "~/.kube/config") 
}

# WSL still has clock issues:
function FixWSLClock { wsl.exe -d Ubuntu-20.04 -u root -- ntpdate time.windows.com }
Set-Alias hwclock FixWSLClock

function VSCodeInsiders {
    Param($file)
    & 'C:\Users\karl.vietmeier\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe' $file
}
Set-Alias code VSCodeInsiders

# This function locks the workstation.
Function lock {
  # Define a signature for the external function from the user32.dll to lock the workstation
  $signature = @"
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool LockWorkStation();
"@

  # Add the type with the defined signature to the PowerShell session and create an object to call the function
  $LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru

  # Call the LockWorkStation function to lock the workstation
  $LockWorkStation::LockWorkStation()|Out-Null
}


# Laptop/system model and serial number.
Function Get-Model {(Get-WmiObject -Class:Win32_ComputerSystem).Model}
Set-Alias GModel Get-Model

Function Get-SerialNumber {(Get-WmiObject -Class:Win32_BIOS).SerialNumber}
Set-Alias GSer Get-SerialNumber 

#function alias {Get-Alias | Format-Table -Property Name, Options -Autosize}

function WindowsBuild { systeminfo | Select-String "^OS Name","^OS Version" }
Set-Alias winbuild WindowsBuild

#function SystemInfo { 
#  $SysDetails = (Get-ComputerInfo) }
#
#Set-Alias SysDet SystemInfo
