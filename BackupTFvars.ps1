#=======================================================================================
# Script Name : Backup-Tfvars.ps1
# Description : Backs up all .tfvars files from a Terraform repo, excluding certain folders
# Parameters  :
#   -RepoRoot   : Root path of the Terraform repo
#   -BackupRoot : Destination for backups
#   -ZipBackup  : Optional switch to compress the backup folder into a ZIP
#=======================================================================================

param (
    [string]$RepoRoot,
    [string]$BackupRoot,
    [switch]$ZipBackup
)

# Set default paths if none provided
if (-not $RepoRoot) {
    $RepoRoot = Join-Path $env:USERPROFILE "repos\Terraform"
}

if (-not $BackupRoot) {
    $BackupRoot = "C:\Users\karl.vietmeier\OneDrive - KCV Consulting\Documents\TerraformBackup"
}

# Create a timestamped backup directory
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupDir = Join-Path $BackupRoot "tfvars-backup-$timestamp"

Write-Host "Backing up .tfvars files from: $RepoRoot"
Write-Host "Backup destination: $backupDir"

# Define folders to exclude during backup
$excludedDirs = @(".terraform", ".git")

# Find all .tfvars files recursively, skipping excluded folders
$tfvarsFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.tfvars" -File | Where-Object {
    $fullPath = $_.FullName.ToLower()
    foreach ($excluded in $excludedDirs) {
        if ($fullPath -like "*\$excluded\*") {
            return $false
        }
    }
    return $true
}

# Stop if no files were found
if ($tfvarsFiles.Count -eq 0) {
    Write-Host "No .tfvars files found (outside excluded folders)."
    return
}

# Create the backup directory
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

# Copy each .tfvars file, preserving directory structure
foreach ($file in $tfvarsFiles) {
    $relativePath = $file.FullName.Substring((Resolve-Path $RepoRoot).Path.Length + 1)
    $destPath = Join-Path $backupDir $relativePath
    $destDir = Split-Path -Parent $destPath

    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    Copy-Item -Path $file.FullName -Destination $destPath
    Write-Host "Backed up: $relativePath"
}

# Optional: Create a ZIP archive of the backup
if ($ZipBackup) {
    $zipFile = "$backupDir.zip"
    Compress-Archive -Path $backupDir -DestinationPath $zipFile -Force
    Write-Host "Created zip archive: $zipFile"
}

Write-Host "Backup complete."
