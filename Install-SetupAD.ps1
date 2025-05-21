# Filename: Install-AD-DC-RDP.ps1

# Configuration variables
$domainName = "corp.example.com"           # <-- Set your domain FQDN
$netbiosName = "CORP"                      # <-- Set your NetBIOS name
$adminPasswordPlain = "YourSecurePassword123!"  # <-- Set a secure password
$dsrmPassword = ConvertTo-SecureString "DSRMPassword123!" -AsPlainText -Force

# Secure password for local Administrator
$adminPassword = ConvertTo-SecureString $adminPasswordPlain -AsPlainText -Force

Write-Host "Installing Active Directory Domain Services role and management tools..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host "Promoting server to Domain Controller..." -ForegroundColor Cyan
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -InstallDNS:$true `
    -SafeModeAdministratorPassword $dsrmPassword `
    -Force:$true

# At this point, the system will auto-reboot after promotion.
# So the next part is meant to be re-run **after** reboot.

# ---- Post-reboot steps ----

Write-Host "Enabling Remote Desktop..." -ForegroundColor Cyan
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\' -Name 'fDenyTSConnections' -Value 0

Write-Host "Enabling local Administrator account..." -ForegroundColor Cyan
Enable-LocalUser -Name "Administrator"

Write-Host "Setting local Administrator password..." -ForegroundColor Cyan
Set-LocalUser -Name "Administrator" -Password $adminPassword

Write-Host "Adding Administrator to Remote Desktop Users group..." -ForegroundColor Cyan
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "Administrator"

Write-Host "Enabling RDP in Windows Firewall..." -ForegroundColor Cyan
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

Write-Host "Domain Controller installed, RDP enabled, Administrator configured." -ForegroundColor Green
