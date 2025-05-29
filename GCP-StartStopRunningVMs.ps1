###========================================================================###
<#     
   Shutdown or Start VMs based on their status
#>
###========================================================================###

# Fetch the list of VMs dynamically from GCP
Write-Host "Fetching list of VMs from Google Cloud..."
$vmData = & gcloud compute instances list --format="table(name,zone,status)"

# Split the data into individual lines
$lines = $vmData -split "\r?\n"  # Handle newline variations

# Initialize an array to store parsed VM objects
$vms = @()

# Loop through each line and parse
foreach ($line in $lines) {
    $columns = $line -split '\s+'  # Split the line by whitespace
    if ($columns[0] -ne "NAME" -and $columns[0] -ne "") {  # Skip header and empty lines
        $vms += @{ 
            Name   = $columns[0]
            Zone   = $columns[1]
            Status = $columns[-1]  # Fetch Status dynamically
        }
    }
}

# Prompt the user for the VM name to manage
$vmNameToManage = Read-Host "Enter the name of the VM you want to start or stop"

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