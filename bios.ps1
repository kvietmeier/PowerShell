# Function to display BIOS info.
# Needs ComputerName


# Assigning the current computer's name to the $Computer variable using the environment variable $env:computername
$Computer = $env:computername | Select-Object

# Define a function named Get-BIOSDetails which takes a parameter $Computer
function Get-BIOSDetails {
  param($Computer)

  # Creating an empty custom object with properties ComputerName, BIOSVersion, and SerialNumber
  $output = "" | select ComputerName, BIOSVersion, SerialNumber
  
  # Getting BIOS information using WMI (Windows Management Instrumentation) from Win32_BIOS class on the specified computer ($Computer)
  $obj = Get-WmiObject -Class Win32_BIOS -ComputerName $Computer
  
  # Setting the ComputerName property of $output to the uppercase value of $Computer
  $output.ComputerName = $Computer.ToUpper()
  
  # Setting the BIOSVersion property of $output to the SMBIOSBIOSVersion property from the $obj (BIOS information)
  $output.BIOSVersion = $obj.SMBIOSBIOSVersion
  
  # Setting the SerialNumber property of $output to the SerialNumber property from the $obj (BIOS information)
  $output.SerialNumber = $obj.SerialNumber

  # Returning the $output object with ComputerName, BIOSVersion, and SerialNumber properties populated
  $output
}

