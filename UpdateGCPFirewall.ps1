# Path to your tfvars file
$filePath = "C:\Users\karl.vietmeier\repos\Terraform\gcp\CoreInfra\firewalls\my_rules\fw.terraform.tfvars.test"

# Prompt for the IP address
$newIP = Read-Host "Enter the IP address to add"

# Check if the IP address is valid (basic check)
if (-not ([ipaddress]::TryParse($newIP, [ref]$null))) {
    Write-Error "Invalid IP address format."
    return # Exit the script
}

# Check if the file exists
if (Test-Path $filePath) {
    try {
        # Read the file content
        $content = Get-Content $filePath -Raw

        # Debug: Print the original content
        Write-Host "Original content:" -ForegroundColor Green
        Write-Host $content

        # Check if the IP already exists
        if ($content -match [regex]::Escape($newIP)) {
            Write-Host "IP address '$newIP' already exists in the file."
        } else {
            # Find the line containing "ingress_filter = ["
            $ingressFilterLine = $content | Select-String -Pattern "ingress_filter\s*=\s*

\["

            if ($ingressFilterLine) {
                # Find the position of the line
                $lineIndex = $content.IndexOf($ingressFilterLine.Line)

                # Find the position of the closing bracket
                $closingBracketIndex = $content.IndexOf("]", $lineIndex)

                # Insert the new IP address before the closing bracket
                $newContent = $content.Insert($closingBracketIndex, "`n  `"$newIP`",")

                # Debug: Print the updated content
                Write-Host "Updated content:" -ForegroundColor Green
                Write-Host $newContent

                # Write the modified content back to the file
                Set-Content $filePath -Value $newContent

                Write-Host "IP address '$newIP' appended to ingress_filter."

                # Inform the user to run Terraform apply
                Write-Host "Now, run 'terraform apply' from your Terraform directory to apply the changes."
            } else {
                Write-Error "Could not find 'ingress_filter = 