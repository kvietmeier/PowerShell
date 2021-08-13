###====================================================================================###
<#   
  FileName: UserFunctions.ps1
  Created By: Karl Vietmeier
    
  Description:
   Functions and aliases for my PowerShell profile.
   Uses values imported from a "secrets" file.

   I can't take credit for all of these - some are sourced from various searches
   through Github etc. I've tried to document this.

#>
###====================================================================================###

# Color ls output and other aliases
Set-Alias l Get-ChildItemColor -option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -option AllScope
Set-Alias dir Get-ChildItemColor -option AllScope
Set-Alias -Name cd -value cddash -Option AllScope


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

function get-path { ($Env:Path).Split(";") }
function cd...  { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }
function cd~ { Set-Location C:\Users\ksvietme }

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

function exp_here {
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


###====================================================================================###
#      Prompt mods for ConEmu
###====================================================================================###
function prompt
{
  $loc = Get-Location

  # Emulate standard PS prompt with location followed by ">"
  $out = "PS $loc> "

  # Simple check for ConEmu existance and ANSI emulation enabled
  if ($env:ConEmuANSI -eq "ON") {
    # Let ConEmu know when the prompt ends, to select typed
    # command properly with "Shift+Home", to change cursor
    # position in the prompt by simple mouse click, etc.
    $out += "$([char]27)]9;12$([char]7)"

    # And current working directory (FileSystem)
    # ConEmu may show full path or just current folder name
    # in the Tab label (check Tab templates)
    # Also this knowledge is crucial to process hyperlinks clicks
    # on files in the output from compilers and source control
    # systems (git, hg, ...)
    if ($loc.Provider.Name -eq "FileSystem") {
      $out += "$([char]27)]9;9;`"$($loc.Path)`"$([char]7)"
    }
  }

  return $out
}


###====================================================================================###
#     https://gist.github.com/aroben/5542538
#     Process management
###====================================================================================###
function pstree {
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

	function Show-ProcessTree([UInt32]$ProcessId, $IndentLevel) {
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
    Param($message)
    git add -A; git commit -m $message; git push origin master
}

<###  More GitHub aliases - uncomment to use. 
function Get-GitStatus { & git status -sb $args }
Set-Alias -Name s -Value Get-GitStatus -Force -Option AllScope
function Get-GitCommit { & git commit -ev $args }
Set-Alias -Name c -Value Get-GitCommit -Force -Option AllScope
function Get-GitAdd { & git add --all $args }
Set-Alias -Name ga -Value Get-GitAdd -Force -Option AllScope
function Get-GitTree { & git log --graph --oneline --decorate $args }
Set-Alias -Name t -Value Get-GitTree -Force -Option AllScope
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
function StartDPDK {
  Start-AzVM -ResourceGroupName "rg-networktesting" -Name "dpdk01" -NoWait
  Start-AzVM -ResourceGroupName "rg-networktesting" -Name "dpdk02" -NoWait
}
Set-Alias dpdkstart StartDPDK

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