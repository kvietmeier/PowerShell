# PowerShell Script to shutdown Google Cloud VMs with a "RUNNING" state.
# This script uses 'gcloud' to fetch VM data as JSON, making it more robust
# than parsing plain text output.

# ====================================================================
# WARNING: This script will attempt to stop ALL running VMs in your
#          currently active Google Cloud project.
# ====================================================================
Write-Host "WARNING: This script will shut down all RUNNING VMs in the currently active project." -ForegroundColor Red

# Add a confirmation prompt before proceeding.
$confirmation = Read-Host "Are you sure you want to continue? (Type 'yes' to proceed)"
if ($confirmation -ne "yes") {
    Write-Host "Script cancelled by user. No VMs were stopped." -ForegroundColor Yellow
    return
}

# Get the currently active gcloud project.
Write-Host "Fetching the currently active Google Cloud project..."
try {
    # This command retrieves the project ID from your gcloud configuration.
    $currentProject = gcloud config get-value project
    Write-Host "Operating on project: '$currentProject'" -ForegroundColor Cyan
} catch {
    Write-Error "Failed to retrieve the active project. Please ensure 'gcloud' is installed and configured."
    Write-Error $_
    return
}

# Define the data source. We'll get this directly from 'gcloud'
# The '--format=json' flag ensures a consistent, machine-readable output.
# We pipe the output directly to ConvertFrom-Json.
Write-Host "Fetching list of all Google Cloud VMs..."
try {
    $vms = gcloud compute instances list --format=json | ConvertFrom-Json
} catch {
    Write-Error "Failed to retrieve VM list. Please ensure 'gcloud' is installed and authenticated."
    Write-Error $_
    return
}

if ($null -eq $vms -or $vms.Count -eq 0) {
    Write-Host "No VMs found. Exiting script."
    return
}

# Loop through each VM and check its status.
foreach ($vm in $vms) {
    # Check if the VM's current status is "RUNNING".
    if ($vm.status -eq "RUNNING") {
        Write-Host "Stopping VM: $($vm.name) in zone: $($vm.zone)" -ForegroundColor Yellow

        # Construct the command to stop the VM.
        # We use '&' to call the external 'gcloud.exe' executable.
        # This is the preferred method for calling external commands in PowerShell.
        try {
            & gcloud compute instances stop $vm.name --zone=$vm.zone
            Write-Host "Successfully stopped VM: $($vm.name)" -ForegroundColor Green
        } catch {
            Write-Error "Failed to stop VM: $($vm.name). Error details:"
            Write-Error $_
        }
    }
    else {
        # If the VM is not running, we skip it and print a message.
        Write-Host "Skipping VM: $($vm.name) (Status: $($vm.status))"
    }
}

Write-Host "Script execution complete."
