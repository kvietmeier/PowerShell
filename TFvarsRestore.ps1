#=======================================================================================
# Script Name : Restore-Tfvars.ps1
# Description : Restores .tfvars files from OneDrive backup into a Terraform repo.
#               Only restores files that do not already exist.
# Parameters  :
#   -RepoRoot   : Root path of the Terraform repo
#   -BackupRoot : Source of backup files (OneDrive)
#=======================================================================================

param (
    [string]$RepoRoot,
    [string]$BackupRoot
)

# ---------------------------
# Resolve default Terraform repo path
# ---------------------------
if (-not $RepoRoot) {
    $RepoRoot = Join-Path $env:USERPROFILE "repos\Terraform"
}

# ---------------------------
# Resolve OneDrive path dynamically
# ---------------------------
if (-not $BackupRoot) {
    $OneDriveRoot = $env:OneDriveCommercial ?? $env:OneDriveConsumer ?? $env:OneDrive

    if (-not $OneDriveRoot) {
        throw "OneDrive is not configured or environment variables are missing."
    }

    $BackupRoot = Join-Path $OneDriveRoot "Documents\TerraformBackup"
}

# ---------------------------
# Find latest backup folder
# ---------------------------
$backupFolders = Get-ChildItem -Path $BackupRoot -Directory |
    Where-Object { $_.Name -like "tfvars-backup-*" } |
    Sort-Object Name -Descending

if ($backupFolders.Count -eq 0) {
    throw "No backup folders found in $BackupRoot"
}

$latestBackup = $backupFolders[0].FullName
Write-Host "Restoring from latest backup: $latestBackup"

# ---------------------------
# Find all .tfvars files in backup
# ---------------------------
$tfvarsFiles = Get-ChildItem -Path $latestBackup -Recurse -Filter "*.tfvars" -File

if ($tfvarsFiles.Count -eq 0) {
    throw "No .tfvars files found in backup folder"
}

# ---------------------------
# Restore files only if missing
# ---------------------------
foreach ($file in $tfvarsFiles) {
    $relativePath = $file.FullName.Substring($latestBackup.Length + 1)
    $destPath = Join-Path $RepoRoot $relativePath
    $destDir = Split-Path -Parent $destPath

    # Skip if file already exists
    if (Test-Path $destPath) {
        Write-Host "Skipped (exists): $relativePath"
        continue
    }

    # Ensure destination directory exists
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null

    # Copy the file
    Copy-Item -Path $file.FullName -Destination $destPath -Force
    Write-Host "Restored: $relativePath"
}

Write-Host "Restore complete."
