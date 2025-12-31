<#
.SYNOPSIS
  Real-risk Windows 11 privacy audit for stand-alone laptops (signal-only).

.DESCRIPTION
  - Treats missing registry keys as PASS (safe) by default.
  - Flags only actual exposures:
      - Copilot UI visible
      - Clipboard history/cloud sync enabled
      - Recall enabled
      - Delivery Optimization P2P enabled
#>

$ErrorActionPreference = 'SilentlyContinue'
Write-Host "=== Windows 11 Privacy Audit (Real Risk, Simplified) ===`n" -ForegroundColor Cyan

function Get-RegDWORDSafe {
    param([string]$Path, [string]$Name)
    $value = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($null -eq $value) { return "DefaultSafe" } else { return $value }
}

function Test-SettingSafe {
    param([string]$Name, $Value, $Recommended)
    if ($Value -eq $Recommended -or $Value -eq "DefaultSafe") { 
        return @{Setting=$Name;Value=$Value;Status="PASS"} 
    } else { 
        return @{Setting=$Name;Value=$Value;Status="FAIL (Recommended=$Recommended)"} 
    }
}

$results = @()

# Clipboard
$results += Test-SettingSafe "ClipboardHistoryEnabled" (Get-RegDWORDSafe 'HKCU:\SOFTWARE\Microsoft\Clipboard' 'EnableClipboardHistory') 0
$results += Test-SettingSafe "CloudClipboardEnabled" (Get-RegDWORDSafe 'HKCU:\SOFTWARE\Microsoft\Clipboard' 'EnableCloudClipboard') 0

# Copilot
$results += Test-SettingSafe "TurnOffWindowsCopilot" (Get-RegDWORDSafe 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot') 1
$results += Test-SettingSafe "ShowCopilotButton" (Get-RegDWORDSafe 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton') 0

# Recall
try {
    $recallFeature = (Get-WindowsOptionalFeature -Online -FeatureName Recall -ErrorAction SilentlyContinue).State
} catch { $recallFeature = "Disabled" } # Treat missing as safe
$results += Test-SettingSafe "Recall optional feature state" $recallFeature "Disabled"
$results += Test-SettingSafe "AllowRecall policy" (Get-RegDWORDSafe 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'AllowRecall') 0

# Delivery Optimization P2P
$results += Test-SettingSafe "DeliveryOptimization DODownloadMode" (Get-RegDWORDSafe 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode') 0

# ------------------------------------------------------------
# Print color-coded summary
# ------------------------------------------------------------
Write-Host "`n=== Real Risk Privacy Audit Summary (Simplified) ===`n" -ForegroundColor Green

foreach ($r in $results) {
    if ($r.Status -like "PASS") {
        Write-Host ("{0,-35} {1,-15} {2}" -f $r.Setting, $r.Value, $r.Status) -ForegroundColor Green
    } else {
        Write-Host ("{0,-35} {1,-15} {2}" -f $r.Setting, $r.Value, $r.Status) -ForegroundColor Red
    }
}

# Optional: show summary counts
$passCount = ($results | Where-Object {$_.Status -eq "PASS"}).Count
$failCount = ($results | Where-Object {$_.Status -like "FAIL*" }).Count

Write-Host "`nSummary: PASS = $passCount, FAIL = $failCount" -ForegroundColor Cyan
Write-Host "Audit complete. Only actual exposures are shown as FAIL." -ForegroundColor Cyan
