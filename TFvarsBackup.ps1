#=======================================================================================
# Script Name : Backup-Tfvars.ps1
# Description : Backs up all .tfvars files from multiple Terraform repos
#               into a OneDrive-backed local folder, preserving structure.
#=======================================================================================

param (
    [string[]]$RepoRoots,
    [string]$BackupRoot,
    [switch]$ZipBackup
)

# -----------------------------
# Default repo roots
# -----------------------------
if (-not $RepoRoots) {

    $UserProfile = [Environment]::GetFolderPath("UserProfile")
    $ReposBase   = Join-Path $UserProfile "repos"

    $RepoRoots = @(
        (Join-Path $ReposBase "Terraform"),
        (Join-Path $ReposBase "vastoncloud")
    )
}

# -----------------------------
# Resolve OneDrive backup root
# -----------------------------
if (-not $BackupRoot) {

    $OneDriveRoot = @(
        $env:OneDriveCommercial,
        $env:OneDriveConsumer,
        $env:OneDrive
    ) | Where-Object { $_ } | Select-Object -First 1

    if (-not $OneDriveRoot) {
        throw "OneDrive is not configured or OneDrive environment variables are missing."
    }

    $BackupRoot = Join-Path $OneDriveRoot "Documents\TerraformBackup"
}

# Ensure BackupRoot exists
if (-not (Test-Path $BackupRoot)) {
    New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
}

# Ensure OneDrive folder is fully local
attrib -U +P $BackupRoot /S /D | Out-Null

# Fail fast if cloud-only
$attrs = (Get-Item $BackupRoot).Attributes
if ($attrs -match "Offline") {
    throw "OneDrive backup path exists but is cloud-only. Mark it 'Always keep on this device'."
}

# -----------------------------
# Create timestamped backup dir
# -----------------------------
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupDir = Join-Path $BackupRoot "tfvars-backup-$timestamp"

New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Write-Host "Backup root: $backupDir"

# -----------------------------
# Backup logic
# -----------------------------
$excludedDirs = @(".terraform", ".git")

foreach ($RepoRoot in $RepoRoots) {

    if (-not (Test-Path $RepoRoot)) {
        Write-Warning "Repo path not found, skipping: $RepoRoot"
        continue
    }

    $repoName = Split-Path $RepoRoot -Leaf
    $repoBackupRoot = Join-Path $backupDir $repoName

    Write-Host "`nBacking up repo: $RepoRoot"

    $tfvarsFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.tfvars" -File | Where-Object {
        $fullPath = $_.FullName.ToLower()
        foreach ($excluded in $excludedDirs) {
            if ($fullPath -like "*\$excluded\*") {
                return $false
            }
        }
        return $true
    }

    if (-not $tfvarsFiles) {
        Write-Host "  No .tfvars files found."
        continue
    }

    $repoRootResolved = (Resolve-Path $RepoRoot).Path

    foreach ($file in $tfvarsFiles) {
        $relativePath = $file.FullName.Substring($repoRootResolved.Length + 1)
        $destPath = Join-Path $repoBackupRoot $relativePath
        $destDir  = Split-Path -Parent $destPath

        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path $file.FullName -Destination $destPath -Force

        Write-Host "  Backed up: $repoName\$relativePath"
    }
}

# -----------------------------
# Optional ZIP archive
# -----------------------------
if ($ZipBackup) {
    $zipFile = "$backupDir.zip"
    Compress-Archive -Path $backupDir -DestinationPath $zipFile -Force
    Write-Host "`nCreated zip archive: $zipFile"
}

Write-Host "`nBackup complete."
