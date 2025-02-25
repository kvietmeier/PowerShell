# This works - 
# Define the path to your .tfvars file
$tfvarsFilePath = "C:\Users\karl.vietmeier\repos\Terraform\gcp\CoreInfra\firewalls\my_rules\fw.terraform.tfvars.test"

# Read the content of the .tfvars file
$tfvarsContent = Get-Content -Path $tfvarsFilePath -Raw

# Define the old and new IP addresses
$oldIpAddresses = @("47.144.74.13")
$newIpAddresses = @("47.144.74.26")

# Replace the old IP addresses with the new IP addresses
for ($i = 0; $i -lt $oldIpAddresses.Length; $i++) {
    $tfvarsContent = $tfvarsContent -replace [regex]::Escape($oldIpAddresses[$i]), $newIpAddresses[$i]
}

# Write the updated content back to the .tfvars file
Set-Content -Path $tfvarsFilePath -Value $tfvarsContent

Write-Host "IP addresses updated successfully!"
