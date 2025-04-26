### PowerShell Profile Examples

---

My PowerShell Profile and include files - Use at your own risk.  
Some features:  

- Detect VPN and set/unset the system proxies and correct info for Vagrant and git.
- A config block for the PSColor module that will colorize directory listings.
- Misc functions/aliases to create a few "Linux like" CLI tools.
- Azure cli aliases to authenticate to a tenant and start/stop VMs.
- Same for GCP
- A bunch of Kubernetes aliases/functions I scrounged.
- Same for Git
- Anything else handy I think of.
  
Files:  

- AzureFunctions.ps1
- CommandAliases.ps1
- GCPFunctions.ps1
- K8SAndGit.ps1
- kubecompletion.ps1
- LinuxFunctions.ps1
- Microsoft.PowerShell_profile.ps1
- VSCode_profile.ps1
- ProcessFunctions.ps1
- TerminalAndPrompts.ps1
- TerraformFunctions.ps1
- UserFunctions.ps1

#### Useful Document Links

- [Understanding the Six PowerShell Profiles - Scripting Blog (microsoft.com)](https://devblogs.microsoft.com/scripting/understanding-the-six-powershell-profiles/)
- [about Profiles - PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.1)

#### Examples

Reference the source files in the master profile script -

~~~powershell
###--- Functions and Aliases
# Base folder path
$OneDriveVastPath = "C:\Users\karl.vietmeier\OneDrive - Vast Data\Documents\WindowsPowerShell"

# Individual Function Definition Files
$UserFunctionsPath         = Join-Path $OneDriveVastPath "UserFunctions.ps1"
$LinuxFunctionsPath        = Join-Path $OneDriveVastPath "LinuxFunctions.ps1"
$KubeCompletionPath        = Join-Path $OneDriveVastPath "kubecompletion.ps1"
$GCPFunctionPath           = Join-Path $OneDriveVastPath "GCPFunctions.ps1"
$AzureFunctionPath         = Join-Path $OneDriveVastPath "AzureFunctions.ps1"
$TerminAndPromptsPath      = Join-Path $OneDriveVastPath "TerminalAndPrompts.ps1"
$ProcessFunctionsPath      = Join-Path $OneDriveVastPath "ProcessFunctions.ps1"
$K8SAndGitPath             = Join-Path $OneDriveVastPath "K8SAndGit.ps1"
$TerrafromFunctionsPath    = Join-Path $OneDriveVastPath "TerraformFunctions.ps1"

# Load each script if it exists
foreach ($script in @(
    $UserFunctionsPath,
    $LinuxFunctionsPath,
    $KubeCompletionPath,
    $GCPFunctionPath,
    $TerminAndPromptsPath,
    $K8SAndGitPath,
    $ProcessFunctionsPath,
    $TerrafromFunctionsPath,
    $AzureFunctionPath
)) {
    if (Test-Path $script) {
        . $script
    } else {
        Write-Warning "Script not found: $script"
    }
}
```

Get your router IP:  

~~~powershell
function GetMyIP {
  $RouterIP = Invoke-RestMethod -uri "https://ipinfo.io"
  
  # See it on the screen
  Write-Host ""
  Write-Host "Current Router/VPN IP: $($RouterIP.ip)"
  Write-Host ""
  
  # Create/Set an Environment variable for later use
  $env:MyIP  = $($RouterIP.ip)
}
# Run function to set variable
Set-Alias myip GetMyIP
~~~

Start and stop some infrastructure VMs:

~~~powershell
function StartCoreVMs {
  Start-AzVM -ResourceGroupName "$VMGroup" "linuxtools" -NoWait
  Start-AzVM -ResourceGroupName "$VMGroup" "WinServer" -NoWait
}
Set-Alias stcore StartCoreVMs

function StopCoreVMs {
  Stop-AzVM -ResourceGroupName "$VMGroup" "linuxtools" -NoWait -Force
  Stop-AzVM -ResourceGroupName "$VMGroup" "WinServer" -NoWait -Force
}
Set-Alias stpcore StopCoreVMs
~~~

Login and out of Azure:

~~~powershell
function AZCommConnectSP () {
  az login --service-principal `
   --username $SPAppID `
   --password $SPSecret `
   --tenant $TenantID
}
Set-Alias azlogin AZCommConnectSP

function AZcommLogout () { azlogout "az logout --username $SPAppID" }
Set-Alias azlogout AZcommLogout
~~~

Run "terraform apply --auto-approve" with a non-standard tfvars filename

~~~powershell
function tfapply {
  # Get all the .tfvars files in the current directory (no recursion)
  $VarFiles = Get-ChildItem -Path . -Filter "*.tfvars" | Select-Object -ExpandProperty FullName

  # Check if any .tfvars files were found
  if ($VarFiles.Count -eq 0) {
    Write-Host "No .tfvars files found in the current directory."
    return
  }

  # Build the Terraform apply command with each -var-file argument
  $TerraformArgs = $VarFiles | ForEach-Object { "-var-file=$($_)" }

  # Run terraform apply with the .tfvars files
  terraform apply --auto-approve $TerraformArgs
}
~~~
