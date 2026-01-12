<#
.SYNOPSIS
    Active Directory Domain Services (AD DS) Initialization for GCP.
    
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
    1. NETWORK: Captures current GCP DHCP lease and converts it to a Static OS assignment.
    2. DNS: Configures the local loopback (127.0.0.1) as the primary resolver for AD.
    3. IPV6: Disables IPv6 to prevent DNS resolution conflicts and prerequisite warnings.
    4. ROLES: Installs AD-Domain-Services and required Management Tools.
    5. PROMOTION: Deploys a new Forest (ginaz.org) and triggers a mandatory reboot.
#>

# 1. Set OS IP to Static (Crucial for AD stability)
Write-Host "Configuring Static IP based on GCP Assignment..." -ForegroundColor Cyan
$IPConfig = Get-NetIPConfiguration | Where-Object {$_.IPv4Address -ne $null}
$InterfaceAlias = $IPConfig.InterfaceAlias
$IPAddress = "172.20.16.54" # Your specific GCP Assigned IP
$Gateway = $IPConfig.Ipv4DefaultGateway.NextHop
$Prefix = $IPConfig.IPv4Address.PrefixLength

New-NetIPAddress -InterfaceAlias $InterfaceAlias `
                 -IPAddress $IPAddress `
                 -PrefixLength $Prefix `
                 -DefaultGateway $Gateway `
                 -ErrorAction SilentlyContinue

Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("127.0.0.1")
Disable-NetAdapterBinding -Name $InterfaceAlias -ComponentID ms_tcpip6

# 2. Install AD Feature
Write-Host "Installing Windows Features..." -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# 3. Promote to Forest
Write-Host "Promoting to Domain Controller (Reboot will occur)..." -ForegroundColor Cyan
$SafeModePassword = ConvertTo-SecureString "Chalc0pyr1te!123" -AsPlainText -Force

Install-ADDSForest -DomainName "ginaz.org" `
    -DomainNetbiosName "ginaz" `
    -InstallDns:$true `
    -NoRebootOnCompletion:$false `
    -SafeModeAdministratorPassword $SafeModePassword
