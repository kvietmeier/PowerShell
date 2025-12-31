###========================================================================###
<#    
   Script Name: Toggle-GCP-VMs.ps1
   Purpose    : Starts or stops a predefined list of Google Cloud VMs based on a 
               command-line argument.
   
   Description:
   - This script requires one command-line argument: "start" or "stop".
   - It iterates through a hardcoded list of VMs and checks their current status.
   - If the VM's status is the opposite of the requested action, it will perform the action.
   - Example: Running `.\Toggle-GCP-VMs.ps1 start` will start all VMs in the list that are currently stopped.

   Usage Notes:
   - Requires gcloud CLI to be installed and authenticated.
   - User must have permissions to list and manage instances in the current project.
   - The list of VMs to manage is hardcoded within the script.

   Author     : Karl Vietmeier
   Version    : 1.1
   Last Update: 2025-07-08
#>
###========================================================================###

# --- Define the VMs to be managed ---
# Add or remove VM names from this list as needed.
$vmsToManage = @("devops01", "w22server01")

# --- Get the command-line argument and validate it ---
if ($args.Count -ne 1) {
    Write-Error "Invalid number of arguments. Please provide exactly one argument: 'start' or 'stop'."
    exit
}

$action = $args[0].ToLower()
if ($action -ne "start" -and $action -ne "stop") {
    Write-Error "Invalid argument. Please use 'start' or 'stop'."
    exit
}

# --- Get the current active gcloud project for context ---
Write-Host "Fetching the currently active Google Cloud project..." -ForegroundColor Cyan
try {
    $currentProject = gcloud config get-value project
    Write-Host "Operating on project: '$currentProject'"
} catch {
    Write-Error "Failed to retrieve the active project. Please ensure 'gcloud' is installed and configured."
    return
}

# --- Loop through the list of VMs and toggle their status ---
foreach ($vmName in $vmsToManage) {
    Write-Host "`nChecking status for VM: $($vmName)..." -ForegroundColor Yellow

    try {
        # Fetch the status and zone for the specific VM using JSON format
        $vmDetails = gcloud compute instances describe $vmName --format="json" | ConvertFrom-Json
        
        if (-not $vmDetails) {
            Write-Host "VM '$($vmName)' not found in this project. Skipping." -ForegroundColor Red
            continue
        }

        $vmZone = ($vmDetails.zone -split '/')[-1]
        $vmStatus = $vmDetails.status
        
        Write-Host "VM '$($vmName)' is currently in state: $($vmStatus) (Zone: $($vmZone))"

        # Perform the requested action if the VM is in the opposite state
        if ($action -eq "start" -and $vmStatus -ne "RUNNING") {
            Write-Host "Action: Starting VM '$($vmName)'..." -ForegroundColor Green
            & gcloud compute instances start $vmName --zone=$vmZone
        } elseif ($action -eq "stop" -and $vmStatus -eq "RUNNING") {
            Write-Host "Action: Stopping VM '$($vmName)'..." -ForegroundColor Green
            & gcloud compute instances stop $vmName --zone=$vmZone
        } else {
            Write-Host "Skipping VM '$($vmName)'. It is already in the desired state or a different action is requested."
        }
    } catch {
        Write-Error "An error occurred while attempting to manage VM '$($vmName)'."
        Write-Error $_
    }
}

Write-Host "`nScript execution complete."
