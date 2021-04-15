# Am I on my corp network and need proxies?
# Use Get-DnsClientGlobalSetting
# https://docs.microsoft.com/en-us/powershell/module/dnsclient/get-dnsclientglobalsetting?view=win10-ps
# https://docs.microsoft.com/en-us/powershell/module/dnsclient/get-dnsclient?view=win10-ps

#  Above may not work - not reliable
#  Try -  get-wmiobject -query "Select * FROM Win32_NetworkAdapterConfiguration WHERE IpEnabled='TRUE'"
# http://www.savagenomads.net/2009/07/21/powershell_to_get_network_settings/


# Domain to match
$dnsDomain = "intel"

function CheckCorpDomain ($domain) 
{
    # Parse out FQDN
    $dnsDomainList = Get-DnsClientGlobalSetting
    $FQDN = $dnsDomainList.SuffixSearchList | Select-Object -First 1

    # create an array
    $dnsParts = $FQDN.Substring($FQDN.IndexOf(".") + 1).split(".")

    # Find the element that matches
    $corpDomain = $dnsParts -contains $domain
    return $corpDomain
}

$needProxy = CheckCorpDomain ($dnsDomain)
Write-Host $needProxy