# Get Project ID from environment variable
$ProjectID = $env:GOOGLE_PROJECT

# Validate the variable is set
if (-not $ProjectID) {
    Write-Error "Environment variable GCP_PROJECT is not set. Run:`n`$env:GCP_PROJECT = 'your-project-id'"
    exit 1
}

# Use OneDrive project path for output
$OutputDir = "C:\Users\karlv\OneDrive - Vast Data\Projects\VastOnCloudLocal\GCP"
$OutputCSV = Join-Path $OutputDir "GCP_Permissions_$ProjectID.csv"

# Get active authenticated account
$Account = (gcloud auth list --format="value(account)" --filter=status:ACTIVE)

$Roles = gcloud projects get-iam-policy $ProjectID `
  --flatten="bindings[].members" `
  --format="value(bindings.role)" `
  --filter="bindings.members:$Account" | Sort-Object -Unique

# Prepare array for permissions
$PermissionsList = @()

foreach ($Role in $Roles) {
    # Get role details (predefined or custom)
    if ($Role -like "roles/*") {
        $RoleInfo = gcloud iam roles describe $Role --format="json" | ConvertFrom-Json
    } else {
        $RoleInfo = gcloud iam roles describe $Role --project $ProjectID --format="json" | ConvertFrom-Json
    }

    # Add permissions with service extracted
    foreach ($Perm in $RoleInfo.includedPermissions) {
        # Extract service from permission (text before first dot)
        $Service = $Perm.Split('.')[0]

        $PermissionsList += [PSCustomObject]@{
            Account      = $Account
            ProjectID    = $ProjectID
            RoleName     = $Role
            RoleTitle    = $RoleInfo.title
            RoleDesc     = $RoleInfo.description
            Service      = $Service
            Permission   = $Perm
        }
    }
}

# Deduplicate by permission
$PermissionsList = $PermissionsList | Sort-Object Permission -Unique

# Export to CSV
$PermissionsList | Export-Csv -Path $OutputCSV -NoTypeInformation -Encoding UTF8

Write-Host "`nExport complete: $OutputCSV"
