###=================================================================================###
<# 
  Filename: Setup-WindowsServerLab.ps1
  
  Description: Configures Windows Server for lab workloads. Applies baseline 
  configurations including power profiles, security exclusions, and essential tools.
  Note: Intended for lab environments. Not for production use.

  Must be run as Administrator. Idempotent script; can be run multiple times without adverse effects.

  Configurations Applied:
  1. High Performance Power Profile
  2. Hyper-V Antivirus Exclusions
  3. Disable Internet Explorer Enhanced Security Configuration (IEESC)
  4. Disable Watson Error Popups
  5. Persistent RDP Access
  6. Hardware Clock set to UTC
  7. OpenSSH Server Deployment
  8. Google Chrome Enterprise Deployment
  9. Microsoft Edge Enterprise Deployment (Dynamic API Query)
  
  Written By: Gemini 
#>
###=================================================================================###

#Requires -RunAsAdministrator

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ErrorActionPreference = "Stop"

    # Restore System32 PATH integrity
    $Sys32 = "$env:SystemRoot\System32"
    if (($env:PATH -split ';') -notcontains $Sys32) { 
        $env:PATH = "$Sys32;$env:PATH" 
    }

    Write-Output "Applying Idempotent Test Server Baseline..."

    # 1. High Performance Power Profile
    & "$Sys32\powercfg.exe" /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

    # 2. Hyper-V Antivirus Exclusions
    $MpPref = Get-MpPreference
    $Exts = @(".vhd", ".vhdx", ".avhdx") | Where-Object { $MpPref.ExclusionExtension -notcontains $_ }
    if ($Exts) { 
        Add-MpPreference -ExclusionExtension $Exts 
    }
    
    $Procs = @("vmms.exe", "vmwp.exe") | Where-Object { $MpPref.ExclusionProcess -notcontains $_ }
    if ($Procs) { 
        Add-MpPreference -ExclusionProcess $Procs 
    }

    # 3. Disable IEESC
    $IEESC = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    if ((Get-ItemProperty -Path $IEESC -Name "IsInstalled" -ErrorAction SilentlyContinue).IsInstalled -ne 0) {
        Set-ItemProperty -Path $IEESC -Name "IsInstalled" -Value 0 -Force
    }

    # 4. Disable Watson Error Popups
    $WatsonPath = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
    if ((Get-ItemProperty -Path $WatsonPath -Name "Disabled" -ErrorAction SilentlyContinue).Disabled -ne 1) {
        New-ItemProperty -Path $WatsonPath -Name "Disabled" -PropertyType "DWORD" -Value 1 -Force | Out-Null
    }

    # 5. Persistent RDP Access
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

    # 6. Hardware Clock UTC
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type "DWORD" -Force

    # 7. OpenSSH Server Deployment
    $SshCap = Get-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0"
    if ($SshCap.State -ne "Installed") {
        Write-Output "Installing OpenSSH Server..."
        Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" | Out-Null
    }
    
    $SshSvc = Get-Service -Name "sshd" -ErrorAction SilentlyContinue
    if ($SshSvc.StartType -ne "Automatic") { 
        Set-Service -Name "sshd" -StartupType Automatic 
    }
    if ($SshSvc.Status -ne "Running") { 
        Start-Service -Name "sshd" 
    }

    if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow | Out-Null
    }

    # 8. Google Chrome Enterprise Deployment
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe")) {
        Write-Output "Deploying Google Chrome Enterprise..."
        $ChromeMsi = "$env:TEMP\googlechrome64.msi"
        Invoke-WebRequest -Uri "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" -OutFile $ChromeMsi
        Start-Process msiexec.exe -ArgumentList "/i `"$ChromeMsi`" /qn /norestart" -Wait
        Remove-Item -Path $ChromeMsi -Force -ErrorAction SilentlyContinue
    } else {
        Write-Output "Google Chrome present. Skipping."
    }

    # 9. Microsoft Edge Enterprise Deployment
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe")) {
        Write-Output "Querying latest Microsoft Edge Enterprise release..."
        $EdgeApi = Invoke-RestMethod -Uri "https://edgeupdates.microsoft.com/api/products"
        $EdgeMsiUrl = ($EdgeApi | Where-Object { $_.Product -eq "Stable" }).Releases |
                      Where-Object { $_.Architecture -eq "x64" -and $_.Platform -eq "Windows" } |
                      Select-Object -First 1 |
                      Select-Object -ExpandProperty Artifacts |
                      Where-Object { $_.ArtifactName -eq "msi" } |
                      Select-Object -ExpandProperty Location

        if (-not $EdgeMsiUrl) { 
            throw "Unable to resolve Microsoft Edge Enterprise MSI URL." 
        }

        Write-Output "Deploying Microsoft Edge Enterprise..."
        $EdgeMsi = "$env:TEMP\MicrosoftEdgeX64.msi"
        Invoke-WebRequest -Uri $EdgeMsiUrl -OutFile $EdgeMsi
        Start-Process msiexec.exe -ArgumentList "/i `"$EdgeMsi`" /qn /norestart" -Wait
        Remove-Item -Path $EdgeMsi -Force -ErrorAction SilentlyContinue
    } else {
        Write-Output "Microsoft Edge present. Skipping."
    }

    Write-Output "Baseline state verified and applied successfully."

} catch {
    Write-Error "Deployment failed. Exception: $($_.Exception.Message)"
    exit 1
}