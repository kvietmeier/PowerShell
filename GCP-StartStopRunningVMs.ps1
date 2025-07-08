###========================================================================###
<#     
   Script Name: Manage-GCP-VMs.ps1
   Purpose    : Allows interactive management (start/stop) of Google Cloud VMs.
   
   Description:
   - Dynamically fetches a list of Google Cloud VMs including their name, zone, 
     status, and instance type.
   - Displays a formatted summary of VM counts by status (RUNNING, TERMINATED, etc).
   - Lists all VMs with aligned columns for readability.
   - Prompts the user to select a VM by name.
   - Based on current status, the user can start or stop the selected VM.

   Usage Notes:
   - Requires gcloud CLI to be installed and authenticated.
   - User must have permissions to list and manage instances in the current project.
   - Run this script in a PowerShell terminal with access to the `gcloud` command.

   Author     : Karl Vietmeier
   Version    : 1.0
   Last Update: 2025-07-07
#>
###========================================================================###

Write-Host "Fetching list of VMs from Google Cloud..."
$vmData = & gcloud compute instances list --format="table(name,zone,status,machineType)"
$lines = $vmData -split "\r?\n"

$vms = @()

foreach ($line in $lines) {
    $columns = $line -split '\s+'
    if ($columns[0] -ne "NAME" -and $columns[0] -ne "") {
        # Extract instance type from full machineType URI (if present)
        $machineType = $columns[3] -replace '.*/', ''
        $vms += @{ 
            Name         = $columns[0]
            Zone         = $columns[1]
            Status       = $columns[2]
            InstanceType = $machineType
        }
    }
}

# Display the list of VMs to the user with aligned columns
Write-Host "`nAvailable VMs:"
Write-Host "-------------------------------------------------------------------------------"
Write-Host ("{0,-25} {1,-25} {2,-12} {3,-20}" -f "Name", "Zone", "Status", "Instance Type")
Write-Host "-------------------------------------------------------------------------------"

foreach ($vm in $vms) {
    Write-Host ("{0,-25} {1,-25} {2,-12} {3,-20}" -f $vm.Name, $vm.Zone, $vm.Status, $vm.InstanceType)
}
Write-Host "-------------------------------------------------------------------------------`n"


# Prompt the user for the VM name to manage
$vmNameToManage = Read-Host "Enter the name of the VM you want to start or stop (press Enter to cancel)"

# Exit if no input was provided
if (-not $vmNameToManage) {
    Write-Host "No VM name provided. Exiting script."
    exit
}

# Find the VM in the parsed list
$vmToManage = $vms | Where-Object { $_.Name -eq $vmNameToManage }

if ($vmToManage) {
    # Prompt the user to select an action
    $action = Read-Host "Do you want to start or stop the VM? Type 'start' or 'stop'"

    # Perform the requested action
    if ($action -eq "start" -and $vmToManage.Status -ne "RUNNING") {
        Write-Host "Starting VM: $($vmToManage.Name) in zone: $($vmToManage.Zone)"
        $command = "gcloud compute instances start $($vmToManage.Name) --zone=$($vmToManage.Zone)"
        Invoke-Expression $command
    } elseif ($action -eq "stop" -and $vmToManage.Status -eq "RUNNING") {
        Write-Host "Stopping VM: $($vmToManage.Name) in zone: $($vmToManage.Zone)"
        $command = "gcloud compute instances stop $($vmToManage.Name) --zone=$($vmToManage.Zone)"
        Invoke-Expression $command
    } else {
        Write-Host "VM '$($vmToManage.Name)' is already in the desired state or action is invalid."
    }
} else {
    Write-Host "VM with name '$vmNameToManage' not found. Please verify the VM name."
}
