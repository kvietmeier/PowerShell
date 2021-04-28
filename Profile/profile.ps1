###====================================================================================###
<#   
  FileName: profile.ps1
  Created By: Karl Vietmeier
    
  Description:
    My customized PowerShell Profile

    * Detect VPN status and set proxies if required
    * Create a bunch of useful "Linux like" aliases.
    * Functions, aliases, and confidential variables are sourced from external files

#>
###====================================================================================###

# Import some Modules
Import-Module Get-ChildItemColor
Import-Module posh-git

# Color ls output and other aliases
Set-Alias l Get-ChildItemColor -option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -option AllScope
Set-Alias dir Get-ChildItemColor -option AllScope
Set-Alias -Name cd -value cddash -Option AllScope

# Import "secrets" that we don't want to keep in this file
# TBD

# Source files with functions and aliases
# Run from the location of the script so I don't need full path
Set-Location $PSscriptroot

# Functions and confidential variables are in external files - In this repo
. '.\UserFunctions.ps1'
. '.\LinuxFunctions.ps1'
. '.\DetectVPN.ps1'
. '.\CompanyData.ps1'

# Safe way to load variables from another file.
#$CompanyData = Join-Path -Path $PSscriptroot -ChildPath CompanyData.psd1
#if ( Test-Path -Path $CompanyData ) { Import-PowerShellDataFile -Path $CompanyData }


### Set some Variables (test)
# Find out if the current user identity is elevated (has admin rights)
# Find a way to use this :)
$Identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal $identity
$IsAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# We don't need these any more; they were just temporary variables to get to $isAdmin. 
# Delete them to prevent cluttering up the user profile. 
Remove-Variable Identity
Remove-Variable Principal
Remove-Variable IsAdmin

# Increase history
$MaximumHistoryCount = 10000

# Produce UTF-8 by default
$PSDefaultParameterValues["Out-File:Encoding"]="utf8"

# So we know where the .gitconfgig file lives
$GitPath = 'C:\Users\ksvietme\.gitconfig'


# Show selection menu for tab
#Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

# Windows PoshGit w/PowerShell
#. (Resolve-Path "$env:LOCALAPPDATA\GitHub\shell.ps1")
#. $env:github_posh_git\profile.example.ps1


###====================================================================================###
#      VPN detection and setting proxies
#      Leave this in here for now
###====================================================================================###

# Domain to match
#$dnsDomain = "intel"

# Set the VPN adapter to look for
$vpnAdapter="cisco anyconnect"

# Get VPN Status
$vpnstatus=Test-VPNConnection -LikeAdapterDescription $vpnAdapter

### Identify active IPV4 Interface and network type:
<# 
  Odd behaviour - if you sleep, then log back in not on a network, there will be a route to 0.0.0.0 that doesn't show up in "route PRINT"
  $activeIPV4Interface will get set and no route will be false - but the else statement fails because there is no connectprofile.
  - stil does the right thing - not setting proxies so I just have the command silently fail.
#>

$activeIPV4Interface = Get-NetRoute `
    -DestinationPrefix 0.0.0.0/0 `
    -ErrorAction SilentlyContinue `
    -ErrorVariable NoRoute | Sort-Object {$_.RouteMetric+(Get-NetIPInterface -AssociatedRoute $_).InterfaceMetric}| Select-Object -First 1 -ExpandProperty InterfaceIndex

if ($NoRoute) {
    # The network isn't up - so we don't need to set proxies
    Write-Host "No routes - Running without an external network"
}
else {
    # We have a route to 0.0.0.0/0 and an active network up.ink
    $activeNetworkType = (Get-NetConnectionProfile -InterfaceIndex $activeIPV4Interface -ErrorAction SilentlyContinue -ErrorVariable activeIPV4Interface).NetworkCategory
}

<###---
 If the VPN is up, we need to configure Vagrant and Git to use proxies.
 a corp network behind a FW will have a network type of "DomainAuthenticated"
#>

if (($vpnstatus -eq "True") -or ($activeNetworkType -eq "DomainAuthenticated"))
{
	# Proxies
	$env:HTTP_PROXY="$http_proxy"
	$env:HTTPS_PROXY="$https_proxy"
	$env:SOCKS_PROXY="$socks_proxy"
	$env:NO_PROXY="$no_proxy"

    if ($vpnstatus -eq "True") {
           Write-Host "VPN is up - Enabling Proxies:"
    }
    else { Write-Host "On Corp Network - Enabling Proxies:" }

	# Update Vagrant flag file .gitconfig
    $regEx = ".*#proxy.+"
    $replacement = "    proxy = HTTPS_PROXY=http://proxy-dmz.intel.com:912"
    
    # Do some text manipulation magic
    Set-Content -Path C:\Users\ksvietme\.setproxies -Value 'True'
    (Get-Content -Path $GitPath) | Foreach-Object -Process {  $_ -replace $regEx, $replacement  } | Set-Content -Path $GitPath


	Write-Host " "
	Write-Host "HTTP Proxy    - $HTTP_PROXY"
	Write-Host "HTTPS Proxy   - $HTTPS_PROXY"
	Write-Host "No Proxy      - $NO_PROXY"
    Write-Host " "

} else {
	# Update Vagrant flag file
    Set-Content -Path C:\Users\ksvietme\.setproxies -Value 'False'

    # Update Vagrant flag file and .gitconfig
    $regEx = ".*proxy.+"
    $replacement = "    #proxy = HTTPS_PROXY=http://proxy-dmz.intel.com:912"

    # Do some text manipulation magic
    Set-Content -Path C:\Users\ksvietme\.setproxies -Value 'False'
    (Get-Content -Path $GitPath) | Foreach-Object -Process {  $_ -replace $regEx, $replacement  } | Set-Content -Path $GitPath

    Write-Host "Not on Corp Network and no VPN - Not Setting Proxies"
    Write-Host ""

}