<#
.SYNOPSIS
    Post-Promotion Configuration for VAST-Ready Domain Controllers in GCP.
    
.DESCRIPTION
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

SUMMARY OF ACTIONS
    1. FIREWALL: Disables all Windows Firewall profiles to defer security to GCP VPC rules.
    2. DNS FORWARDERS: Configures 169.254.169.254 to leverage Google's internal metadata DNS.
    3. DNS ROOT HINTS: Disables Root Hints to prevent resolution timeouts behind GCP firewalls.
    4. REVERSE LOOKUP: Creates the 172.20.16.x PTR zone required for VAST/Kerberos auth.
    5. IDENTITY: Enables the Domain Administrator and sets a persistent password.
    6. RDP ACCESS: Enables Remote Desktop and injects RDP User Rights into the DC Security Policy.
    7. STRUCTURE: Initializes the 'VAST' and 'Servers' Organizational Unit (OU) hierarchy.
#>

# --- ADMIN & MODULE GATEKEEPER ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: YOU MUST RUN THIS AS ADMINISTRATOR." -ForegroundColor Red
    exit
}

if (!(Get-Module -ListAvailable ActiveDirectory)) {
    Write-Host "Active Directory module missing. Attempting to install..." -ForegroundColor Yellow
    Install-WindowsFeature RSAT-AD-PowerShell
    Import-Module ActiveDirectory
} else {
    Import-Module ActiveDirectory
}


# 1. Disable Firewall (Security is managed via GCP VPC Firewall)
Write-Host "Disabling local firewall profiles..." -ForegroundColor Cyan
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# 2. Fix DNS: Set GCP Forwarder & Disable Root Hints 
Write-Host "Configuring DNS Forwarders and Root Hint settings..." -ForegroundColor Cyan
Set-DnsServerForwarder -IPAddress "169.254.169.254"
$DNSObj = Get-WmiObject -Namespace "root\MicrosoftDNS" -Class MicrosoftDNS_Server
$DNSObj.UseRootHints = $false
$DNSObj.Put()
Restart-Service DNS

# 3. Create Reverse Lookup Zone (Critical for VAST Kerberos/Auth)
Write-Host "Creating Reverse Lookup Zone and PTR record..." -ForegroundColor Cyan
if (!(Get-DnsServerZone -Name "16.20.172.in-addr.arpa" -ErrorAction SilentlyContinue)) {
    Add-DnsServerPrimaryZone -NetworkId "172.20.16.0/24" -ReplicationScope "Forest"
}
Add-DnsServerResourceRecordPtr -Name "54" -ZoneName "16.20.172.in-addr.arpa" -PtrDomainName "w22server02.ginaz.org" -Force

# 4. Configure Admin & Unlock RDP on the DC
Write-Host "Configuring Administrator account and RDP policies..." -ForegroundColor Cyan
Enable-ADAccount -Identity "Administrator"
Set-ADAccountPassword -Identity "Administrator" -NewPassword (ConvertTo-SecureString "Chalc0pyr1te!123" -AsPlainText -Force)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\' -Name 'fDenyTSConnections' -Value 0

# Unlock RDP Rights for the DC specifically via Secedit
$sid = (Get-ADGroup -Identity "Remote Desktop Users").SID.Value
$tempFile = [System.IO.Path]::GetTempFileName()
secedit /export /cfg "$tempFile"
$newContent = foreach ($line in (Get-Content $tempFile)) {
    if ($line -match "SeRemoteInteractiveLogonRight" -and $line -notmatch $sid) { "$line,*$sid" } else { $line }
}
$newContent | Set-Content $tempFile
secedit /configure /db "$env:windir\security\local.sdb" /cfg "$tempFile" /areas USER_RIGHTS

# 5. Create VAST and Server OUs
Write-Host "Creating OU Structure..." -ForegroundColor Cyan
foreach ($ou in @("VAST", "Servers")) {
    if (!(Get-ADOrganizationalUnit -Filter "Name -eq '$ou'")) {
        New-ADOrganizationalUnit -Name "$ou" -Path "DC=ginaz,DC=org"
    }
}

Write-Host "Phase 2 Complete. Domain Controller is now optimized for VAST." -ForegroundColor Green

### Optional - Single Node Move Example
# $NodeName = "VAST-NODE-01" 
# Get-ADComputer $NodeName | Move-ADObject -TargetPath "OU=VAST,DC=ginaz,DC=org"