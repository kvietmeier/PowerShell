###===================================================================================###
###  GCP Functions
###===================================================================================###
function GCPAuthADCCreds {
    param (
        [string]$GCPProject = "myproject
    )

    if (-not $env:GOOGLE_APPLICATION_CREDENTIALS) {
        Write-Error "Environment variable GOOGLE_APPLICATION_CREDENTIALS is not set."
        return
    }

    if (-not (Test-Path $env:GOOGLE_APPLICATION_CREDENTIALS)) {
        Write-Error "Credential file not found at '$env:GOOGLE_APPLICATION_CREDENTIALS'"
        return
    }

    Write-Host "Using credentials from: $env:GOOGLE_APPLICATION_CREDENTIALS"

    # Activate the service account using ADC
    try {
        & gcloud auth activate-service-account --key-file="$env:GOOGLE_APPLICATION_CREDENTIALS" | Out-Null
        Write-Host "Service account activated."
    } catch {
        Write-Error "Failed to activate service account. $_"
        return
    }

    # Set ADC and validate
    try {
        $null = & gcloud auth application-default print-access-token
        Write-Host "Application Default Credentials validated. Access token retrieved."
    } catch {
        Write-Error "Failed to retrieve ADC access token. $_"
        return
    }

    # Set the GCP project
    try {
        & gcloud config set project $GCPProject | Out-Null
        Write-Host "GCP project set to: $GCPProject"
    } catch {
        Write-Error "Failed to set GCP project '$GCPProject'. $_"
        return
    }
}


function GCPADCAuth {
    gcloud auth login --update-adc
}

function GCPAuthenticate {
    if (-not $env:GOOGLE_APPLICATION_CREDENTIALS) {
        Write-Error "GOOGLE_APPLICATION_CREDENTIALS is not set."
        return
    }

    gcloud auth activate-service-account --key-file="$env:GOOGLE_APPLICATION_CREDENTIALS"
}

# Set the active Google Cloud account
function GCPSetAcct {
    gcloud config set account karl.vietmeier@vastdata.com
}

# Get the current active Google Cloud project
function GCPGetProject {
    $CurrentProject = gcloud info --format="value(config.project)"
    Write-Host "The current active project is:  $CurrentProject"
}

# Get the current core Google Cloud account
function GCPGetCoreAcct {
    $CoreAccount = gcloud config list account --format "value(core.account)"
    Write-Host "The current core account is:  $CoreAccount"
}
Set-Alias gcpuser GCPGetCoreAcct

# Get the Google Cloud application default access token
function GCPGetAccessToken {
    $GCPAccessToken = gcloud auth application-default print-access-token
    Write-Host "Current Access Token: $GCPAccessToken"
}
Set-Alias gcptoken GCPGetAccessToken

###--- One-Liners
# Returns names of GCP routes that are not associated with any next hop
function GCPGetOrphanedRoutes () {
    gcloud compute routes list `
        --filter="NOT (nextHopGateway:* OR nextHopIp:* OR nextHopInstance:* OR nextHopIlb:* OR nextHopVpnTunnel:* OR nextHopPeering:*)" `
        --format="value(name)"
}

function GCPGetOrphanedRoutesCore () {
    gcloud compute routes list `
        --filter="network:karlv-corevpc AND NOT (nextHopGateway:* OR nextHopIp:* OR nextHopInstance:* OR nextHopIlb:* OR nextHopVpnTunnel:* OR nextHopPeering:*)" `
        --format="value(name)"
}

function GCPListSubnets () {
    gcloud compute networks subnets list
}

function GCPListInstances () {
    gcloud compute instances list --format="table(name, status, networkInterfaces[0].accessConfigs[0].natIP, networkInterfaces[0].networkIP, zone)"
}

###--- GCPManageClientVMs
<#
.SYNOPSIS
    Start, stop, or resume a list of Google Cloud VM instances in parallel.

.DESCRIPTION
    This function performs the specified action ('start' or 'stop') on a predefined list of Google Cloud VM instances.
    - Automatically determines the zone of each VM based on its name.
    - Skips VMs that are already in the desired state:
        * RUNNING for 'start' (or 'resume' if currently SUSPENDED)
        * TERMINATED for 'stop'
    - Queues background jobs for VMs that require action, enabling parallel execution.
    - Waits for all jobs to complete and outputs a detailed result for each VM.
    - Handles errors gracefully when a VM cannot be found or gcloud commands fail.

.PARAMETER Action
    The operation to perform on each VM. Allowed values: 'start', 'stop'.

.PARAMETER Count
    Optional. Limits how many VMs from the predefined list should be processed.
    Default is 0 (process all VMs).

.NOTES
    - The function automatically resolves the correct zone for each VM.
    - For 'start' action:
        * TERMINATED VMs will be started.
        * SUSPENDED VMs will be resumed automatically.
    - For 'stop' action:
        * RUNNING or SUSPENDED VMs will be stopped.
    - Uses PowerShell background jobs to perform multiple actions concurrently for efficiency.
    - Provides clear console output for skipped VMs, queued actions, and results.

.EXAMPLE
    GCPManageClientVMs start
    # Starts all VMs in the list, resuming any that are suspended.

.EXAMPLE
    GCPManageClientVMs stop 5
    # Stops the first 5 VMs in the list.

#>

function GCPManageClientVMs {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("start","stop")]
        [string]$Action,

        [Parameter(Position = 1)]
        [int]$Count = 0  # 0 = all
    )

    # Define your list of VMs
    $instances = @(
        "client01","client02","client03","client04","client05",
        "client06","client07","client08","client09","client10","client11"
    )

    if ($Count -gt 0) {
        $instances = $instances[0..([math]::Min($Count, $instances.Count)-1)]
    }

    $jobs = @()

    foreach ($vm in $instances) {
        # Determine VM zone dynamically
        # Determine VM zone dynamically
        try {
            $zoneRaw = & gcloud compute instances list --filter="name=$vm" --format="value(zone)"
            if (-not $zoneRaw) {
                Write-Host "Error: Could not determine zone for ${vm}" -ForegroundColor Red
                continue
            }

        # Take first line and split
        $Zone = $zoneRaw.Trim() -split '/' | Select-Object -Last 1

        } catch {
            Write-Host "Error querying zone for ${vm}: $_" -ForegroundColor Red
            continue
    }

        # Get VM current status
        $status = (gcloud compute instances describe $vm --zone $Zone --format="get(status)") -replace "`n",""

        if (-not $status) {
            Write-Host "Error: Unable to get status for ${vm}" -ForegroundColor Red
            continue
        }

        # Decide which action is needed
        $cmd = $null
        switch ($Action) {
            "start" {
                switch ($status) {
                    "TERMINATED" { $cmd = "start" }
                    "SUSPENDED"  { $cmd = "resume" }
                    "RUNNING"    { $cmd = $null }
                }
            }
            "stop" {
                switch ($status) {
                    "RUNNING"    { $cmd = "stop" }
                    "SUSPENDED"  { $cmd = $null } 
                    "TERMINATED" { $cmd = $null }
                }
            }
        }

        if ($cmd) {
            Write-Host "Queuing ${cmd} for ${vm} (current status: $status)" -ForegroundColor Yellow
            $jobs += Start-Job -Name $vm -ScriptBlock {
                param($vmName, $zoneName, $action)
                try {
                    & gcloud compute instances $action $vmName --zone $zoneName 2>&1
                } catch {
                    "Error: $_"
                }
            } -ArgumentList $vm, $Zone, $cmd
        } else {
            Write-Host "${vm} is already in desired state ($status), skipping." -ForegroundColor Green
        }
    }

    # Process all background jobs
    if ($jobs.Count -gt 0) {
        Write-Host "`nWaiting for all operations to complete..." -ForegroundColor Cyan
        $jobs | Wait-Job | Out-Null

        foreach ($job in $jobs) {
            $vmName = $job.Name
            $result = Receive-Job -Job $job

            # Clean output
            if ($result -match 'Resuming instance|Updated') {
                Write-Host "Result for ${vmName}: Resumed successfully." -ForegroundColor Green
            } elseif ($result -match 'started') {
                Write-Host "Result for ${vmName}: Started successfully." -ForegroundColor Green
            } elseif ($result -match 'stopped') {
                Write-Host "Result for ${vmName}: Stopped successfully." -ForegroundColor Green
            } else {
                Write-Host "Result for ${vmName}: $result" -ForegroundColor Yellow
            }

            Remove-Job -Job $job
        }
    } else {
        Write-Host "No VMs required action." -ForegroundColor Green
    }
}

Set-Alias gcpclients GCPManageClientVMs



###===================================================================================###
##   Terrfaorm - Update the ingress_rules for GCP FireWall.
###===================================================================================###

# Path to your GCP Firewall Rules tfvars file
$filePath = "C:\Users\karl.vietmeier\repos\Terraform\gcp\CoreInfra\firewalls\my_rules\fw.terraform.tfvars"

###===================================================================================###
# --- Replace IP on line tagged with "# MobileIP"
###===================================================================================###
<#
.SYNOPSIS
Replaces the IP address on the line tagged with "# MobileIP" in a Terraform .tfvars file,
but only if the provided value is a valid IPv4 address.

.DESCRIPTION
- Validates the input to ensure it is a well-formed IPv4 address with octets in the range 0–255.
- If the input is not a valid IPv4 address, the script exits without making any changes.
- Searches for the line in the tfvars file that ends with the comment "# MobileIP".
- Replaces only the quoted IP address portion of that line, preserving the surrounding formatting and comment.
- Writes the updated content back to the original file.

.PARAMETER NewIP
A string representing a valid IPv4 address (e.g., "192.168.1.100") to replace the current MobileIP value.

.EXAMPLE
GCPIngressRule-Update -NewIP "192.168.88.88"

If “192.168.88.88” is valid, finds a line like:
    "10.0.0.5",    # MobileIP

And updates it to:
    "192.168.88.88",    # MobileIP

.NOTES
- The script expects a variable `$filePath` to be defined and point to your target Terraform .tfvars file.
- The function will write: "Invalid IP address. No changes made." if the input does not meet the IPv4 criteria.
#>

function GCPMobileIPUpdate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$NewIP
    )
    
    # Validate IP format using regex and octet check
    if ($NewIP -notmatch '^(\d{1,3}\.){3}\d{1,3}$' -or ($NewIP.Split('.') | Where-Object { [int]$_ -gt 255 }).Count -gt 0) {
        Write-Host "Invalid IP address. No changes made."
        return
    }

    $lines = Get-Content -Path $filePath

    $updatedLines = $lines | ForEach-Object {
        if ($_ -match '^\s*"([^"]+)",?\s*#\s*MobileIP') {
            $_ -replace '"[^"]+"', "`"$NewIP`""
        } else {
            $_
        }
    }

    Set-Content -Path $filePath -Value $updatedLines -Encoding UTF8
    Write-Host "Replaced MobileIP entry with: $NewIP"
}


###===================================================================================###
##    Appends a new IP address to the ingress_filter list in a Terraform .tfvars file.
###===================================================================================###
<#
.SYNOPSIS
Appends a valid IPv4 address to the ingress_filter list in a Terraform .tfvars file.

.DESCRIPTION
- Validates that the input is a well-formed IPv4 address.
- Ensures the last existing entry ends with a comma.
- Inserts the new IP (with a comment) just before the closing bracket `]` of the ingress_filter block.

.PARAMETER NewIP
The new IPv4 address to append to the ingress_filter list.

.PARAMETER Comment
An optional comment to add beside the IP (default: "Added by script").

.EXAMPLE
Add-GCPIngressRule --NewIP "10.10.10.10"

Appends:
  "10.10.10.10"    # Added by script

.EXAMPLE
Add-GCPIngressRule --NewIP "172.16.0.1" --Comment "MobileIP"

Appends:
  "172.16.0.1"    # MobileIP

.NOTES
- The `$filePath` variable must point to the correct .tfvars file.
- Will not update the file if the IP is invalid or missing.
#>
function GCPAddIngressRule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$NewIP,

        [string]$Comment = "Added by script"
    )

    # Validate IP address format
    if (-not ($NewIP -match '^(\d{1,3}\.){3}\d{1,3}$') -or (($NewIP -split '\.') | Where-Object { [int]$_ -gt 255 })) {
        Write-Host "Invalid or missing IP address. No changes made."
        return
    }

    $lines = Get-Content -Path $filePath
    $trimmedLines = $lines | ForEach-Object { $_.Trim() }

    # Find index of closing bracket for ingress_filter array
    $endIndex = $trimmedLines | Select-String '^\]' | Select-Object -First 1

    if ($endIndex) {
        $closingBracketLine = $endIndex.LineNumber - 1
        $lineBeforeClosing = $closingBracketLine - 1

        # Ensure the previous line ends with a comma
        $prevLine = $lines[$lineBeforeClosing]
        if ($prevLine -notmatch '",\s*(#.*)?$') {
            if ($prevLine -match '(")(\s*)(#.*)?$') {
                $lines[$lineBeforeClosing] = $prevLine -replace '(")(\s*)(#.*)?$', '$1,$2$3'
            } else {
                $lines[$lineBeforeClosing] += ","
            }
        }

        # Create new line to insert
        $newLine = "  `"$NewIP`"    # $Comment"

        # Insert before closing bracket
        $lines = $lines[0..($lineBeforeClosing)] + $newLine + $lines[$closingBracketLine..($lines.Count - 1)]

        # Save changes
        Set-Content -Path $filePath -Value $lines -Encoding UTF8
        Write-Host "Added IP: $NewIP with comment: # $Comment"
    } else {
        Write-Host "Could not find end of ingress_filter array."
    }
}

<#
function GCPTerraformApply {
    if (-not (Test-Path $filePath)) {
        Write-Host "File path does not exist: $filePath"
        return
    }

    $terraformDir = Split-Path -Path $filePath -Parent

    Write-Host "Running 'terraform apply' in: $terraformDir"

    Push-Location $terraformDir
    try {
        terraform apply -auto-approve
    } catch {
        Write-Host "Terraform apply failed: $_"
    } finally {
        Pop-Location
    }
}
#>
# Define a function that runs terraform apply using your specific .tfvars file
function GCPApplyFirewall {
    # Apply updates to firewall rules
    $filePath = "C:\Users\karl.vietmeier\repos\Terraform\gcp\CoreInfra\firewalls\my_rules\fw.terraform.tfvars"

    if (-Not (Test-Path $filePath)) {
        Write-Host "Error: File not found at path '$filePath'"
        return
    }

    $tfVarsAbsolute = (Resolve-Path $filePath).Path
    $tfDir  = Split-Path $tfVarsAbsolute -Parent
    $tfFile = Split-Path $tfVarsAbsolute -Leaf

    Push-Location $tfDir

    try {
        Write-Host "Running: terraform apply -var-file=$tfFile"
        terraform apply "-var-file=$tfFile"
    } catch {
        Write-Host "Error during terraform apply: $_"
    } finally {
        Pop-Location
    }
}


###===================================================================================###
##    IAM Checking
###===================================================================================###


function GCPGetIAMPendingDeletionRoles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [switch]$ForceUndelete
    )

    Write-Host ""
    Write-Host "Checking for custom roles in PENDING_DELETION state in project '$ProjectId'..."

    $json = & gcloud iam roles list `
        --project $ProjectId `
        --show-deleted `
        --format=json

    if ($LASTEXITCODE -ne 0 -or -not $json) {
        Write-Error "Failed to retrieve roles from GCP."
        return
    }

    $roles = $json | ConvertFrom-Json
    $pendingRoles = $roles | Where-Object { $_.deleted -eq $true }

    if (-not $pendingRoles) {
        Write-Host "No roles in PENDING_DELETION state."
        return
    }

    Write-Host ""
    Write-Host "Roles in PENDING_DELETION state:"
    Write-Host "---------------------------------"
    foreach ($role in $pendingRoles) {
        Write-Host "* Role ID: $($role.name)"
        Write-Host "  Title  : $($role.title)"
        Write-Host "  Stage  : $($role.stage)"
        Write-Host ""
    }

    if ($ForceUndelete) {
        Write-Host "Starting undelete operations..."
        foreach ($role in $pendingRoles) {
            Write-Host "Undeleting $($role.name)..."
            & gcloud iam roles undelete $role.name --project=$ProjectId
        }
        Write-Host "Undelete operations complete."
    }
}


function GCPGetIAMCustomRolesByRange {
    param (
        [string]$ProjectId
    )

    $projectRanges = 1..10

    foreach ($range in $projectRanges) {
        $gcpProject = "gcp" + $range
        Write-Host "Checking roles for project: $gcpProject"
        
        # Fetch roles for the specific project (replace with actual GCP command to get roles)
        $roles = Get-GcpIamCustomRoles -ProjectId $ProjectId -Region $gcpProject

        Write-Host "Fetched roles for $gcpProject $($roles.Count) roles found."
        
        if ($roles.Count -eq 0) {
            Write-Host "[$gcpProject] No roles found."
        } else {
            Write-Host "[$gcpProject] Matching Roles:"
            Write-Host "-----------------------------"
            foreach ($role in $roles) {
                $status = if ($role.deleted) { "DELETED" } else { "ACTIVE" }
                Write-Host "* $($role.name) - $($role.title) [$status]"
            }
        }

        Write-Host ""
    }
}