###=================================================================================###
#  Filename: checkvpn.ps1
#  
#  Description:
#    Is my Cato VPN client runningn
#
#  Written By: Karl Vietmeier and ChatGPT                                            
#                                                                            
###=================================================================================###

# Check for common VPN processes
$vpnProcesses = @("openvpn", "forticlient", "vpn", "cisco", "softether", "CatoClient")

# Get a list of running processes
$runningProcesses = Get-Process | Where-Object { $_.Name -in $vpnProcesses }

if ($runningProcesses) {
    Write-Output "VPN is currently running:"
    $runningProcesses | ForEach-Object { $_.Name }
} else {
    Write-Output "No VPN is running."
}

# Alternatively, check network adapters
$networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

foreach ($adapter in $networkAdapters) {
    if ($adapter.Name -like "*Cato*") {
        Write-Output "VPN adapter detected: $($adapter.Name)"
    }
}
