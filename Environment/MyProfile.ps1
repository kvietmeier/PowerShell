### Name: _profile.ps1
### Karl Vietmeier

# Import Modules
Import-Module Get-ChildItemColor
Import-Module posh-git

# Color ls output and other aliases
Set-Alias l Get-ChildItemColor -option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -option AllScope
Set-Alias dir Get-ChildItemColor -option AllScope
Set-Alias -Name cd -value cddash -Option AllScope


# Increase history
$MaximumHistoryCount = 10000

# Produce UTF-8 by default
$PSDefaultParameterValues["Out-File:Encoding"]="utf8"

# Show selection menu for tab
#Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

# Windows PoshGit w/PowerShell
#. (Resolve-Path "$env:LOCALAPPDATA\GitHub\shell.ps1")
#. $env:github_posh_git\profile.example.ps1

###- Set some variables

# Vagrant doesn't like the Intel https proxy
$http_proxy='yourproxy'
$https_proxy='yourproxy'
$socks_proxy='yourproxy'
$no_proxy='127.0.0.1, 172.16.0.0, 172.10.0.0'

# Domain to match
#$dnsDomain = "intel"
$vpnAdapter="cisco anyconnect"


#######################################################
# Prompt mods for ConEmu
#######################################################
function prompt
{
  $loc = Get-Location

  # Emulate standard PS prompt with location followed by ">"
  $out = "PS $loc> "

  # Simple check for ConEmu existance and ANSI emulation enabled
  if ($env:ConEmuANSI -eq "ON") {
    # Let ConEmu know when the prompt ends, to select typed
    # command properly with "Shift+Home", to change cursor
    # position in the prompt by simple mouse click, etc.
    $out += "$([char]27)]9;12$([char]7)"

    # And current working directory (FileSystem)
    # ConEmu may show full path or just current folder name
    # in the Tab label (check Tab templates)
    # Also this knowledge is crucial to process hyperlinks clicks
    # on files in the output from compilers and source control
    # systems (git, hg, ...)
    if ($loc.Provider.Name -eq "FileSystem") {
      $out += "$([char]27)]9;9;`"$($loc.Path)`"$([char]7)"
    }
  }

  return $out
}

#######################################################
# Helper Functions
#######################################################

function uptime {
	Get-WmiObject win32_operatingsystem | Select-Object csname, @{LABEL='LastBootUpTime';
	EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}

function find-file($name) {
	Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
		$place_path = $_.directory
		Write-Output "${place_path}\${_}"
	}
}

function get-path { ($Env:Path).Split(";") }
function cd...  { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }

Function llm
{
 # Lock Screen 
 $signature = @"  
    [DllImport("user32.dll", SetLastError = true)]  
    public static extern bool LockWorkStation();  
"@  
    $LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru  

    $LockWorkStation::LockWorkStation()|Out-Null
}

function exp_here {
    explorer .
}


#######################################################
# Unixlike commands
#######################################################

function df { get-volume }
function ll($name) { Get-ChildItem -Path . }

function sed($file, $find, $replace){
	(Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function sed_recursive($filePattern, $find, $replace) {
	$files = Get-ChildItem . "$filePattern" -rec
	foreach ($file in $files) {
		(Get-Content $file.PSPath) |
		Foreach-Object { $_ -replace "$find", "$replace" } |
		Set-Content $file.PSPath
	}
}

function grep($regex, $dir) {
	if ( $dir ) {
		Get-ChildItem $dir | select-string $regex
		return
	}
	$input | select-string $regex
}

function grepv($regex) {
	$input | Where-Object { !$_.Contains($regex) }
}

function which($name) {
	Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
	set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
	Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
	Get-Process $name
}

function touch($file) {
	"" | Out-File $file -Encoding ASCII
}

function cddash {
    if ($args[0] -eq '-') {
        $pwd = $OLDPWD;
    } else {
        $pwd = $args[0];
    }
    $tmp = Get-Location;

    if ($pwd) {
        Set-Location $pwd;
    }
    Set-Variable -Name OLDPWD -Value $tmp -Scope global;
}

# From https://github.com/keithbloom/powershell-profile/blob/master/Microsoft.PowerShell_profile.ps1
function sudo {
	$file, [string]$arguments = $args;
	$psi = new-object System.Diagnostics.ProcessStartInfo $file;
	$psi.Arguments = $arguments;
	$psi.Verb = "runas";
	$psi.WorkingDirectory = get-location;
	[System.Diagnostics.Process]::Start($psi) >> $null
}

# https://gist.github.com/aroben/5542538
function pstree {
	$ProcessesById = @{}
	foreach ($Process in (Get-WMIObject -Class Win32_Process)) {
		$ProcessesById[$Process.ProcessId] = $Process
	}

	$ProcessesWithoutParents = @()
	$ProcessesByParent = @{}
	foreach ($Pair in $ProcessesById.GetEnumerator()) {
		$Process = $Pair.Value

		if (($Process.ParentProcessId -eq 0) -or !$ProcessesById.ContainsKey($Process.ParentProcessId)) {
			$ProcessesWithoutParents += $Process
			continue
		}

		if (!$ProcessesByParent.ContainsKey($Process.ParentProcessId)) {
			$ProcessesByParent[$Process.ParentProcessId] = @()
		}
		$Siblings = $ProcessesByParent[$Process.ParentProcessId]
		$Siblings += $Process
		$ProcessesByParent[$Process.ParentProcessId] = $Siblings
	}

	function Show-ProcessTree([UInt32]$ProcessId, $IndentLevel) {
		$Process = $ProcessesById[$ProcessId]
		$Indent = " " * $IndentLevel
		if ($Process.CommandLine) {
			$Description = $Process.CommandLine
		} else {
			$Description = $Process.Caption
		}

		Write-Output ("{0,6}{1} {2}" -f $Process.ProcessId, $Indent, $Description)
		foreach ($Child in ($ProcessesByParent[$ProcessId] | Sort-Object CreationDate)) {
			Show-ProcessTree $Child.ProcessId ($IndentLevel + 4)
		}
	}

	Write-Output ("{0,6} {1}" -f "PID", "Command Line")
	Write-Output ("{0,6} {1}" -f "---", "------------")

	foreach ($Process in ($ProcessesWithoutParents | Sort-Object CreationDate)) {
		Show-ProcessTree $Process.ProcessId 0
	}
}

#==== Utilities

function unzip ($file) {
    $dirname = (Get-Item $file).Basename
    Write-Output("Extracting", $file, "to", $dirname)
    New-Item -Force -ItemType directory -Path $dirname
    expand-archive $file -OutputPath $dirname -ShowProgress
}

#=====  Test if VPN is up
# https://gallery.technet.microsoft.com/scriptcenter/Test-VPNConnection-Check-36fa4b57
Function Test-VPNConnection
{
<#
.SYNOPSIS
    Check to see if there is an active VPN connection.
    
.DESCRIPTION
    Check to see if there is an active VPN connection by using the Win32_NetworkAdapter and the
     Win32_NetworkAdapterConfiguration WMI classes.
    
.PARAMETER NotMatchAdapterDescription
    Excludes on the network adapter description field using regex matching. Precedence order: 0.
    Following WAN Miniport adapters are used for Microsoft Remote Access based VPN
     so are not excluded by default: L2TP, SSTP, IKEv2, PPTP
    
.PARAMETER LikeAdapterDescription
    Matches on the network adapter description field using wild card matching. Precedence order: 1.
    
.PARAMETER LikeAdapterDNSDomain
    Matches on the network adapter DNS Domain field using wild card matching. Precedence order: 2.
    
.PARAMETER LikeAdapterDHCPServer
    Matches on the network adapter DHCP Server field using wild card matching. Precedence order: 3.
    
.PARAMETER LikeAdapterDefaultGateway
    Matches on the network adapter Default Gateway field using wild card matching. Precedence order: 4.
    
.PARAMETER DisplayNetworkAdapterTable
    Logs the full list of network adapters and also the filterd list of possible VPN connection
     network adapters.
    
.EXAMPLE
    Test-VPNConnection
    
.NOTES
    $AllNetworkAdapterConfigTable contains all criteria for detecting VPN connections.
    Try to choose criteria that:
      1) Uniquely identifies the network(s) of interest.
      2) Try not to rely on networking data that may change in future. For example, default gateways
         and DNS and DHCP addresses may change over time or there may be too many to match on.
         Try to use wildcard or regular expression matches if there is an available pattern
         to match multiple values on.
.LINK
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$NotMatchAdapterDescription = ('^WAN Miniport \(PPPOE\)','^WAN Miniport \(IPv6\)','^WAN Miniport \(Network Monitor\)',
                                                 '^WAN Miniport \(IP\)','^Microsoft 6to4 Adapter','^Microsoft Virtual WiFi Miniport Adapter',
                                                 '^Microsoft WiFi Direct Virtual Adapter','^Microsoft ISATAP Adapter','^Direct Parallel',
                                                 '^Microsoft Kernel Debug Network Adapter','^Microsoft Teredo','^Packet Scheduler Miniport',
                                                 '^VMware Virtual','^vmxnet','VirtualBox','^Bluetooth Device','^RAS Async Adapter','USB'),
        
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$LikeAdapterDescription = ('*vpn*','*juniper*','*check point*','*cisco anyconnect*'),
        
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$LikeAdapterDNSDomain = ('*.*'),
        
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$LikeAdapterDHCPServer,
        
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$LikeAdapterDefaultGateway,
        
        [Parameter(Mandatory=$false)]
        [switch]$DisplayNetworkAdapterTable = $false
    )
    
    Begin
    {
        [scriptblock]$AdapterDescriptionFilter = {
            [CmdletBinding()]
            Param
            (
                [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
                $sbInputObject,
                
                [Parameter(Mandatory=$true,Position=1)]
                [string[]]$sbNotMatchAdapterDescription
            )
            
            $SendToPipeline = $true
            ForEach ($sbNotMatchDesc in $sbNotMatchAdapterDescription)
            {
                If ($sbInputObject.Description -imatch $sbNotMatchDesc)
                {
                    $SendToPipeline = $false
                    Break
                }
            }
            
            If ($SendToPipeline)
            {
                Write-Output $sbInputObject
            }
        }
    }
    Process
    {
        Try
        {
            [psobject[]]$AllNetworkAdapter           = Get-WmiObject Win32_NetworkAdapter -ErrorAction 'Stop' |
                                                       Select-Object -Property DeviceID, PNPDeviceID, Manufacturer
            
            [psobject[]]$AllNetworkAdapterConfigTemp = Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction 'Stop' |
                                                       Select-Object -Property @{L='DeviceID'; E={$_.Index}}, DNSDomain, DefaultIPGateway, DHCPServer, IPEnabled, PhysicalAdapter, Manufacturer, Description
            
            ForEach ($AdapterConfig in $AllNetworkAdapterConfigTemp)
            {
                ForEach ($Adapter in $AllNetworkAdapter)
                {
                    If ($AdapterConfig.DeviceID -eq $Adapter.DeviceID)
                    {
                        ## Note: We create our own custom PhysicalAdapter property b/c the one in the
                        ##       Win32_NetworkAdapter class is not accurate.
                        $AdapterConfig.PhysicalAdapter        = [boolean]($Adapter.PNPDeviceID -imatch '^PCI\\')
                        $AdapterConfig.Manufacturer           = $Adapter.Manufacturer
                        [psobject[]]$AllNetworkAdapterConfig += $AdapterConfig
                    }
                }
            }
            
            ## This table contains the major markers that might help user create the criteria for detecting VPN connections.
            [string]$AllNetworkAdapterConfigTable   = $AllNetworkAdapterConfig |
                                                      Format-Table DNSDomain, DefaultIPGateway, DHCPServer, IPEnabled, PhysicalAdapter, Manufacturer, Description -AutoSize -Wrap | Out-String
            
            ## Sanitize list of Network Adapters by removing:
            ##  a) physical adapters
            ##  b) adapters which we know are not VPN connections
            [psobject[]]$NetworkAdapterConfig       = $AllNetworkAdapterConfig |
                                                      Where-Object   { -not ($_.PhysicalAdapter) } |
                                                      ForEach-Object {
                                                                        &$AdapterDescriptionFilter -sbInputObject $_ -sbNotMatchAdapterDescription $NotMatchAdapterDescription
                                                                     }
            [string]$NetworkAdapterConfigTable      = $NetworkAdapterConfig |
                                                      Format-Table DNSDomain, DefaultIPGateway, DHCPServer, IPEnabled, PhysicalAdapter, Manufacturer, Description -AutoSize -Wrap | Out-String
            
            ## Sanitize list of Network Adapters by removing:
            ##  a) adapters which are not connected (IP Enabled)
            $NetworkAdapterConfig = $NetworkAdapterConfig | Where-Object { $_.IpEnabled }
            [string]$IpEnabledNetworkAdapterConfigTable = $NetworkAdapterConfig |
                                                          Format-Table DNSDomain, DefaultIPGateway, DHCPServer, IPEnabled, PhysicalAdapter, Manufacturer, Description -AutoSize -Wrap | Out-String
            
            ## Discover VPN Network Adapter by using multiple search criteria.
            ## Search stops at the first match using below precedence order.
            [string]$VPNMatchUsing = ''
            
            #  Precedence Order 1: Detect VPN connection based on key words in network adapter description field.
            If ($LikeAdapterDescription)
            {
                ForEach ($LikeDescription in $LikeAdapterDescription)
                {
                    If ([boolean]($NetworkAdapterConfig | Where-Object {($_ | Select-Object -ExpandProperty Description) -ilike $LikeDescription}))
                    {
                        $VPNMatchUsing = 'VPN Network Adapter matched on search criteria in parameter [-LikeAdapterDescription]'
                        Return $true
                    }
                }
            }
            
            #  Precedence Order 2: Detect VPN based on DNS domain (e.g.: contoso.com).
            If ($LikeAdapterDNSDomain)
            {
                ForEach ($LikeDNSDomain in $LikeAdapterDNSDomain)
                {
                    If ([boolean]($NetworkAdapterConfig | Where-Object {($_ | Select-Object -ExpandProperty DNSDomain) -ilike $LikeDNSDomain}))
                    {
                        $VPNMatchUsing = 'VPN Network Adapter matched on search criteria in parameter [-LikeAdapterDNSDomain]'
                        Return $true
                    }
                }
            }
            
            #  Precedence Order 3: Detect VPN connection based on the DHCP Server of the network adapter
            If ($LikeAdapterDHCPServer)
            {
                ForEach ($LikeDHCPServer in $LikeAdapterDHCPServer)
                {
                    If ([boolean]($NetworkAdapterConfig | Where-Object {($_ | Select-Object -ExpandProperty DHCPServer) -ilike $LikeDHCPServer}))
                    {
                        $VPNMatchUsing = 'VPN Network Adapter matched on search criteria in parameter [-LikeAdapterDHCPServer]'
                        Return $true
                    }
                }
            }
            
            #  Precedence Order 4: Detect VPN connection based on the default gateway for the network adapter.
            If ($LikeAdapterDefaultGateway)
            {
                ForEach ($LikeDefaultGateway in $LikeAdapterDefaultGateway)
                {
                    If ([boolean]($NetworkAdapterConfig | Where-Object {($_ | Select-Object -ExpandProperty DefaultIPGateway) -ilike $LikeDefaultGateway}))
                    {
                        $VPNMatchUsing = 'VPN Network Adapter matched on search criteria in parameter [-LikeAdapterDefaultGateway]'
                        Return $true
                    }
                }
            }
            Return $false
        }
        Catch
        {
            Return $false
        }
    }
    End
    {
        ## Display Network Adapter Tables
        If ($DisplayNetworkAdapterTable)
        {
            Write-Host "All network adapters: `n$AllNetworkAdapterConfigTable"                                         -ForegroundColor 'Magenta'
            Write-Host "Filtered to possible VPN network adapters: `n$NetworkAdapterConfigTable"                       -ForegroundColor 'Yellow'
            Write-Host "Filtered to possible VPN network adapters (IP Enabled): `n$IpEnabledNetworkAdapterConfigTable" -ForegroundColor 'Cyan'
            If (-not ([string]::IsNullOrEmpty($VPNMatchUsing)))
            {
                Write-Host "$VPNMatchUsing" -ForegroundColor 'White'
            }
        }
    }
}


# Get VPN Status
$vpnstatus=Test-VPNConnection -LikeAdapterDescription $vpnAdapter

# Identify active IPV4 Interface and network type:
# Odd behaviour - if you sleep, then log back in not on a network, there will be a route to 0.0.0.0 thatr doesn't show up in "route PRINT"
# $activeIPV4Interface will get set and no route will be false - but the else statement fails because there is no connectprofle. 
# - stil does the right thing - not setting proxies so I just have the command silently fail.
$activeIPV4Interface = Get-NetRoute -DestinationPrefix 0.0.0.0/0 -ErrorAction SilentlyContinue -ErrorVariable NoRoute | Sort-Object {$_.RouteMetric+(Get-NetIPInterface -AssociatedRoute $_).InterfaceMetric}| Select-Object -First 1 -ExpandProperty InterfaceIndex 
if ($NoRoute) {
    # The network isn't up - so we don't need to set proxies
    Write-Host "Running without an external network"
}
else {
    # We have a route to 0.0.0.0/0 and an active network up.ink
    $activeNetworkType = (Get-NetConnectionProfile -InterfaceIndex $activeIPV4Interface -ErrorAction SilentlyContinue -ErrorVariable activeIPV4Interface).NetworkCategory
}

# Set proxies if VPN is up or we are on corp network
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

	# Update Vagrant flag file
    set-Content -Path C:\Users\ksvietme\.setproxies -Value 'True'
    
	Write-Host " "
	Write-Host "HTTP Proxy    - $HTTP_PROXY"
	Write-Host "HTTPS Proxy   - $HTTPS_PROXY"
	Write-Host "No Proxy      - $NO_PROXY"
    Write-Host " "
    
} else {
    
	# Update Vagrant flag file
    set-Content -Path C:\Users\ksvietme\.setproxies -Value 'False'
    
    Write-Host "Not on Corp Network and no VPN - Not Setting Proxies"
    Write-Host ""
    
}

