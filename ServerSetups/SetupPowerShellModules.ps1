<#
.SYNOPSIS
    Deploys PowerShell modules for Azure Local, Hyper-V, and VAST Storage automation pipelines.
.DESCRIPTION
    Configures TLS 1.2, installs NuGet provider, trusts PSGallery, upgrades package management, and provisions core management modules.
#>
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet("All", "AzureLocal", "CoreAz")]
    [string]$ModuleScope = "All"
)

$ErrorActionPreference = "Stop"

function Set-EnvironmentPrerequisites {
    [CmdletBinding()]
    param ()
    
    try {
        # Enforce TLS 1.2 for PSGallery transactions
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Set process execution policy
        if ((Get-ExecutionPolicy -Scope Process) -ne "RemoteSigned") {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
        }

        # Validate NuGet package provider version safely
        $NugetProvider = Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue
        if (-not $NugetProvider -or $NugetProvider.Version -lt [Version]"2.8.5.201") {
            Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Scope CurrentUser -Force | Out-Null
        }

        # Trust PSGallery repository
        if ((Get-PSRepository -Name "PSGallery").InstallationPolicy -ne "Trusted") {
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        }

        # Upgrade PowerShellGet module
        Install-Module -Name "PowerShellGet" -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck
    }
    catch {
        throw "Failed to configure environment prerequisites: $($_.Exception.Message)"
    }
}

function Install-EnterpriseModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ModuleList
    )

    foreach ($module in $ModuleList) {
        try {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-Verbose "Installing module: $module"
                Install-Module -Name $module `
                    -Repository "PSGallery" `
                    -Scope "CurrentUser" `
                    -AllowClobber `
                    -Force `
                    -SkipPublisherCheck `
                    -ErrorAction Stop
            }
            else {
                Write-Verbose "Module $module is present. Skipping installation."
            }
        }
        catch {
            Write-Error "Failed to install module [$module]: $($_.Exception.Message)"
        }
    }
}

# Main Execution Pipeline
try {
    Set-EnvironmentPrerequisites

    $CoreAzModules = @(
        "Az.Accounts",
        "Az.Resources",
        "Az.Network"
    )

    $AzureLocalModules = @(
        "Az.StackHCI",
        "Az.ConnectedMachine"
    )

    switch ($ModuleScope) {
        "CoreAz" {
            Install-EnterpriseModule -ModuleList $CoreAzModules
        }
        "AzureLocal" {
            Install-EnterpriseModule -ModuleList $AzureLocalModules
        }
        "All" {
            Install-EnterpriseModule -ModuleList ($CoreAzModules + $AzureLocalModules)
        }
    }
}
catch {
    Write-Error "Infrastructure setup script failed: $($_.Exception.Message)"
}