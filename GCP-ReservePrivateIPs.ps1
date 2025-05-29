# Define your GCP project, region, and subnet
$projectId    = "clouddev-itdesk124"           # Name - not number
$region       = "us-west2" # Replace with your desired region
$subnetName   = "subnet-hub-us-west2-voc1" # Replace with your subnet name

# Define how many IPs you want to reserve
$numberOfIpsToReserve = 20

Write-Host "Starting reservation of $numberOfIpsToReserve auto-allocated internal IP addresses..."

for ($i = 1; $i -le $numberOfIpsToReserve; $i++) {
    $ipName = "auto-reserved-ip-$i"
    $description = "Auto-allocated internal IP for batch reservation #$i"

    Write-Host "Attempting to reserve auto-allocated IP (Name: $ipName)"

    try {
        gcloud compute addresses create $ipName `
            --region=$region `
            --subnet=$subnetName `
            --project=$projectId `
            --description="$description" `
            --quiet # --quiet prevents interactive prompts

        Write-Host "Successfully reserved auto-allocated IP with name: ${ipName}"
    }
    catch {
        Write-Error "Failed to reserve auto-allocated IP ${ipName}: $($_.Exception.Message)"
    }
}

Write-Host "Auto-allocated IP address reservation process complete."

function ListIPs {
   <#  param (
        OptionalParameters
    ) #>
    # Define your GCP project and region
    Write-Host "Listing reserved internal IP addresses in $region for project $projectId..."

    try {
        gcloud compute addresses list `
           --regions=$region `
           --filter="addressType=INTERNAL" `
           --project=$projectId | Out-Host
    }
    catch {
        Write-Error "Failed to list IP addresses: $($_.Exception.Message)"
    }

    Write-Host "Finished listing internal IP addresses."
    }