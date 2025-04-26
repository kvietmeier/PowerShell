###===================================================================================###
###  GCP Functions
###===================================================================================###
function GCPAuthUpdateADC {
    # Authenticate with Google Cloud and update ADC
    gcloud auth login --update-adc
}

# Set an alias to easily call the function
Set-Alias gcpauthall GCPAuthUpdateADC

function GCPAuthenticate {
    # Authenticate with Google Cloud using the specified credentials file
    gcloud auth login --brief --cred-file="C:\.info\gcpcomputesa.json"
    
    # Optionally set the account (uncomment if needed)
    # gcloud config set account karl.vietmeier@vastdata.com
}

# Set an alias for easy access to the authentication function
Set-Alias gcplogin GCPAuthenticate

# Set the active Google Cloud account
function GCPSetAcct {
    gcloud config set account karl.vietmeier@vastdata.com
}
Set-Alias gcpacctset GCPSetAcct

# Get the current active Google Cloud project
function GCPGetProject {
    $CurrentProject = gcloud info --format="value(config.project)"
    Write-Host "The current active project is:  $CurrentProject"
}
Set-Alias gcpproject GCPGetProject

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


###===================================================================================###
##   Update the ingress_rules for GCP FireWall.
###===================================================================================###

# Path to your GCP Firewall Rules tfvars file
$filePath = "C:\Users\karl.vietmeier\repos\Terraform\gcp\CoreInfra\firewalls\my_rules\fw.terraform.tfvars"

###===================================================================================###
# --- Replace IP on line tagged with "# MobileIP"
###===================================================================================###
<#
.SYNOPSIS
Replaces the IP address on the line tagged with "# MobileIP" in a Terraform .tfvars file.

.DESCRIPTION
- Searches for a line in the ingress_filter block that ends with a comment "# MobileIP".
- Replaces the IP on that line with a new one, preserving the rest of the line (including the comment).
- Only affects the first line it finds with "# MobileIP".

.PARAMETER NewIP
The new IP address to replace the existing one labeled as "# MobileIP".

.EXAMPLE
Update-GCPIngressRule -NewIP "192.168.88.88"

Replaces the IP address on the line tagged "# MobileIP" with 192.168.88.88.

.NOTES
- Make sure the $filePath variable points to the correct .tfvars file.
- Useful for updating dynamic/mobile IPs like those from hotspots.
#>
function Update-GCPIngressRule {
    param (
        [string]$NewIP
    )

    if (-not $NewIP) {
        Write-Host "No IP provided. Nothing was added."
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
Appends a new IP address to the ingress_filter list in a Terraform .tfvars file.

.DESCRIPTION
- Ensures the previous last IP entry ends with a comma.
- Adds the new IP without a trailing comma.
- Optionally adds a comment next to the new IP.
- Designed to be used with a known file path containing ingress_filter = [ ... ] block.

.PARAMETER NewIP
The new IP address to add to the ingress_filter array.

.PARAMETER Comment
A comment to include on the same line as the new IP (default is 'Added by script').

.EXAMPLE
Add-GCPIngressRule -NewIP "192.168.100.200"

Adds the IP to the end of the ingress_filter list with the default comment.

.EXAMPLE
Add-GCPIngressRule -NewIP "10.1.1.1" -Comment "MobileIP"

Adds the IP to the ingress_filter list with a comment "# MobileIP".

.NOTES
- Make sure the $filePath variable points to the correct .tfvars file.
- Modify the path assignment if needed.
#>
function Add-GCPIngressRule {
    param (
        [string]$NewIP,
        [string]$Comment = "Added by script"
    )

    if (-not $NewIP) {
        Write-Host "No IP provided. Nothing was added."
        return
    }


    $terraformDir = Split-Path -Path $filePath
    $lines = Get-Content -Path $filePath
    $trimmedLines = $lines | ForEach-Object { $_.Trim() }

    $endIndex = $trimmedLines | Select-String '^\]' | Select-Object -First 1

    if ($endIndex) {
        $closingBracketLine = $endIndex.LineNumber - 1
        $lineBeforeClosing = $closingBracketLine - 1

        $prevLine = $lines[$lineBeforeClosing]
        if ($prevLine -notmatch '",\s*(#.*)?$') {
            if ($prevLine -match '(")(\s*)(#.*)?$') {
                $lines[$lineBeforeClosing] = $prevLine -replace '(")(\s*)(#.*)?$', '$1,$2$3'
            } else {
                $lines[$lineBeforeClosing] += ","
            }
        }

        $newLine = "  `"$NewIP`"    # $Comment"
        $lines = $lines[0..$lineBeforeClosing] + $newLine + $lines[$closingBracketLine..($lines.Count - 1)]

        Set-Content -Path $filePath -Value $lines -Encoding UTF8
        Write-Host "✔ Added IP: $NewIP with comment: # $Comment"
    }
    else {
        Write-Error "Could not find end of ingress_filter array."
    }
}
