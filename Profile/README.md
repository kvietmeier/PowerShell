### PowerShell Profile Examples

---

My PowerShell Profile and include files - Use at your own risk.  
Some features:  

- Detect VPN and set/unset the system proxies and correct info for Vagrant and git.
- A config block for the PSColor module that will colorize directory listings.
- Misc functions/aliases to create a few "Linux like" CLI tools.
- Some Azure cli aliases to authenticate to a tenant and start/stop VMs.
- A bunch of Kubernetes aliases/functions I scrounged.
- Anything else handy I think of.
  
Files:  

- DetectVPN.ps1  
- LinuxFunctions.ps1  
- Microsoft.PowerShell_profile.ps1  
- Microsoft.VSCode_profile.ps1  
- UserFunctions.ps1  
- PSColorConfig.ps1
- kubecompletion.ps1
- kubectl_aliases.ps1

#### Useful Document Links

- [Understanding the Six PowerShell Profiles - Scripting Blog (microsoft.com)](https://devblogs.microsoft.com/scripting/understanding-the-six-powershell-profiles/)
- [about Profiles - PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.1)

#### Examples

Get your router IP:  

~~~powershell
function GetMyIP {
  $RouterIP = Invoke-RestMethod -uri "https://ipinfo.io"
  
  # See it on the screen
  Write-Host ""
  Write-Host "Current Router/VPN IP: $($RouterIP.ip)"
  Write-Host ""
  
  # Create/Set an Environment variable for later use
  $env:MyIP  = $($RouterIP.ip)
}
# Run function to set variable
Set-Alias myip GetMyIP
~~~

Start and stop some infrastructure VMs:

~~~powershell
function StartCoreVMs {
  Start-AzVM -ResourceGroupName "$VMGroup" "linuxtools" -NoWait
  Start-AzVM -ResourceGroupName "$VMGroup" "WinServer" -NoWait
}
Set-Alias stcore StartCoreVMs

function StopCoreVMs {
  Stop-AzVM -ResourceGroupName "$VMGroup" "linuxtools" -NoWait -Force
  Stop-AzVM -ResourceGroupName "$VMGroup" "WinServer" -NoWait -Force
}
Set-Alias stpcore StopCoreVMs
~~~

Login and out of Azure:

~~~powershell
function AZCommConnectSP () {
  az login --service-principal `
   --username $SPAppID `
   --password $SPSecret `
   --tenant $TenantID
}
Set-Alias azlogin AZCommConnectSP

function AZcommLogout () { azlogout "az logout --username $SPAppID" }
Set-Alias azlogout AZcommLogout
~~~
