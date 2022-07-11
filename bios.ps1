# Function to display BIOS info.
# Needs ComputerName
#
$Computer = $env:computername | Select-Object
function Get-BIOSDetails {
  param($Computer)

  $output = “” | select ComputerName, BIOSVersion, SerialNumber
  $obj = Get-WMIObject -Class Win32_BIOS -ComputerName $Computer
  $output.ComputerName = $Computer.ToUpper()
  $output.BIOSVersion = $obj.SMBIOSBIOSVersion
  $output.SerialNumber = $obj.SerialNumber

  $output

}

