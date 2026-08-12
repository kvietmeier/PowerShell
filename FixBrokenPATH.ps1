###=================================================================================###
<# 
  Filename: Repair-SystemPath.ps1
  
  Description: Repairs the System PATH environment variable. Enforces mandatory 
  OS default paths, purges orphaned Windows Terminal entries, deduplicates 
  existing variables, and applies changes to the Machine scope and current session.
  
  Configurations Applied:
  1. Inject mandatory OS paths (System32, Wbem, PowerShell)
  2. Purge orphaned WindowsTerminal string matches
  3. Deduplicate PATH array elements
  4. Commit sanitized PATH to Machine registry scope
  5. Refresh active session environment PATH
  
  Written By: Gemini 
#>
###=================================================================================###

#Requires -RunAsAdministrator

try {
    $ErrorActionPreference = "Stop"

    Write-Output "Repairing System PATH environment variable..."

    # 1. Define mandatory default system paths
    $DefaultPaths = @(
        "$env:SystemRoot\system32",
        "$env:SystemRoot",
        "$env:SystemRoot\System32\Wbem",
        "$env:SystemRoot\System32\WindowsPowerShell\v1.0\"
    )

    # 2. Retrieve Machine PATH and purge orphaned WindowsTerminal entries
    $CurrentMachinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine") -split ';' | 
        Where-Object { $_ -and $_ -notmatch "WindowsTerminal" }

    # 3. Merge default paths with existing custom paths
    $UpdatedPathList = ($DefaultPaths + $CurrentMachinePath) | Select-Object -Unique

    # 4. Commit clean PATH to Machine Registry
    $CleanMachinePath = $UpdatedPathList -join ';'
    [Environment]::SetEnvironmentVariable("PATH", $CleanMachinePath, "Machine")

    # 5. Force update active session PATH
    $CurrentUserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$CleanMachinePath;$CurrentUserPath"

    Write-Output "PATH environment successfully restored."
    Write-Output "Current active PATH: $env:PATH"

} catch {
    Write-Error "PATH repair failed: $($_.Exception.Message)"
    exit 1
}