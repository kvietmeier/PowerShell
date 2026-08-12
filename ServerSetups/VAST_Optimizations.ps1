 ###=================================================================================###
<# 
  Filename: VAST_Optimizations.ps1
  
  Description: Applies baseline storage and network performance optimizations for 
  Windows Server & VAST Data Integration. Tunes SMB, RSS, MTU, SET, and RSC.
  Note: Execution requires administrative privileges.

  Configurations Applied:
  1. SMB Client & Registry Caching Optimization
  2. Receive-Side Scaling (RSS) Core Alignment
  3. Jumbo Frames MTU Standard (Driver-Agnostic)
  4. Hyper-V Switch Embedded Teaming (SET) Configuration
  5. Hardware Receive Segment Coalescing (RSC) Disabling
  
  Written By: Gemini 
#>
###=================================================================================###

#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string[]]$StorageAdapters = @("Ethernet1", "Ethernet2"),
    [string]$VSwitchName = "vSwitch-Storage",
    [string]$JumboMtuValue = "9014"
)

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ErrorActionPreference = "Stop"

    # Restore System32 PATH integrity
    $Sys32 = "$env:SystemRoot\System32"
    if (($env:PATH -split ';') -notcontains $Sys32) { 
        $env:PATH = "$Sys32;$env:PATH" 
    }

    Write-Output "Starting Windows Server Tuning for VAST Data Integration..."

    # 1. SMB Client & Registry Caching Optimization
    Write-Output "Optimizing SMB Client Configuration..."
    Set-SmbClientConfiguration -RequireSecuritySignature $false `
                               -EnableSecuritySignature $false `
                               -ConnectionCountPerRssNetworkInterface 8 `
                               -EnableBandwidthThrottling $false `
                               -EnableMultiChannel $true `
                               -Confirm:$false

    $RegPath = "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters"
    $SmbTuning = @{
        "FileInfoCacheEntriesMax"     = 1024
        "DirectoryCacheEntriesMax"    = 1024
        "FileNotFoundCacheEntriesMax" = 2048
        "DormantFileLimit"            = 256
    }
    
    foreach ($Key in $SmbTuning.Keys) {
        if ((Get-ItemProperty -Path $RegPath -Name $Key -ErrorAction SilentlyContinue).$Key -ne $SmbTuning[$Key]) {
            New-ItemProperty -Path $RegPath -Name $Key -PropertyType DWORD -Value $SmbTuning[$Key] -Force | Out-Null
        }
    }

    # 2. Receive-Side Scaling (RSS) Core Alignment
    Write-Output "Aligning Receive-Side Scaling (RSS) Cores..."
    foreach ($AdapterName in $StorageAdapters) {
        if (Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue) {
            Set-NetAdapterRss -Name $AdapterName `
                              -Profile Closest `
                              -NumberOfReceiveQueues 16 `
                              -MaxProcessors 16
        } else {
            Write-Warning "Adapter '$AdapterName' not found. Skipping RSS config."
        }
    }

    # 3. Jumbo Frames MTU Standard (Driver-Agnostic)
    Write-Output "Setting Jumbo Frames (MTU $JumboMtuValue)..."
    foreach ($AdapterName in $StorageAdapters) {
        if (Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue) {
            $JumboProp = Get-NetAdapterAdvancedProperty -Name $AdapterName -ErrorAction SilentlyContinue | 
                         Where-Object { $_.DisplayName -match "Jumbo" }
            if ($JumboProp) {
                Set-NetAdapterAdvancedProperty -Name $AdapterName `
                                               -DisplayName $JumboProp.DisplayName `
                                               -RegistryValue $JumboMtuValue
            } else {
                Write-Warning "Jumbo Frame property not exposed by driver on '$AdapterName'."
            }
        }
    }

    # 4. Hyper-V Switch Embedded Teaming (SET) Configuration
    Write-Output "Checking Hyper-V Switch Embedded Teaming (SET)..."
    if (Get-Module -ListAvailable -Name Hyper-V) {
        $ExistingVSwitch = Get-VMSwitch -Name $VSwitchName -ErrorAction SilentlyContinue
        if (-not $ExistingVSwitch) {
            $ValidAdapters = $StorageAdapters | Where-Object { Get-NetAdapter -Name $_ -ErrorAction SilentlyContinue }
            if ($ValidAdapters.Count -gt 0) {
                New-VMSwitch -Name $VSwitchName `
                             -NetAdapterName $ValidAdapters `
                             -EnableEmbeddedTeaming $true `
                             -AllowManagementOS $true
            } else {
                Write-Warning "No valid physical adapters available to create vSwitch '$VSwitchName'."
            }
        }

        if (Get-VMSwitch -Name $VSwitchName -ErrorAction SilentlyContinue) {
            Set-VMSwitchTeam -Name $VSwitchName `
                             -TeamingMode SwitchIndependent `
                             -LoadBalancingAlgorithm Dynamic
        }
    } else {
        Write-Warning "Hyper-V role/module not installed. Skipping vSwitch creation."
    }

    # 5. Hardware-Specific Driver Configurations (Disable RSC)
    Write-Output "Disabling Receive Segment Coalescing (RSC)..."
    foreach ($AdapterName in $StorageAdapters) {
        if (Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue) {
            Disable-NetAdapterRsc -Name $AdapterName -ErrorAction SilentlyContinue
        }
    }

    Write-Output "VAST Data Windows Server Tuning Successfully Completed."

} catch {
    Write-Error "VAST Optimization Script failed: $($_.Exception.Message)"
    exit 1
}