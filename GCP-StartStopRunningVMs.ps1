###========================================================================###
<#    
   Script Name: Manage-GCP-VMs.ps1
   Purpose    : Allows interactive management (start/stop) of Google Cloud VMs.
   
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

   Author     : Karl Vietmeier
   Version    : 1.0
   Last Update: 2025-07-07
#>
###========================================================================###

# --- Function to get and display VM list from gcloud using JSON ---
function Get-VMList {
    Write-Host "Fetching list of VMs from Google Cloud..." -ForegroundColor Yellow
    try {
        # Use gcloud with JSON format for reliable parsing
        $vmData = gcloud compute instances list --format="json" | ConvertFrom-Json
        
        if (-not $vmData) {
            Write-Host "No VMs found. Exiting script."
            exit
        }

        # Create a new, cleaner array of VM objects
        $vms = @()
        foreach ($vm in $vmData) {
            # Machine type and Zone come in as full URIs, so we grab just the name
            $simpleMachineType = ($vm.machineType -split '/')[-1]
            $simpleZone = ($vm.zone -split '/')[-1]
            
            $vms += [PSCustomObject]@{
                Name         = $vm.name
                Zone         = $simpleZone
                Status       = $vm.status
                InstanceType = $simpleMachineType
            }
        }

        # Display the list of VMs to the user with aligned columns
        Write-Host "`nAvailable VMs:" -ForegroundColor Cyan
        Write-Host "-------------------------------------------------------------------------------"
        Write-Host ("{0,-25} {1,-25} {2,-12} {3,-20}" -f "Name", "Zone", "Status", "Instance Type")
        Write-Host "-------------------------------------------------------------------------------"

        foreach ($vm in $vms) {
            Write-Host ("{0,-25} {1,-25} {2,-12} {3,-20}" -f $vm.Name, $vm.Zone, $vm.Status, $vm.InstanceType)
        }
        Write-Host "-------------------------------------------------------------------------------`n"
        return $vms
    } catch {
        Write-Error "Failed to retrieve VM list. Please ensure 'gcloud' is installed and authenticated."
        Write-Error $_
        exit
    }
}

# --- Main Script Logic ---

# Get and display the list of VMs
$vms = Get-VMList

# Prompt the user for the VM name to manage
$vmNameToManage = Read-Host "Enter the name of the VM you want to start or stop (press Enter to cancel)"

# Exit if no input was provided
if (-not $vmNameToManage) {
    Write-Host "No VM name provided. Exiting script."
    return
}

# Find the VM in the parsed list
# We use case-insensitive matching for better user experience
$vmToManage = $vms | Where-Object { $_.Name -eq $vmNameToManage }

if ($vmToManage) {
    Write-Host "Selected VM: $($vmToManage.Name) (Status: $($vmToManage.Status))" -ForegroundColor Green

    # Determine the action based on the VM's current status
    $actionPrompt = "Do you want to "
    if ($vmToManage.Status -eq "RUNNING") {
        $actionPrompt += "stop it? (Type 'stop' to confirm)"
    } else {
        $actionPrompt += "start it? (Type 'start' to confirm)"
    }

    $action = Read-Host $actionPrompt
    
    # Perform the requested action
    try {
        if ($action -eq "start" -and $vmToManage.Status -ne "RUNNING") {
            Write-Host "Starting VM: $($vmToManage.Name) in zone: $($vmToManage.Zone)" -ForegroundColor Yellow
            # Force PowerShell to pass the variable value as a string using a subexpression
            & gcloud compute instances start $($vmToManage.Name) --zone=$($vmToManage.Zone)
        } elseif ($action -eq "stop" -and $vmToManage.Status -eq "RUNNING") {
            Write-Host "Stopping VM: $($vmToManage.Name) in zone: $($vmToManage.Zone)" -ForegroundColor Yellow
            # Force PowerShell to pass the variable value as a string using a subexpression
            & gcloud compute instances stop $($vmToManage.Name) --zone=$($vmToManage.Zone)
        } else {
            Write-Host "Action cancelled or invalid. VM '$($vmToManage.Name)' is already in the desired state or action is not recognized."
        }
    } catch {
        Write-Error "An error occurred while attempting to manage VM '$($vmToManage.Name)'."
        Write-Error $_
    }
} else {
    Write-Host "VM with name '$vmNameToManage' not found. Please verify the VM name." -ForegroundColor Red
}

Write-Host "`nScript execution complete."
