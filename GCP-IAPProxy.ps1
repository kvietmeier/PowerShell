<#
.SYNOPSIS
    GCP IAP SSH Tunnel Proxy for OpenSSH on Windows

.DESCRIPTION
    This script wraps 'gcloud compute start-iap-tunnel' to be used as a ProxyCommand
    in your OpenSSH configuration on Windows. It allows SSH connections to GCP VMs
    through Identity-Aware Proxy (IAP), including support for LocalForward port
    forwarding.

.PARAMETER HostName
    The hostname or VM name to connect to (required).

.PARAMETER Port
    The SSH port on the target VM (typically 22, required).

.PARAMETER Zone
    The GCP zone where the VM resides (default: "us-west2-a").

.PARAMETER Project
    The GCP project ID (default: "MyProject").

.NOTES
    - Designed for use in Windows OpenSSH ProxyCommand.
    - Any output to stdout before the tunnel starts may break the SSH connection.
    - Harmless "[Errno 5] stdin ReadFile failed" may appear on Windows after disconnect.
    - Ensure 'gcloud.cmd' exists at the path specified in $GCloudPath.
    - Keeps the tunnel functional and compatible with local port forwarding.

.EXAMPLE
    # In .ssh/config
    Host lab01
        HostName devops01
        User labuser01
        IdentityFile C:\Users\karl.vietmeier\.ssh\labuser.priv.key
        ProxyCommand powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\karl.vietmeier\bin\gcp-proxy.ps1" %h %p
        LocalForward 8443 vms:443

    # Command-line usage for testing
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\karl.vietmeier\bin\gcp-proxy.ps1" devops01 22
#>

param(
    [string]$HostName,
    [int]$Port,
    [string]$Zone = "us-west2-a",
    [string]$Project = "MyProject"
)

$GCloudPath = "C:\Users\karl.vietmeier\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"

if (-not (Test-Path $GCloudPath)) { exit 1 }

$cmd = @(
    $GCloudPath,
    "compute", "start-iap-tunnel",
    $HostName, $Port,
    "--zone=$Zone",
    "--project=$Project",
    "--listen-on-stdin",
    "--quiet"
)

# Run the tunnel. Do NOT print anything to stdout.
try {
    & $cmd[0] @($cmd[1..($cmd.Length - 1)])
} catch {
    if ($_.Exception.Message -match 'stdin ReadFile failed') { exit 0 }
    else { exit 1 }
}
