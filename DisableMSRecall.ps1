<#
.SYNOPSIS
  Idempotently disables Windows Recall on Windows 11.

.DESCRIPTION
  - Disables the Recall Windows optional feature
  - Enforces Recall disabled via policy (registry)
  - Removes any existing Recall snapshot data
  - Safe to run multiple times

.NOTES
  Run in an elevated PowerShell session.
#>

$ErrorActionPreference = 'Stop'

Write-Host "=== Windows Recall Hardening ===" -ForegroundColor Cyan

# --- 1. Disable Recall optional feature (if present) ---
try {
    $recallFeature = Get-WindowsOptionalFeature -Online -FeatureName Recall -ErrorAction Stop

    if ($recallFeature.State -ne 'Disabled') {
        Write-Host "Disabling Recall optional feature..."
        Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart | Out-Null
        $featureChanged = $true
    }
    else {
        Write-Host "Recall optional feature already disabled."
    }
}
catch {
    Write-Host "Recall optional feature not present on this build." -ForegroundColor Yellow
}

# --- 2. Enforce policy: AllowRecall = 0 ---
$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
$policyName = 'AllowRecall'

if (-not (Test-Path $policyPath)) {
    Write-Host "Creating policy registry path..."
    New-Item -Path $policyPath -Force | Out-Null
}

$currentValue = (Get-ItemProperty -Path $policyPath -Name $policyName -ErrorAction SilentlyContinue).$policyName

if ($currentValue -ne 0) {
    Write-Host "Enforcing Recall disabled via policy..."
    New-ItemProperty `
        -Path $policyPath `
        -Name $policyName `
        -PropertyType DWord `
        -Value 0 `
        -Force | Out-Null
}
else {
    Write-Host "Recall policy already enforced."
}

# --- 3. Remove existing Recall snapshot data ---
$snapshotPath = "$env:LOCALAPPDATA\CoreAIPlatform"

if (Test-Path $snapshotPath) {
    Write-Host "Removing existing Recall snapshot data..."
    Remove-Item -Path $snapshotPath -Recurse -Force
}
else {
    Write-Host "No Recall snapshot data found."
}

# --- 4. Summary ---
Write-Host "`n=== Final State ===" -ForegroundColor Green

$finalFeatureState = (Get-WindowsOptionalFeature -Online -FeatureName Recall -ErrorAction SilentlyContinue).State
$finalPolicyValue  = (Get-ItemProperty $policyPath -Name $policyName -ErrorAction SilentlyContinue).$policyName

Write-Host "Recall feature state : $finalFeatureState"
Write-Host "Recall policy value  : $finalPolicyValue"

if ($featureChanged) {
    Write-Host "`nA reboot is recommended to complete feature disablement." -ForegroundColor Yellow
}
