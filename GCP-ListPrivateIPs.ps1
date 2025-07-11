<#
.SYNOPSIS
    Lists all reserved INTERNAL IP addresses in the current GCP project.

.DESCRIPTION
    Uses the `gcloud` CLI to retrieve all INTERNAL type reserved IPs across regions.
    Extracts key fields like:
        - Reservation resource name
        - Actual attached VM (from `.users`)
        - Subnet, Region, Purpose, Status

.NOTES
    Author: Karl Vietmeier
    Date:   2025-07-09
    Requires: Google Cloud SDK (gcloud), PowerShell 5.1+

.EXAMPLE
    .\List-GCPInternalIPs.ps1

    Displays a formatted table of reserved internal IP addresses in the current GCP project.
#>

# Get internal addresses from gcloud
$internalAddresses = gcloud compute addresses list `
  --filter="addressType=INTERNAL" `
  --format="json" | ConvertFrom-Json

Write-Host ""
Write-Host "==================== Reserved Internal IP Summary ====================" -ForegroundColor Cyan
Write-Host "Project: $(gcloud config get-value project 2>$null)" -ForegroundColor Gray
Write-Host "Total Reserved Internal IPs: $($internalAddresses.Count)" -ForegroundColor Gray
Write-Host "======================================================================"
Write-Host ""

$internalAddresses | ForEach-Object {
  [PSCustomObject]@{
    ReservationName = $_.name
    Address         = $_.address
    AttachedToVM    = if ($_.users) { ($_.users[0] -split "/")[-1] } else { "Not Attached" }
    Purpose         = $_.purpose
    Network         = if ($_.network) { ($_.network -split "/")[-1] } else { "None" }
    Region          = if ($_.region) { ($_.region -split "/")[-1] } else { "Global" }
    Subnet          = if ($_.subnetwork) { ($_.subnetwork -split "/")[-1] } else { "None" }
    Status          = $_.status
  }
} | Format-Table `
  @{Label="Attached To VM";   Expression={$_.AttachedToVM};    Width=45}, `
  @{Label="Address";          Expression={$_.Address};         Width=15}, `
  @{Label="Purpose";          Expression={$_.Purpose};         Width=15}, `
  @{Label="Network";          Expression={$_.Network};         Width=15}, `
  @{Label="Region";           Expression={$_.Region};          Width=12}, `
  @{Label="Subnet";           Expression={$_.Subnet};          Width=25}, `
  @{Label="Status";           Expression={$_.Status};          Width=12}, `
  @{Label="Reservation Name"; Expression={$_.ReservationName}; Width=65}
