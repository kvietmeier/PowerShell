###====================================================================================================###
<#   
  Section     : Azure Related Functions
  Author      : Karl Vietmeier
  Created On  : <Insert Date>

  Purpose:
    Provides helper functions and aliases for Azure CLI and Az PowerShell module tasks:
      * Tab-completion for `az` CLI
      * Service Principal authentication (CLI and Az module)
      * Quick start/stop for commonly used VMs
      * Build and tear-down VoltDB and NVMe clusters
      * Serial console connection helpers
      * Region listing and Azure info utilities
#>
###====================================================================================================###


###====================================================================================================###
###--- Azure CLI Tab Completion
###====================================================================================================###
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


###====================================================================================================###
###--- Azure Authentication Functions
###====================================================================================================###
function MyAZContext {
    if (-not $SubID) {
        Write-Host "Variable `\$SubID` not set. Please define subscription details first." -ForegroundColor Yellow
        return
    }

    $context = Get-AzContext

    if (!$context -or ($context.Subscription.Id -ne $SubID)) {
        Write-Host ""
        Write-Host "======================================================="
        Write-Host "  No Azure Connection use Alias 'azconn' to connect  "
        Write-Host "======================================================="
        Write-Host ""
        exit
    }
    else {
        Write-Host ""
        Write-Host "======================================================================="
        Write-Host "  $SubName in $AADDomain is logged in"
        Write-Host "======================================================================="
    }
}

Set-Alias azcontext MyAZContext

function AZConnectSP {
    if (-not ($SPAppID -and $SPSecret -and $TenantID -and $SubID)) {
        Write-Host "Missing required variables for Service Principal login." -ForegroundColor Red
        return
    }

    $context = Get-AzContext

    if (!$context -or ($context.Subscription.Id -ne $SubID)) {
        Write-Host ""
        Write-Host "Authenticating to Subscription: $SubID with Service Principal"
        Write-Host ""

        $SPPassWd = $SPSecret | ConvertTo-SecureString -AsPlainText -Force 
        $SPCred   = New-Object -TypeName System.Management.Automation.PSCredential($SPAppID, $SPPassWd)
        Connect-AzAccount -ServicePrincipal -Credential $SPCred -Tenant $TenantID
    }
    else {
        Write-Host ""
        Write-Host "SubscriptionId $SubID is connected - no action required"
        Write-Host ""
    }
}
Set-Alias azconn AZConnectSP
Set-Alias azdconn Disconnect-AzAccount

function AZ_CLI_ConnectSP {
    if (-not ($SPAppID -and $SPSecret -and $TenantID -and $SubID)) {
        Write-Host "Missing required variables for Azure CLI Service Principal login." -ForegroundColor Red
        return
    }

    az account set --subscription $SubID
    az login --service-principal `
      --username $SPAppID `
      --password $SPSecret `
      --tenant $TenantID
}
Set-Alias azlogin AZ_CLI_ConnectSP

function AZ_CLI_Logout { az logout --username $SPAppID }
Set-Alias azlogout AZ_CLI_Logout

function AZ_CLI_ShowAcct { az account show --output table }
Set-Alias azshow AZ_CLI_ShowAcct


###====================================================================================================###
###--- Azure VM Start/Stop Helpers
###====================================================================================================###
$CoreRG = "CoreVMs"
$VoltRG = "TMP-VoltTesting"

function StartCoreVMs {
    Start-AzVM -ResourceGroupName $CoreRG -Name "linuxtools" -NoWait
    Start-AzVM -ResourceGroupName $CoreRG -Name "WinServer" -NoWait
}
Set-Alias stcore StartCoreVMs

function StopCoreVMs {
    Stop-AzVM -ResourceGroupName $CoreRG -Name "linuxtools" -NoWait -Force
    Stop-AzVM -ResourceGroupName $CoreRG -Name "WinServer" -NoWait -Force
}
Set-Alias stpcore StopCoreVMs

function StartTools { Start-AzVM -ResourceGroupName $CoreRG -Name "linuxtools" -NoWait }
Set-Alias stools StartTools

function StopTools { Stop-AzVM -ResourceGroupName $CoreRG -Name "linuxtools" -NoWait }
Set-Alias stptools StopTools

function StartWin { Start-AzVM -ResourceGroupName $CoreRG -Name "WinServer" -NoWait }
Set-Alias stwin StartWin

function StopWin { Stop-AzVM -ResourceGroupName $CoreRG -Name "WinServer" -NoWait }
Set-Alias stpwin StopWin


###====================================================================================================###
###--- VoltDB VM Control
###====================================================================================================###
function StartVolt {
    Start-AzVM -ResourceGroupName $VoltRG -Name "voltnode-01" -NoWait
    Start-AzVM -ResourceGroupName $VoltRG -Name "voltnode-02" -NoWait
}
Set-Alias stvolt StartVolt

function StopVoltVMs {
    Stop-AzVM -ResourceGroupName $VoltRG -Name "voltnode-01" -NoWait -Force
    Stop-AzVM -ResourceGroupName $VoltRG -Name "voltnode-02" -NoWait -Force
    Stop-AzVM -ResourceGroupName $VoltRG -Name "voltnode-03" -NoWait -Force
}
Set-Alias stpvolt StopVoltVMs

function BuildNVME { & "C:\Users\ksvietme\repos\AzureLabs\scripts\MultiVM_NVMe_DBCluster.ps1" }
Set-Alias bnvme BuildNVME

function BuildSCSI { & "C:\Users\ksvietme\repos\AzureLabs\scripts\MultiVM_SCSI_DBCluster.ps1" }
Set-Alias bscsi BuildSCSI

function DelNVMERG { Remove-AzResourceGroup -Name "TMP-VoltTesting" -Force }
Set-Alias dnvme DelNVMERG

function DelSCSIRG { Remove-AzResourceGroup -Name "SCSI-VoltTesting" -Force }
Set-Alias dscsi DelSCSIRG


###====================================================================================================###
###--- Azure Serial Console Helpers
###====================================================================================================###
function ToolsCon { az serial-console connect -g $CoreRG -n "linuxtools" }
function Volt1Con { az serial-console connect -g $VoltRG -n "vdb-01" }
function Volt2Con { az serial-console connect -g $VoltRG -n "vdb-02" }
function Volt3Con { az serial-console connect -g $VoltRG -n "vdb-03" }
function Volt4Con { az serial-console connect -g $VoltRG -n "vdb-04" }
function Volt5Con { az serial-console connect -g $VoltRG -n "vdb-05" }
function Volt6Con { az serial-console connect -g $VoltRG -n "vdb-06" }
function Volt7Con { az serial-console connect -g $VoltRG -n "vdb-07" }
function Volt8Con { az serial-console connect -g $VoltRG -n "vdb-08" }

function VMCon {
    param($VMName)
    az serial-console connect -g $VoltRG -n $VMName
}


###====================================================================================================###
###--- Azure Info Functions
###====================================================================================================###
function ListAllRegions {
    az account list-locations --query '[].{Name:name,region:regionalDisplayName,DisplayName:displayName}' -o table
}
Set-Alias azregions ListAllRegions

function ListMyRegions {
    Get-AzLocation | Select-Object location,displayname
}
Set-Alias myregions ListMyRegions
