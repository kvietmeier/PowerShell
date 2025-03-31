###========================================================================###
<#    
   Shutdown VMs with a "running" state
#>
###========================================================================###


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

# Loop through VMs and stop those with status "RUNNING"
foreach ($vm in $vms) {
    if ($vm.Status -eq "RUNNING") {
        Write-Host "Stopping VM: $($vm.Name) in zone: $($vm.Zone)"
        $command = "gcloud compute instances stop $($vm.Name) --zone=$($vm.Zone)"
        Invoke-Expression $command
    } else {
        Write-Host "Skipping VM: $($vm.Name) (Status: $($vm.Status))"
    }
}