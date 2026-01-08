# region: Define your GCP project and region
$projectId    = "clouddev-itdesk124"           # Name - not number
$region       = "us-west2" # Replace with your desired region

# The number of IPs that were originally reserved in the batch.
# This must match the `$numberOfIpsToReserve` variable from the creation script.
$numberOfIpsToDelete = 20

Write-Host "Starting unreservation of $numberOfIpsToDelete auto-allocated internal IP addresses..."

for ($i = 1; $i -le $numberOfIpsToDelete; $i++) {
    # Reconstruct the name exactly as it was created
    $ipName = "auto-reserved-ip-$i"

    Write-Host "Attempting to delete IP: '$ipName'"

    try {
        gcloud compute addresses delete $ipName `
            --region=$region `
            --project=$projectId `
            --quiet # --quiet prevents interactive prompts for confirmation

        Write-Host "Successfully deleted IP: '$ipName'."
    }
    catch {
        Write-Error "Failed to delete IP '$ipName': $($_.Exception.Message)"
    }
}

Write-Host "Auto-allocated IP address unreservation process complete."