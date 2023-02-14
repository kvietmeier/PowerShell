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

function TerraformDir { Set-Location C:\Users\ksvietme\repos\Terraform\Azure}
Set-Alias tform TerraformDir

function AKS2Dir { Set-Location C:\Users\ksvietme\repos\Terraform\azure\AKS\aks-2}
Set-Alias aks2 AKS2Dir

function AKSDir { Set-Location C:\Users\ksvietme\repos\Terraform\azure\AKS\aks-1}
Set-Alias aks1 AKSDir

function AKSDir { Set-Location C:\Users\ksvietme\repos\Terraform\azure\AKS\aks-billrun}
Set-Alias billrun AKSDir

function AzureDir { Set-Location C:\Users\ksvietme\repos\Terraform\azure}
Set-Alias azuretf AzureDir

function CDRepos { Set-Location C:\Users\ksvietme\repos\ }
Set-Alias repos CDRepos

###--- Apps
function explore { explorer .  }

function tf { terraform }

function tfaks2([string]$action='apply', [string]$approve='-auto-approve', [string]$var_file='.\aks2-terraform.tfvars') {
  terraform $action $approve -var-file=$var_file
}

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
    & 'C:\Users\ksvietme\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe' $file
}
Set-Alias code VSCodeInsiders

# Lock Screen
Function lock
{
 $signature = @"
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool LockWorkStation();
"@
    $LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru

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


###====================================================================================###
###--- Terminal related
###====================================================================================###

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

###==== Make history act like bash history - sort of ====#
<# 
  https://github.com/PowerShell/PowerShell/issues/12061
  This will format (Get-PSReadLineOption).HistorySavePath so that the multiline commands
  (like when you paste in a function) appear as a single function. It will then allow you 
  to search across your history. 
  You can do something like Select -Expand Command once
  you find what you are looking for and itll display the whole command.
#>
function Format-PSReadLineHistory {
  $historyList = [System.Collections.ArrayList]::new()
  $history = $(Get-Content (Get-PSReadLineOption).HistorySavePath)
  $i = 0
  while( $i -lt $($history.Length - 1) ){
      # If it ends in a backtic then the command continues onto the next line
      if( $history[$i] -match "``$" ){
          $commands = [System.Collections.ArrayList]::new()
          $commands.Add($history[$i].Replace('`','')) | Out-Null
          $i++
          while($history[$i] -match "``$"){
              $commands.Add($history[$i].Replace('`','')) | Out-Null 
              $i++       
          }
          $commands.Add($history[$i].Replace('`','')) | Out-Null
          $i++
          # Now we join it all together with newline characters
          $command = $commands -join "`n"
          $historyList.Add([pscustomobject]@{
          Number = $i + 1
              Command = $command
        }) | Out-Null
      } else {
          $historyList.Add([pscustomobject]@{
          Number = $i + 1
              Command = $history[$i]
        }) | Out-Null
          $i++  
      }                           
  }
  return $historyList
} 

function Get-PSReadLineHistory {
  [CmdletBinding()]
  [Alias('gph')]
  param()
  Format-PSReadLineHistory | Format-Table -HideTableHeaders -AutoSize
}
Set-Alias hist Get-PSReadLineHistory

function Find-PSReadLineHistory {
  [CmdletBinding()]
  [Alias('fph')]
  param([parameter(Position=0)]$keyword)
  Format-PSReadLineHistory | Where-Object { $($_.Command.Replace('`n','; ')) -match $keyword } | Format-Table -HideTableHeaders -AutoSize 
}
Set-Alias searchhist Get-PSReadLineHistory


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
#      Terraform related
###====================================================================================###

function tfapply {
  # Run an apply using the tfvars file in the current folder
  #Param($message)
  $VarFile=(Get-ChildItem -Path .  -Recurse -Filter "*.tfvars")
  terraform apply --auto-approve -var-file="$VarFile"
}

function tfdestroy {
  # Run a destroy using the tfvars file in the currenmt folder 
  #Param($message)
  $VarFile=(Get-ChildItem -Path .  -Recurse -Filter "*.tfvars")
  terraform destroy --auto-approve -var-file="$VarFile"
}

function tfshow {
  # 
  terraform show
}



###====================================================================================###
#      Kubernetes related
###====================================================================================###

function SetKubePath { [Environment]::SetEnvironmentVariable("KUBE_CONFIG_PATH", "~/.kube/config") }
Set-Alias k8spath SetKubePath

# Bunch of Aliases
# https://manjit28.medium.com/powershell-define-shortcut-alias-for-common-kubernetes-commands-1c006d68cce2
Set-Alias -Name k -Value kubectl

function GetPods([string]$namespace='kube-system') { kubectl get pods -n $namespace }
Set-Alias -Name kgp -Value GetPods
 
function GetPods() { kubectl get pods -A }
Set-Alias -Name kgpa -Value GetPods

function GetPodsWide([string]$namespace='kube-system') { kubectl get pods -n $namespace -o wide }
Set-Alias -Name kgpw -Value GetPods

function GetPods() { kubectl get pods -A -o wide}
Set-Alias -Name kgpwa -Value GetPods

function GetAll([string]$namespace='kube-system') { kubectl get all -n $namespace }
Set-Alias -Name kgall -Value GetAll

function GetNodes() { kubectl get nodes -o wide }
Set-Alias -Name kgn -Value GetNodes

function DescribePod([string]$container, [string]$namespace='kube-system') { kubectl describe po $container -n $namespace }
Set-Alias -Name kdp -Value DescribePod

function GetLogs([string]$container, [string]$namespace='kube-system') { kubectl logs pod/$container -n $namespace }
Set-Alias -Name klp -Value GetLogs

function ApplyYaml([string]$filename, [string]$namespace='kube-system') { kubectl apply -f $filename -n $namespace }
Set-Alias -Name kaf -Value ApplyYaml

#function ExecContainerShell([string]$container, [string]$namespace='default') { kubectl exec -it $container -n $namespace — sh }
#Set-Alias -Name kexec -Value ExecContainerShell

###====================================================================================###
###                                  Azure related                                     ###

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

    <# Could check this too
    $AccessToken = Get-AzAccessToken -ErrorAction SilentlyContinue
    if (!$AccessToken) {
      Write-Host "Login needed"
      try {
          Login-AzAccount -ErrorAction stop > Out-Null
      }
      catch
      {
          throw "Could not login to Azure"
      }
      } else {
          Write-Host "Already logged in"
    }
    #>

    
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
Set-Alias azlogin AZCommConnectSP

function AZcommLogout () { azlogout "az logout --username $SPAppID" }
Set-Alias azlogout AZcommLogout

### Add later
# az serial-console connect -g "CoreVMs" -n "labnode-1098"

#-- Start and stop some VMs I use
$VMGroup = "CoreVMs"

function StartCoreVMs {
  Start-AzVM -ResourceGroupName "$VMGroup" "linuxtools" -NoWait
  Start-AzVM -ResourceGroupName "$VMGroup" "WinServer" -NoWait
  Start-AzVM -ResourceGroupName "$VMGroup" "labnode-1098" -NoWait
}
Set-Alias stcore StartCoreVMs

function StopCoreVMs {
  Stop-AzVM -ResourceGroupName "$VMGroup" "linuxtools" -NoWait -Force
  Stop-AzVM -ResourceGroupName "$VMGroup" "WinServer" -NoWait -Force
  Stop-AzVM -ResourceGroupName "$VMGroup" "labnode-1098" -NoWait -Force
}
Set-Alias stpcore StopCoreVMs

# Azure Serial Consoles
function ToolsCon { az serial-console connect -g "$VMGroup" -n "linuxtools" }
function LoadgenCon { az serial-console connect -g "$VMGroup" -n "labnode-1098" }


# Azure Info
function ListAllRegions () {
  # Print list of available regions
  az account list-locations --query "[].{Name:name,region:regionalDisplayName,DisplayName:displayName}" -o table 
}
Set-Alias azregions ListAllRegions

function ListMyRegions () {
  # Print list of available regions
  Get-AzLocation | Select-Object location,displayname
}
Set-Alias myregions ListMyRegions



###====================================================================================###
###                                 Misc utilities                                     ###

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