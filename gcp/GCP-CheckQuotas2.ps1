# Define regions you want to check
$regions = @(
    #"us-central1", "us-east1", "us-east4", "us-west1"
    "us-west1"
    #"europe-west1", "europe-west2", "europe-west4",
    #"asia-east1", "asia-northeast1", "asia-southeast1"
)

$quotaResults = @()

foreach ($region in $regions) {
    Write-Host "Checking region: $region..." -ForegroundColor Cyan
    $output = gcloud compute regions describe $region --format=json | ConvertFrom-Json

    foreach ($quota in $output.quotas) {
        if ($quota.metric -match "CPUS" -or $quota.metric -match "LOCAL_SSD_TOTAL_GB") {
            $quotaResults += [pscustomobject]@{
                Region = $region
                Metric = $quota.metric
                Limit  = $quota.limit
                Usage  = $quota.usage
                Remaining = [math]::Round($quota.limit - $quota.usage, 2)
            }
        }
    }
}

# Display results in a table
$quotaResults | Sort-Object Region, Metric | Format-Table -AutoSize
