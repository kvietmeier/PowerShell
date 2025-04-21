# Replace with your actual Project ID
$ProjectId = "clouddev-itdesk124"

# List of regions you want to check
$Regions = @(
    "us-west1",
    "us-west2",
    "us-central1",
    "us-east1",
    "us-east4"
)

foreach ($Region in $Regions) {
    Write-Host "`nChecking region: $Region..."

    # Execute the gcloud command and capture the output as a single string
    $gcloudOutput = & gcloud compute regions describe $Region --project $ProjectId --format json | Out-String

    # Check if there was any output from the gcloud command
    if (-not [string]::IsNullOrEmpty($gcloudOutput)) {
        try {
            # Convert the JSON string to a PowerShell object
            $jsonOutput = ConvertFrom-Json $gcloudOutput

            # Find the Local SSD per VM quota in the list of quotas
            $localSSDQuota = $jsonOutput.quotas | Where-Object { $_.metric -eq "LOCAL_SSD_TOTAL_GB" }

            # Output the quota limit if found
            if ($localSSDQuota) {
                Write-Host "Local SSD per VM Quota in ${Region} for project ${ProjectId}: $($localSSDQuota.limit)"
            } else {
                Write-Host "LOCAL_SSD_TOTAL_GB quota not found in ${Region}."
            }
        } catch {
            Write-Error "Failed to parse JSON for ${Region}: $($_.Exception.Message)"
            Write-Host "Raw gcloud output for debugging:"
            Write-Host $gcloudOutput
        }
    } else {
        Write-Host "Error: No output received from gcloud command for region ${Region}."
    }
}
