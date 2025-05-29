
<#
###----------------------------------------------------------------------------------------### 
   The following commands require you to be logged into your Azure account
   Use "Connect-AzAccount" to authenticate

###----------------------------------------------------------------------------------------### 

  To check the routing table from the Azure SDN perspective use: "Get-AzEffectiveRouteTable"
  Requirement: Need Az Module and be connected to your Subscription (see above)
  In some cases info in the host OS can be misleading/not useful especially in an "all Azure" infrastructure.
  https://docs.microsoft.com/en-us/powershell/module/az.network/get-azeffectiveroutetable?view=azps-4.6.0

  ### Virtual Networks docs
  https://docs.microsoft.com/en-us/azure/virtual-machines/windows/ps-common-network-ref
  https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview
  https://docs.microsoft.com/en-us/azure/virtual-network/diagnose-network-routing-problem

#>

# Will Need for various tests - 
$AZResourceGroup  = "WVDLandscape01"
$AZStorageAcct    = "kvstor1551"
$AZFileShare      = "userprofiles"
$SMBSharePath     = "\\kvstor1551.file.core.windows.net\userprofiles\"
$VMName           = "testvm-1"
$Region           = "westus2"


# Dump the AddressSpace/subnets/DHCP Options for vNet
$RGName = "CoreInfrastructure-rg"
$VNetName = "VnetCore"
$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $RGName
Write-Output $vnet.DhcpOptions
Write-Output $vnet.AddressSpace
Write-Output $vnet.Subnets.AddressPrefix 


###--- Network Watcher
<# 
  Azure Native Tool - Like TCPdump for Azure SDN: 
  https://azure.microsoft.com/en-us/services/network-watcher/

  * Remotely capture packet data for your virtual machines
  * Monitor your virtual machine network security using flow logs and security group view
  * Diagnose your VPN connectivity issues

Install extension in VM - 
Set-AzVMExtension `
  -ResourceGroupName "myResourceGroup1" `
  -Location "WestUS" `
  -VMName "myVM1" `
  -Name "networkWatcherAgent" `
  -Publisher "Microsoft.Azure.NetworkWatcher" `
  -Type "NetworkWatcherAgentWindows" `
  -TypeHandlerVersion "1.4"

#>

<# 
  Test for Port 445 
  The ComputerName, or host, is <storage-account>.file.core.windows.net for Azure Public Regions.
  $storageAccount.Context.FileEndpoint is used because non-Public Azure regions, such as sovereign clouds
  or Azure Stack deployments, will have different hosts for Azure file shares (and other storage resources).
#>
# Is Port 445 open?
Test-NetConnection -ComputerName ([System.Uri]::new($AZStorageAcct.Context.FileEndPoint).Host) -Port 445

# Check the AZF Setup (need AZ Storage Module loaded)
Debug-AzStorageAccountAuth -StorageAccountName $AZStorageAcct -ResourceGroupName $AZResourceGroup -Verbose

<# 
###----------------------------------------------------------------------------------------### 

   VM Level Tests - Azure Context - Get route tables and manipulate NICs

###----------------------------------------------------------------------------------------### 
#>


# You need these for Azure commands so set them here
$NIC1 = "ubuntu-01989"
$NIC2 = "ubuntu01.nic2"
$NIC3 = ""
$RGgroup1 = "Networktests" 
$VMName1 = "Ubuntu-01"

# Get NICs if you know the VM name
$VM = Get-AzVM -Name $VMName1 -ResourceGroupName $RGgroup1 
$VM.NetworkProfile

<# 
  Routing Information - 
  Syntax -
  Get-AzEffectiveRouteTable `
    -NetworkInterfaceName "<Name of NIC resource>" `
    -ResourceGroupName "<RG Name>" | Format-Table
#>

 # Examples
Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC1  `
  -ResourceGroupName $RGroup1 | Format-Table

Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC2  `
  -ResourceGroupName $RGroup1 ` Format-Table

Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC3  `
  -ResourceGroupName $RGroup1 | Format-Table


### Get effective NSG security rules
<#
   While you are in the terminal, logged in to Azure, you can get more info without clicking through 
   5 levels of Portal menues:
   https://docs.microsoft.com/en-us/powershell/module/az.network/get-azeffectivenetworksecuritygroup?view=azps-4.6.1 
   
   Get-AzEffectiveNetworkSecurityGroup
     -NetworkInterfaceName <String>
     [-ResourceGroupName <String>]
     [-DefaultProfile <IAzureContextContainer>]
     [<CommonParameters>]

#>

Get-AzEffectiveNetworkSecurityGroup `
  -NetworkInterfaceName "$NIC3"  `
  -ResourceGroupName $RGroup1 | Format-Table



###---   Manipulate NICs - swap primaries 
$NIC1 = "ubuntu-01989"
$NIC2 = "ubuntu01.nic2"
$NIC3 = "ubuntu-0240"
$NIC4 = "ubuntu02-nic2"
$RGgroup1 = "Networktests" 
$VMName1 = "Ubuntu-01"
$VMName2 = "Ubuntu-02"

$VM1 = Get-AzVM -Name $VMName1 -ResourceGroupName $RGroup1
$VM2 = Get-AzVM -Name $VMName2 -ResourceGroupName $RGroup1
$NICS = $VM1.NetworkProfile.NetworkInterfaces
$NICS

# List existing NICs on the VM and find which one is primary
$VM1.NetworkProfile.NetworkInterfaces
$VM2.NetworkProfile.NetworkInterfaces

### These steps make a big mess - might be faster to start over.
# Set NIC [1] to be primary
$VM1.NetworkProfile.NetworkInterfaces[0].Primary = $false
$VM1.NetworkProfile.NetworkInterfaces[1].Primary = $true

# Set NIC [1] to be primary
$VM2.NetworkProfile.NetworkInterfaces[0].Primary = $false
$VM2.NetworkProfile.NetworkInterfaces[1].Primary = $true

# Update the VM state in Azure
Update-AzVM -VM $VM1 -ResourceGroupName $RGroup1
Update-AzVM -VM $VM2 -ResourceGroupName $RGroup1

# Accelerated Networking (VM needs to be deallocated)
$NIC = "ubuntu02-dpdk"
$RGgroup1 = "Networktests" 

$NIC=Get-AzNetworkInterface -Name $NIC -ResourceGroupName $RGgroup1
$NIC.EnableAcceleratedNetworking = $True
$NIC | Set-AzNetworkInterface
