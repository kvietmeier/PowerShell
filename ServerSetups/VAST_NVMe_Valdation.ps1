<#
.SYNOPSIS
    Validates Windows node readiness for Azure Local, Hyper-V, and VAST NVMe/TCP integration.
.DESCRIPTION
    Checks Active Directory domain membership, installs required RSAT tools, and validates TCP network access to VAST storage VIPs.
.PARAMETER VastVIPs
    Specifies target IP addresses or FQDNs of the VAST cluster NVMe/TCP interfaces.
.PARAMETER Port
    Specifies the target port for NVMe/TCP traffic. Default is 4420.
.EXAMPLE
    .\Test-VastNodeReadiness.ps1 -VastVIPs "10.10.1.50", "10.20.1.50" -Port 4420
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$VastVIPs,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 4420
)

$ErrorActionPreference = "Stop"

try {
    # Verify Active Directory Domain Membership
    Write-Verbose "Verifying domain membership for node: $env:COMPUTERNAME"
    $DomainStatus = Get-CimInstance -ClassName Win32_ComputerSystem
    if (-not $DomainStatus.PartOfDomain) {
        throw "Node [$env:COMPUTERNAME] is not joined to an Active Directory domain."
    }

    # Install RSAT Active Directory and Failover Clustering Tools
    Write-Verbose "Installing RSAT management features..."
    $RsatFeatures = @("RSAT-AD-PowerShell", "RSAT-Clustering-PowerShell")
    $InstallResult = Install-WindowsFeature -Name $RsatFeatures -IncludeAllSubFeature
    
    if (-not $InstallResult.Success) {
        throw "Failed to install required RSAT features."
    }

    # Test connectivity to VAST NVMe/TCP endpoints
    foreach ($vip in $VastVIPs) {
        Write-Verbose "Testing TCP port $Port on VAST endpoint: $vip"
        $NetTest = Test-NetConnection -ComputerName $vip -Port $Port -WarningAction SilentlyContinue
        
        if (-not $NetTest.TcpTestSucceeded) {
            throw "NVMe/TCP endpoint [$vip:$Port] unreachable from [$env:COMPUTERNAME]."
        }
    }

    Write-Host "Node [$env:COMPUTERNAME] validation successful." -ForegroundColor Green
}
catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    exit 1
}