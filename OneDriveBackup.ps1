<#
.SYNOPSIS
    OneDrive Backup & Full Hydration Utility (Phase 1)
    Developed by: Karl Vietmeier | KCV Consulting

.DESCRIPTION
    This script performs a verified, non-destructive backup of a OneDrive tenant. 
    It is specifically designed for Tenant-to-Tenant migrations where "Cloud-Only" 
    files must be physically downloaded (hydrated) before the old account is closed.

.USAGE
    1. Connect an external drive (W:) with sufficient free space.
    2. Run the script in a PowerShell terminal (VS Code recommended).
    3. Follow the on-screen prompts to select your Source and Target.

.SAFETY GUARANTEES
    - READ-ONLY SOURCE: The script never moves, deletes, or modifies original files.
    - INTEGRITY CHECK: Uses SHA256 Hashing to verify the copy is bit-perfect.
    - HYDRATION: Automatically triggers Windows to download cloud-only stubs.

.TECHNICAL LOGIC
    - PROCESS CHECK: Detects apps (Outlook/Office) that may lock files.
    - DYNAMIC DISCOVERY: Automatically finds all OneDrive tenants in the User Profile.
    - PRE-FLIGHT ANALYSIS: Compares Source Size vs. Target Free Space before starting.
    - PERSISTENT LOGGING: Every action is logged; errors are captured in 'backup_errors.log'.

.MONITORING TIP
    If the script appears to pause on large files (Videos/Captures), do not exit.
    Check 'Task Manager > Performance' to verify active Network and Disk throughput.
    Large files require time to download from the cloud before they can be copied.

.LICENSE
    Copyright 2026 Karl Vietmeier, KCV Consulting
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    http://www.apache.org/licenses/LICENSE-2.0
#>

# ==============================================================================
# ONEDRIVE BACKUP UTILITY 
# ==============================================================================

Clear-Host
Write-Host "--- ONEDRIVE BACKUP UTILITY ---" -ForegroundColor Yellow
Write-Host "SAFE TO RUN: Read-only source. SHA256 Verification enabled." -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------"

# --- STEP 1: PROCESS CHECK ---
$appsToMatch = @("Outlook", "WinWord", "Excel", "Powerpnt", "OneNote", "Snagit", "Acrobat", "msedge", "chrome", "opera", "ms-teams", "slack", "Code", "Code - Insiders")
while ($true) {
  $runningApps = Get-Process | Where-Object { $appsToMatch -contains $_.ProcessName }
  if ($runningApps) {
    Write-Host "WARNING: Apps running that may lock files:" -ForegroundColor Yellow
    $runningApps | Select-Object -Unique ProcessName | ForEach-Object { Write-Host " - $($_.ProcessName)" }
    $choice = Read-Host -Prompt "[C] Continue | [E] Exit | [Enter] Re-scan"
    if ($choice.ToUpper() -eq "E") { exit }
    if ($choice.ToUpper() -eq "C") { break }
  }
  else { break }
}

# --- STEP 2: SOURCE SELECTION ---
Write-Host "`nSELECT ONEDRIVE SOURCE:" -ForegroundColor Cyan
$sources = Get-ChildItem -Path $env:USERPROFILE -Directory -Filter "OneDrive*" | Select-Object -ExpandProperty FullName | Sort-Object
for ($i = 0; $i -lt $sources.Count; $i++) { Write-Host "[$($i+1)] $($sources[$i])" }
$srcChoice = Read-Host -Prompt "Enter Number (or 'E')"
if ($srcChoice.ToUpper() -eq "E") { exit }
$oneDrivePath = $sources[$srcChoice - 1]
$folderName = Split-Path $oneDrivePath -Leaf
$tenantName = if ($folderName -like "* - *") { $folderName.Split("-")[1].Trim() } else { "Personal" }

# --- STEP 3: TARGET DRIVE SELECTION ---
Write-Host "`nSELECT TARGET DRIVE (Min 500GB recommended):" -ForegroundColor Cyan
$driveList = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
for ($i = 0; $i -lt $driveList.Count; $i++) {
  $freeGB = [math]::Round($driveList[$i].Free / 1GB, 2)
  # FIXED LINE 70: Simplified color logic to prevent 'if' cmdlet error
  $color = "White"
  if ($freeGB -lt 500) { $color = "Red" }
  Write-Host "[$($i+1)] $($driveList[$i].Name): [$freeGB GB Free]" -ForegroundColor $color
}
$driveChoice = Read-Host -Prompt "Enter Number (or 'E')"
if ($driveChoice.ToUpper() -eq "E") { exit }
$targetDriveObj = $driveList[$driveChoice - 1]
$targetPath = Join-Path -Path "$($targetDriveObj.Name):\" -ChildPath "OneDrive_Backup\$($tenantName)_$(Get-Date -Format 'yyyyMMdd_HHmm')"
$logFile = Join-Path -Path $targetPath -ChildPath "backup_errors.log"

# --- STEP 4: ANALYSIS & PERFORMANCE TIP ---
Write-Host "`nScanning $oneDrivePath..." -ForegroundColor Yellow
$items = Get-ChildItem -Path $oneDrivePath -Recurse
$fileItems = $items | Where-Object { -not $_.PSIsContainer }
$totalSizeGB = [math]::Round(($fileItems | Measure-Object -Property Length -Sum).Sum / 1GB, 2)

Write-Host "--------------------------------------------------------"
Write-Host "SOURCE SIZE: $totalSizeGB GB"
Write-Host "TARGET FREE: $([math]::Round($targetDriveObj.Free/1GB,2)) GB"
Write-Host "DESTINATION: $targetPath"
Write-Host "--------------------------------------------------------"
Write-Host "TIP: If the script 'hangs' on large files (Videos/Captures)," -ForegroundColor Gray
Write-Host "check Task Manager > Performance to verify Network/Disk activity." -ForegroundColor Gray
Write-Host "--------------------------------------------------------"

if ($targetDriveObj.Free / 1GB -lt $totalSizeGB) { Write-Host "ERROR: No space!" -ForegroundColor Red; exit }
if ((Read-Host -Prompt "Proceed with Backup? [Y/N]").ToUpper() -ne "Y") { exit }

# --- STEP 5: EXECUTION ---
if (-not (Test-Path $targetPath)) { New-Item -ItemType Directory -Path $targetPath -Force | Out-Null }
$stats = @{ Success = 0; Failed = 0 }
Write-Host "`nStarting Backup..." -ForegroundColor Cyan

foreach ($item in $items) {
  $relative = $item.FullName.Substring($oneDrivePath.Length).TrimStart('\')
  $dest = Join-Path -Path $targetPath -ChildPath $relative
  if ($item.PSIsContainer) { if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }; continue }
    
  $displayPath = if ($relative.Length -gt 85) { "..." + $relative.Substring($relative.Length - 82) } else { $relative }
    
  try {
    # Force Hydration
    $stream = [System.IO.File]::OpenRead($item.FullName); $stream.Close() 
    Copy-Item -Path $item.FullName -Destination $dest -Force -ErrorAction Stop
    if ((Get-FileHash $item.FullName).Hash -eq (Get-FileHash $dest).Hash) {
      Write-Host "[OK]   $displayPath" -ForegroundColor Green; $stats.Success++
    }
    else { throw "Hash Failure" }
  }
  catch {
    Write-Host "[FAIL] $displayPath" -ForegroundColor Red
    "$($item.FullName) | Error: $($_.Exception.Message)" | Out-File $logFile -Append; $stats.Failed++
  }
}
Write-Host "`n--- COMPLETED ---" -ForegroundColor Yellow
Write-Host "Success: $($stats.Success) | Failed: $($stats.Failed)"
