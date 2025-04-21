# Replace with your actual Project ID and Region
$ProjectId = "clouddev-itdesk124"
$Region = "us-west2"

# Execute the gcloud command and capture the output as a single string
$gcloudOutput = & gcloud compute regions describe $Region --project $ProjectId --format json | Out-String

# Check if there was any output from the gcloud command
if (-not [string]::IsNullOrEmpty($gcloudOutput)) {
    # Convert the JSON string to a PowerShell object
    try {
        $jsonOutput = ConvertFrom-Json $gcloudOutput
        # Find the Local SSD per VM quota in the list of quotas
        $localSSDQuota = $jsonOutput.quotas | Where-Object {$_.metric -eq "LOCAL_SSD_TOTAL_GB"}

        # Output the quota limit if found
        if ($localSSDQuota) {
            Write-Host "Local SSD per VM Quota in $($Region) for project $($ProjectId): $($localSSDQuota.limit)"
        } else {
            Write-Host "Local SSD per VM Quota not found in the region description."
        }
    }
    catch {
        Write-Error "Error converting gcloud output to JSON: $($_.Exception.Message)"
        Write-Host "Raw gcloud output for debugging:"
        Write-Host $gcloudOutput
    }
} else {
    Write-Host "Error: No output received from gcloud command."
}