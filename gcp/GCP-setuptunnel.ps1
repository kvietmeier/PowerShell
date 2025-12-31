# Hardcoded VPN host IP address
$VPN_HOST = "10.143.11.91"

# Function to display a menu and get user choice
function Get-UserChoice {
    param (
        [string]$prompt,  # Prompt message to display
        [string[]]$options  # Array of options for the user to choose from
    )
    
    # Display the prompt and options
    Write-Host $prompt
    for ($i = 0; $i -lt $options.Count; $i++) {
        Write-Host "$($i + 1)) $($options[$i])"  # Number the options
    }

    # Get user input
    $choice = Read-Host "Enter your choice [1-$($options.Count)]"
    
    # Validate the choice and return the corresponding option
    if ($choice -ge 1 -and $choice -le $options.Count) {
        return $options[$choice - 1]  # Return the selected option
    } else {
        Write-Host "Invalid option, please enter a number between 1 and $($options.Count)."
        return $null  # Return null for invalid input
    }
}

# Get SSH port from the user
$sshPorts = @("60022", "61022", "62022", "63022")  # Available SSH ports
$SSH_PORTNUM = Get-UserChoice "Pick an SSH port" $sshPorts  # Call the function to get user choice

# Get UI port from the user
$uiPorts = @("10043", "11443", "12443", "13443")  # Available UI ports
$UI_PORTNUM = Get-UserChoice "Pick a UI port" $uiPorts  # Call the function to get user choice

# Get VMS IP from the user
$vmsIPs = @("DH1 / 10.179.198.10", "CNR1 / 10.179.224.10")  # Available VMS IPs
$VMS_IP = Get-UserChoice "Choose a VMS IP" $vmsIPs  # Call the function to get user choice

# Extract the actual IP address from the selected option
if ($VMS_IP -ne $null) {
    $VMS_IP = $VMS_IP.Split(' ')[-1]  # Get the last part, which is the IP address
}

# Check if SSH_PORTNUM and VMS_IP are valid before proceeding
if ($SSH_PORTNUM -and $VMS_IP) {
    # Setting up the SSH tunnel
    Write-Host "Setting up SSH tunnel on $SSH_PORTNUM, you may need to enter your password at least once."
    & ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "GatewayPorts=yes" -f -N -g -C -R $SSH_PORTNUM:192.168.2.2:22 vastdata@$VPN_HOST

    # Setting up the UI tunnel
    Write-Host "Now setting up UI tunnel.."
    & ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -f vastdata@$VPN_HOST "ssh -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' -f -N -g -C -L $UI_PORTNUM:$VMS_IP:443 -p $SSH_PORTNUM vastdata@localhost"

    # Display instructions for SSH access
    Write-Host "Tell people they can ssh to:"
    Write-Host "ssh -p $SSH_PORTNUM vastdata@$VPN_HOST"

    # Display instructions for connecting to VMS
    Write-Host "Tell people they can connect to VMS at:"
    Write-Host "https://$VPN_HOST:$UI_PORTNUM"

    # Final message
    Write-Host "Have a lovely day.. and do NOT disconnect your laptop from the tech port.... :)"
}
