###====================================================================================###
<#   
  FileName: UserFunctions.ps1
  Created By: Karl Vietmeier
    
  Description:
   * Functions and aliases for my PowerShell profile.
   * Most of these were grabbed off of various websites and git
     repos but some are mine


#>
###====================================================================================###


###====================================================================================###
#      Basic functions to create aliased commands
###====================================================================================###

function uptime {
	Get-WmiObject win32_operatingsystem | Select-Object csname, @{LABEL='LastBootUpTime';
	EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}

function find-file($name) {
	Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
		$place_path = $_.directory
		Write-Output "${place_path}\${_}"
	}
}

#-- Path and cd related stuff
function get-path { ($Env:Path).Split(";") }
function cd...  { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }
function cdhome { Set-Location $HOME }

function TerraformDir { Set-Location C:\Users\ksvietme\Docs\Projects\GitHub\Terraform\azure}
Set-Alias tform TerraformDir

function DirTerraform { Set-Location C:\Users\ksvietme\repos\Terraform }
Set-Alias terradir DirTerraform

###--- Terminal related
# Open a Windows Terminal as Admin
function AdminTerminal { powershell "Start-Process -Verb RunAs cmd.exe '/c start wt.exe  -p ""Windows PowerShell""'" }
Set-Alias tadmin AdminTerminal

###==== Set colors for dir listings ====#
# Configuration for PSColor
# https://github.com/Davlind/PSColor
$global:PSColor = @{
  File = @{
      Default    = @{ Color = 'White' }
      Directory  = @{ Color = 'blue'}
      Hidden     = @{ Color = 'DarkGray'; Pattern = '^\.' } 
      Code       = @{ Color = 'Magenta'; Pattern = '\.(java|c|cpp|cs|js|css|html|xml|yml|yaml|md|markdown|json)$' }
      Executable = @{ Color = 'Green'; Pattern = '\.(exe|bat|cmd|sh|py|pl|ps1|psm1|vbs|rb|reg)$' }
      Text       = @{ Color = 'Yellow'; Pattern = '\.(docx|doc|ppt|pptx|xls|xlsx|vsdx|vsd|pdf|txt|cfg|conf|ini|csv|log|config)$' }
      Compressed = @{ Color = 'Green'; Pattern = '\.(zip|tar|gz|rar|jar|war|gzip)$' }
  }
  Service = @{
      Default = @{ Color = 'White' }
      Running = @{ Color = 'DarkGreen' }
      Stopped = @{ Color = 'DarkRed' }     
  }
  Match = @{
      Default    = @{ Color = 'White' }
      Path       = @{ Color = 'Cyan'}
      LineNumber = @{ Color = 'Yellow' }
      Line       = @{ Color = 'White' }
  }
NoMatch = @{
      Default    = @{ Color = 'White' }
      Path       = @{ Color = 'Cyan'}
      LineNumber = @{ Color = 'Yellow' }
      Line       = @{ Color = 'White' }
  }
}
###==== End Set colors for dir listings ====#


Function lock
{
 # Lock Screen
 $signature = @"
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool LockWorkStation();
"@
    $LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru

    $LockWorkStation::LockWorkStation()|Out-Null
}

###--- Apps
function explore {
    explorer .
}

function VSCodeInsiders {
    Param($file)
    & 'C:\Users\ksvietme\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe' $file
}
Set-Alias code VSCodeInsiders

# Laptop/system model and serial number.
Function Get-Model {(Get-WmiObject -Class:Win32_ComputerSystem).Model}
Set-Alias GModel Get-Model

Function Get-SerialNumber {(Get-WmiObject -Class:Win32_BIOS).SerialNumber}
Set-Alias GSer Get-SerialNumber 

function alias {Get-Alias | Format-Table -Property Name, Options -Autosize}


###====================================================================================###
#      Prompt mods
###====================================================================================###
function prompt
{
  $color = "Cyan"
  
  # Emulate standard PS prompt with location followed by ">"
  Write-Host ("KV " + $(Get-Location) +">") -NoNewLine -ForegroundColor $Color
  
  return " "

  # Don't know what this does - 
  #$out = "PS $loc> "
  #$loc   = Get-Location
  #$out += "$([char]27)]9;12$([char]7)"
  #
  #if ($loc.Provider.Name -eq "FileSystem") {
  #  $out += "$([char]27)]9;9;`"$($loc.Path)`"$([char]7)"
  #}
  #
  #return $out

}


###====================================================================================###
#     https://gist.github.com/aroben/5542538
#     Process management
###====================================================================================###
function pstree {
  # Works like "ps -aux"
	$ProcessesById = @{}
	foreach ($Process in (Get-WMIObject -Class Win32_Process)) {
		$ProcessesById[$Process.ProcessId] = $Process
	}

	$ProcessesWithoutParents = @()
	$ProcessesByParent = @{}
	foreach ($Pair in $ProcessesById.GetEnumerator()) {
		$Process = $Pair.Value

		if (($Process.ParentProcessId -eq 0) -or !$ProcessesById.ContainsKey($Process.ParentProcessId)) {
			$ProcessesWithoutParents += $Process
			continue
		}

		if (!$ProcessesByParent.ContainsKey($Process.ParentProcessId)) {
			$ProcessesByParent[$Process.ParentProcessId] = @()
		}
		$Siblings = $ProcessesByParent[$Process.ParentProcessId]
		$Siblings += $Process
		$ProcessesByParent[$Process.ParentProcessId] = $Siblings
	}

	function Show-ProcessTree ([UInt32]$ProcessId, $IndentLevel) {
		$Process = $ProcessesById[$ProcessId]
		$Indent = " " * $IndentLevel
		if ($Process.CommandLine) {
			$Description = $Process.CommandLine
		} else {
			$Description = $Process.Caption
		}

		Write-Output ("{0,6}{1} {2}" -f $Process.ProcessId, $Indent, $Description)
		foreach ($Child in ($ProcessesByParent[$ProcessId] | Sort-Object CreationDate)) {
			Show-ProcessTree $Child.ProcessId ($IndentLevel + 4)
		}
  }

	Write-Output ("{0,6} {1}" -f "PID", "Command Line")
	Write-Output ("{0,6} {1}" -f "---", "------------")

	foreach ($Process in ($ProcessesWithoutParents | Sort-Object CreationDate)) {
		Show-ProcessTree $Process.ProcessId 0
	}
}


function ListGUIApps {
  Get-Process | Where-Object {$_.mainWindowTitle} | Format-Table Id, Name, mainWindowtitle -AutoSize
}
Set-Alias -Name listapps -Value ListGUIApps



###====================================================================================###
#      Misc Utilities
###====================================================================================###

function unzip ($file) {
    $dirname = (Get-Item $file).Basename
    Write-Output("Extracting", $file, "to", $dirname)
    New-Item -Force -ItemType directory -Path $dirname
    expand-archive $file -OutputPath $dirname -ShowProgress
}


###====================================================================================###
#      Git related
###====================================================================================###
# For git commits
function gpush {
  # Onle liner git commit with commit message  
  Param($message)
  git add -A; git commit -m $message; git push origin master
}

function Get-GitTree { & git log --graph --oneline --decorate $args }
Set-Alias -Name glog -Value Get-GitTree -Force -Option AllScope

<###  More GitHub aliases - uncomment to use. 
function Get-GitStatus { 
  & git status -sb $args
}
Set-Alias -Name s -Value Get-GitStatus -Force -Option AllScope

function Get-GitCommit { & git commit -ev $args }
Set-Alias -Name c -Value Get-GitCommit -Force -Option AllScope

function Get-GitAdd { & git add --all $args }
Set-Alias -Name ga -Value Get-GitAdd -Force -Option AllScope

function Get-GitPush { & git push $args }
Set-Alias -Name gps -Value Get-GitPush -Force -Option AllScope

function Get-GitPull { & git pull $args }
Set-Alias -Name gpl -Value Get-GitPull -Force -Option AllScope

function Get-GitFetch { & git fetch $args }
Set-Alias -Name f -Value Get-GitFetch -Force -Option AllScope

function Get-GitCheckout { & git checkout $args }
Set-Alias -Name co -Value Get-GitCheckout -Force -Option AllScope

function Get-GitBranch { & git branch $args }
Set-Alias -Name b -Value Get-GitBranch -Force -Option AllScope

function Get-GitRemote { & git remote -v $args }
Set-Alias -Name r -Value Get-GitRemote -Force -Option AllScope

#>


###====================================================================================###
#      Azure related
###====================================================================================###

function MyAZContext ()
{
    $context = Get-AzContext

    if (!$context -or ($context.Subscription.Id -ne $SubID)) 
    {
        #Write-Host "SubscriptionId '$SubID' already connected"
        Write-Host ""
        Write-Host "======================================================="
        Write-Host "  No Azure Connection use Alias - azconn - to connect "
        Write-Host "======================================================="
        Write-Host ""
        
        # Exit script
        exit
    } 
    else 
    {
      #$SubID = $context.Subscription.Id
      Write-Host ""
      Write-Host "======================================================================="
      Write-Host "  $SubName in $AADDomain is logged in"
      Write-Host "======================================================================="
    }
}
Set-Alias chkcontext MyAZContext

function AZConnectSP ()
{
    <# This function requires the following variables to be defined 
      $SPAppID
      $SPSecret
      $SubID
      $TenantID 
    #>

    $context = Get-AzContext

    # If I'm not connected/authorized, connect with Service Principle
    if (!$context -or ($context.Subscription.Id -ne $SubID)) 
    {
        Write-Host "" 
        Write-Host "Authenticating to Subscription: $SubID with Service Principle" 
        Write-Host "" 
        
        # Script Automation w/Service Principle - no prompts
        $SPPassWd = $SPSecret | ConvertTo-SecureString -AsPlainText -Force 
        $SPCred   = New-Object -TypeName System.Management.Automation.PSCredential($SPAppID, $SPPassWd)
        Connect-AzAccount -ServicePrincipal -Credential $SPCred -Tenant $TenantID
    } 
    else 
    {
        Write-Host ""
        Write-Host "SubscriptionId $SubID is connected - no action required"
        Write-Host ""
    }
}

Set-Alias azconn AZConnectSP
Set-Alias azdconn Disconnect-AzAccount

# Do this with the Azure CLI
function AZCommConnectSP () {
  az login --service-principal `
   --username $SPAppID `
   --password $SPSecret `
   --tenant $TenantID
}
Set-Alias azauth AZCommConnectSP

function AZcommLogout () { azlogout "az logout --username $SPAppID" }
Set-Alias azlogout AZcommLogout


#-- Start and stop some VMs I use
function StartTools {
  Start-AzVM -ResourceGroupName "HubInfrastructure-WestUS2" -Name "linuxtools" -NoWait
}
Set-Alias stools StartTools

function StopTools {
  Stop-AzVM -ResourceGroupName "HubInfrastructure-WestUS2" -Name "linuxtools" -NoWait
}
Set-Alias stptools StopTools

function StopDPDK {
  Stop-AzVM -ResourceGroupName "rg-networktesting" -Name "dpdk01" -NoWait -Force
  Stop-AzVM -ResourceGroupName "rg-networktesting" -Name "dpdk02" -NoWait -Force
}
Set-Alias dpdkstop StopDPDK

function ReStartDPDK {
  Restart-AzVM -ResourceGroupName "rg-networktesting" -Name "dpdk01" -NoWait
  Restart-AzVM -ResourceGroupName "rg-networktesting" -Name "dpdk02" -NoWait
}
Set-Alias dpdkreset ReStartDPDK

function StartK8S {
  Start-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8smaster-1793" -NoWait
  Start-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8sworker-1747" -NoWait
  Start-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8sworker-1776" -NoWait
}
Set-Alias k8start StartK8S

function StopK8S {
  Stop-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8smaster-1793" -NoWait
  Stop-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8sworker-1747" -NoWait
  Stop-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8sworker-1776" -NoWait
}
Set-Alias k8stop StopK8S

function RestartK8S {
  Restart-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8smaster-1793" -NoWait
  Restart-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8sworker-1747" -NoWait
  Restart-AzVM -ResourceGroupName "rg-k8scluster01" -Name "k8sworker-1776" -NoWait
}
Set-Alias k8restart RestartK8S


### Misc utilities
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