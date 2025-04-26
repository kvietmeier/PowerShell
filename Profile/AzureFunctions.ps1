###====================================================================================================###
###--- Azure Related Functions
###====================================================================================================###

# Tab Completion for AZ CLI
Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
  $completion_file = New-TemporaryFile
  $env:ARGCOMPLETE_USE_TEMPFILES = 1
  $env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
  $env:COMP_LINE = $wordToComplete
  $env:COMP_POINT = $cursorPosition
  $env:_ARGCOMPLETE = 1
  $env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
  $env:_ARGCOMPLETE_IFS = "`n"
  $env:_ARGCOMPLETE_SHELL = 'powershell'
  az 2>&1 | Out-Null
  Get-Content $completion_file | Sort-Object | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
  }
  Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL
}


###--- Authentication 
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
Set-Alias azcontext MyAZContext

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


#-- Do this with the Azure CLI
function AZ_CLI_ConnectSP () {
  az account set --subscription $SubID
  az login --service-principal `
   --username $SPAppID `
   --password $SPSecret `
   --tenant $TenantID
}
Set-Alias azlogin AZ_CLI_ConnectSP

function AZ_CLI_Logout () { az logout --username $SPAppID }
Set-Alias azlogout AZ_CLI_Logout

function AZ_CLI_ShowAcct () { az account show --output table }
Set-Alias azshow AZ_CLI_ShowAcct



#-- Start and stop some VMs I use
$CoreRG = "CoreVMs"
$VoltRG = "TMP-VoltTesting"

function StartCoreVMs {
  Start-AzVM -ResourceGroupName "$CoreRG" "linuxtools" -NoWait
  Start-AzVM -ResourceGroupName "$CoreRG" "WinServer" -NoWait
}
Set-Alias stcore StartCoreVMs

#--- VoltDB nodes
function StartVolt {
  Start-AzVM -ResourceGroupName "$VoltPG" "voltnode-01" -NoWait
  Start-AzVM -ResourceGroupName "$VoltPG" "voltnode-02" -NoWait
}
Set-Alias stvolt StartVolt

function StopVoltVMs {
  Stop-AzVM -ResourceGroupName "$VoltPG" "voltnode-01" -NoWait -Force
  Stop-AzVM -ResourceGroupName "$VoltPG" "voltnode-02" -NoWait -Force
  Stop-AzVM -ResourceGroupName "$VoltPG" "voltnode-03" -NoWait -Force
}
Set-Alias stpvolt StopVoltVMs
#---

function StartTools {
  Start-AzVM -ResourceGroupName "$CoreRG" "linuxtools" -NoWait 
}
Set-Alias stools StartTools

function StartWin {
  Start-AzVM -ResourceGroupName "$CoreRG" "WinServer" -NoWait
}
Set-Alias stwin StartWin

function StopCoreVMs {
  Stop-AzVM -ResourceGroupName "$CoreRG" "linuxtools" -NoWait -Force
  Stop-AzVM -ResourceGroupName "$CoreRG" "WinServer" -NoWait -Force
}
Set-Alias stpcore StopCoreVMs

function StopTools {
  Stop-AzVM -ResourceGroupName "$CoreRG" "linuxtools" -NoWait
}
Set-Alias stptools StopTools

function StopWin {
  Stop-AzVM -ResourceGroupName "$CoreRG" "WinServer" -NoWait
}
Set-Alias stpwin StopWin

###  Volt functions - build/destroy
# Run the create VM script
function BuildNVME {
  C:\Users\ksvietme\repos\AzureLabs\scripts\MultiVM_NVMe_DBCluster.ps1
}
Set-Alias bnvme BuildNVME

function BuildSCSI {
  C:\Users\ksvietme\repos\AzureLabs\scripts\MultiVM_SCSI_DBCluster.ps1
}
Set-Alias bscsi BuildSCSI

# Delete the PG
function DelNVMERG {
  Remove-AzResourceGroup -Name "TMP-VoltTesting" -Force
}
Set-Alias dnvme DelNVMERG

function DelSCSIRG {
  Remove-AzResourceGroup -Name "SCSI-VoltTesting" -Force
}
Set-Alias dscsi DelSCSIRG

# Serial Consoles
# To exit: Ctrl + ] and then q
function ToolsCon { az serial-console connect -g "$CoreRG" -n "linuxtools" }
function Volt1Con { az serial-console connect -g "$VoltRG" -n "vdb-01" }
function Volt2Con { az serial-console connect -g "$VoltRG" -n "vdb-02" }
function Volt3Con { az serial-console connect -g "$VoltRG" -n "vdb-03" }
function Volt4Con { az serial-console connect -g "$VoltRG" -n "vdb-04" }
function Volt4Con { az serial-console connect -g "$VoltRG" -n "vdb-05" }
function Volt4Con { az serial-console connect -g "$VoltRG" -n "vdb-06" }
function Volt4Con { az serial-console connect -g "$VoltRG" -n "vdb-07" }
function Volt4Con { az serial-console connect -g "$VoltRG" -n "vdb-08" }

function VMCon () {
  # usage: VMCon <vmname>
  param($VMName)
  az serial-console connect -g $VoltRG -n $VMName
}

###---  End Volt

###--- Misc Azure Stuff
###--- Azure Serial Consoles
<# 
### Add Params - $RG and $VMname
function VMCon () {
  param($RG, $VMName)
  az serial-console connect -g $RG -n $VMName
}
#>


### Azure Info
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
