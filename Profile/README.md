### PowerShell Profile Examples

---

My PowerShell Profile and include files - Use at your own risk.  
Some features:  

- Detect VPN and set/unset the system proxies and correct info for Vagrant and git.
- A config block for the PSColor module thta will colorize directory listings.
- Misc functions/aliases to create a few "Linux like" CLI tools.
- Some Azure cli aliases to authenticate to a tenant and start/stop VMs.
- Anything else handy I think of.
  
Files:  

- DetectVPN.ps1  
- LinuxFunctions.ps1  
- Microsoft.PowerShell_profile.ps1  
- Microsoft.VSCode_profile.ps1  
- UserFunctions.ps1  
- PSColorConfig.ps1

#### Example

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
