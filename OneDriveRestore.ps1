<#
.SYNOPSIS
    OneDrive Restore & Rehydration Utility (Phase 2)
    Developed by: Karl Vietmeier | KCV Consulting

.DESCRIPTION
    This script automates the transfer of verified backups into a NEW OneDrive tenant.
    It is designed to be used AFTER the old tenant is unlinked and the new 
    account is signed in. It uses high-speed multi-threading to restore data locally.

.USAGE
    1. Connect the external drive (W:) containing the Phase 1 backup.
    2. Ensure you are signed into the NEW OneDrive tenant.
    3. Run the script and select your "From -> To" paths via the dynamic list.

.PERFORMANCE & SPEED
    - MULTI-THREADED: Uses Robocopy with 16-thread processing (/MT:16).
    - LOGGING: Generates 'Restore_Results.log' in the root of the new OneDrive.
    - ATTRIBUTE PARITY: Maintains file timestamps and data attributes (/COPY:DAT).

.MIGRATION STRATEGY
    - WORKSTATION A (LIVE): Use this script to "push" data into the new cloud.
    - WORKSTATION B (VAULT): Keep this machine OFFLINE during the restore as a 
      fail-safe "Time Capsule" of your data.

.POST-RESTORE ADVICE
    Once the transfer finishes, the OneDrive client will begin the upload phase.
    If internal disk space becomes low, right-click uploaded folders (Green Check)
    and select 'Free up space' to convert them back to cloud placeholders.

.LICENSE
    Copyright 2026 Karl Vietmeier, KCV Consulting
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    http://www.apache.org/licenses/LICENSE-2.0
#>

# ==============================================================================
# ONEDRIVE RESTORE UTILITY
# ==============================================================================

Clear-Host
Write-Host "--- ONEDRIVE RESTORE UTILITY ---" -ForegroundColor Yellow

# --- STEP 1: BACKUP SELECTION ---
# Look for available backup folders on W: (or change drive letter if needed)
$backupRoot = "W:\OneDrive_Backup"

if (-not (Test-Path $backupRoot)) {
  Write-Host "ERROR: Backup root '$backupRoot' not found." -ForegroundColor Red
  Write-Host "Please ensure your backup drive is connected and mapped to W:"
  exit
}

Write-Host "`nSELECT BACKUP SOURCE (Newest first):" -ForegroundColor Cyan
$backupFolders = Get-ChildItem -Path $backupRoot -Directory | Sort-Object LastWriteTime -Descending

if ($backupFolders.Count -eq 0) {
  Write-Host "ERROR: No backup folders found in $backupRoot." -ForegroundColor Red
  exit
}

for ($i = 0; $i -lt $backupFolders.Count; $i++) {
  Write-Host "[$($i+1)] $($backupFolders[$i].Name)"
}

$srcChoice = Read-Host -Prompt "`nEnter Choice (or 'E' to Exit)"
if ($srcChoice.ToUpper() -eq "E") { exit }
if (-not $backupFolders[$srcChoice - 1]) { Write-Host "Invalid Selection."; exit }
$selectedBackupPath = $backupFolders[$srcChoice - 1].FullName

# --- STEP 2: DESTINATION SELECTION ---
Write-Host "`nSELECT DESTINATION (New OneDrive Tenant Folder):" -ForegroundColor Cyan
$userProfile = $env:USERPROFILE
$destinations = Get-ChildItem -Path $userProfile -Directory -Filter "OneDrive*" | Sort-Object Name

if ($destinations.Count -eq 0) {
  Write-Host "ERROR: No active OneDrive folders found in $userProfile." -ForegroundColor Red
  exit
}

for ($i = 0; $i -lt $destinations.Count; $i++) {
  Write-Host "[$($i+1)] $($destinations[$i].FullName)"
}

$destChoice = Read-Host -Prompt "`nEnter Choice (or 'E' to Exit)"
if ($destChoice.ToUpper() -eq "E") { exit }
if (-not $destinations[$destChoice - 1]) { Write-Host "Invalid Selection."; exit }
$targetOneDrivePath = $destinations[$destChoice - 1].FullName

# --- STEP 3: EXECUTION PLAN ---
Write-Host "`n--- RESTORE PLAN ---" -ForegroundColor Yellow
Write-Host "FROM: $selectedBackupPath"
Write-Host "TO:   $targetOneDrivePath"
Write-Host "--------------------------------------------------------"
Write-Host "TIP: This will use multi-threaded Robocopy for speed." -ForegroundColor Gray
Write-Host "--------------------------------------------------------"

$confirm = Read-Host -Prompt "Proceed with Restore? [Y/N]"
if ($confirm.ToUpper() -ne "Y") { exit }

# --- STEP 4: ROBOCOPY EXECUTION ---
$logPath = Join-Path -Path $targetOneDrivePath -ChildPath "Restore_Results.log"

Write-Host "`nRestoring files... monitor 'Restore_Results.log' for details." -ForegroundColor Cyan

# /E       :: Subdirectories (including empty)
# /COPY:DAT :: Data, Attributes, Timestamps
# /MT:16    :: 16 Threads for performance
# /R:3 /W:5 :: Retry 3 times, wait 5 seconds
# /TEE      :: Output to console AND log file
robocopy "$selectedBackupPath" "$targetOneDrivePath" /E /COPY:DAT /MT:16 /R:3 /W:5 /TEE /LOG:"$logPath"

# --- STEP 5: WRAP UP ---
Write-Host "`n--- RESTORE FINISHED ---" -ForegroundColor Yellow
Write-Host "Log file saved to: $logPath"
Write-Host "OneDrive will now begin indexing and uploading these files to the new tenant." -ForegroundColor Gray
