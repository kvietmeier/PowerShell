###====================================================================================###
<#   
  FileName:  CompanyData.psd1
  Created By: Karl Vietmeier
    
  Description:
     Confidential information we don't want exposed in profile.ps1 so we can share it

#>
###====================================================================================###

###====================================================================================###
#   Corporate proxy information
#   Notes - Vagrant doesn't like the Intel https proxy, use the http non-SSL proxy
#           Make sure there are no spaces in no_proxy
#   Optional Proxy - "proxy-chain"

$http_proxy='<myproxy1>'
$https_proxy='<myproxy2>'
$socks_proxy='<myproxy3>'
$no_proxy='127.0.0.1,172.16.0.0/24,172.10.0.0/24'
