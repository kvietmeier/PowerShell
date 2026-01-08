# region: Global Parameters (can be passed as arguments to functions)
$global:projectId  = "clouddev-itdesk124"          # GCP Project ID
$global:region     = "us-west2"                      # GCP Region
$global:subnetName = "subnet-hub-us-west2-voc1"   # GCP Subnet Name
# endregion


<#
.SYNOPSIS
    Reserves a specified number of auto-allocated internal IP addresses in a GCP subnet.

.DESCRIPTION
    This function iterates and calls 'gcloud compute addresses create' to reserve
    a batch of internal IP addresses within the specified GCP subnet. The IP
    addresses are automatically chosen by GCP.

.PARAMETER NumberOfIps
    The quantity of internal IP addresses to reserve.

.PARAMETER ProjectId
    (Optional) The GCP project ID. Defaults to the global $projectId if not provided.

.PARAMETER Region
    (Optional) The GCP region where the subnet is located. Defaults to the global $region.

.PARAMETER SubnetName
    (Optional) The name of the subnet from which to reserve IPs. Defaults to the global $subnetName.

.NOTES
    Requires the 'gcloud' CLI to be installed and authenticated.
    Ensures the subnet exists in the specified region and project.
#>
function ReserveGcpAutoAllocatedIps {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]$NumberOfIps,

        [string]$ProjectId = $global:projectId,
        [string]$Region = $global:region,
        [string]$SubnetName = $global:subnetName
    )

    Write-Host "Starting reservation of $($NumberOfIps) auto-allocated internal IP addresses..."

    for ($i = 1; $i -le $NumberOfIps; $i++) {
        $ipName = "auto-reserved-ip-$i"
        $description = "Auto-allocated internal IP for batch reservation #$i"

        Write-Host "Attempting to reserve auto-allocated IP (Name: $ipName)"

        try {
            gcloud compute addresses create $ipName `
                --region=$Region `
                --subnet=$SubnetName `
                --project=$ProjectId `
                --description="$description" `
                --quiet # --quiet prevents interactive prompts

            Write-Host "Successfully reserved auto-allocated IP with name: ${ipName}"
        }
        catch {
            Write-Error "Failed to reserve auto-allocated IP ${ipName}: $($_.Exception.Message)"
        }
    }

    Write-Host "Auto-allocated IP address reservation process complete."
}

<#
.SYNOPSIS
    Lists all reserved internal IP addresses in a specified GCP region and project.

.DESCRIPTION
    This function executes 'gcloud compute addresses list' to retrieve and display
    details of all internal IP addresses that have been reserved in the given GCP
    region and project.

.PARAMETER ProjectId
    (Optional) The GCP project ID. Defaults to the global $projectId if not provided.

.PARAMETER Region
    (Optional) The GCP region to search for IPs. Defaults to the global $region.

.NOTES
    Requires the 'gcloud' CLI to be installed and authenticated.
#>
function ListGcpInternalIps {
    [CmdletBinding()]
    param (
        [string]$ProjectId = $global:projectId,
        [string]$Region = $global:region
    )

    Write-Host "Listing reserved internal IP addresses in $Region for project $ProjectId..."

    try {
        gcloud compute addresses list `
           --regions=$Region `
           --filter="addressType=INTERNAL" `
           --project=$ProjectId | Out-Host
    }
    catch {
        Write-Error "Failed to list IP addresses: $($_.Exception.Message)"
    }

    Write-Host "Finished listing internal IP addresses."
}

<#
.SYNOPSIS
    Deletes auto-allocated internal IP addresses created by a previous script.

.DESCRIPTION
    This function targets and deletes internal IP address resources based on
    a sequential naming convention (e.g., 'auto-reserved-ip-1', 'auto-reserved-ip-2').

.PARAMETER NumberOfIpsToDelete
    The total number of IP addresses to attempt to delete, starting from 1.
    This should match the number of IPs reserved previously.

.PARAMETER ProjectId
    (Optional) The GCP project ID. Defaults to the global $projectId if not provided.

.PARAMETER Region
    (Optional) The GCP region where the IPs are located. Defaults to the global $region.

.NOTES
    Requires the 'gcloud' CLI to be installed and authenticated.
    Assumes IP names follow the 'auto-reserved-ip-$i' pattern.
#>
function RemoveGcpAutoAllocatedIps {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]$NumberOfIpsToDelete,

        [string]$ProjectId = $global:projectId,
        [string]$Region = $global:region
    )

    Write-Host "Starting unreservation of $($NumberOfIpsToDelete) auto-allocated internal IP addresses..."

    for ($i = 1; $i -le $NumberOfIpsToDelete; $i++) {
        $ipName = "auto-reserved-ip-$i"

        Write-Host "Attempting to delete IP: '$ipName'"

        try {
            gcloud compute addresses delete $ipName `
                --region=$Region `
                --project=$ProjectId `
                --quiet # --quiet prevents interactive prompts for confirmation

            Write-Host "Successfully deleted IP: '$ipName'."
        }
        catch {
            Write-Error "Failed to delete IP '$ipName': $($_.Exception.Message)"
        }
    }

    Write-Host "Auto-allocated IP address unreservation process complete."
}


## Main Script Execution

#  This block demonstrates how to use the functions. You can uncomment and modify the function calls as needed.

# --- Define the number of IPs for reservation/deletion ---
$ipsToManage = 10 # This number should match the batch size for reservation and deletion

# --- Uncomment the function calls you want to execute ---
# 1. Reserve auto-allocated IPs
Write-Host "--- Reserving IPs ---"
ReserveGcpAutoAllocatedIps -NumberOfIps $ipsToManage

# 2. List all internal IPs (useful for verification)
Write-Host "`n--- Listing IPs ---"
ListGcpInternalIps
# 3. Delete auto-allocated IPs (use with caution!)
<# 
Write-Host "`n--- Deleting IPs ---"
RemoveGcpAutoAllocatedIps -NumberOfIpsToDelete $ipsToManage
#>