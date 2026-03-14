###--- AWS SSO Utility Functions ------------------------------------------------###

function Get-AwsProfiles {
    $configPath = "$HOME\.aws\config"
    if (-not (Test-Path $configPath)) {
        Write-Host "No AWS config file found at $configPath" -ForegroundColor Yellow
        return @()
    }
    $profiles = Select-String '^\[profile (.+)\]' $configPath | ForEach-Object {
        ($_ -match '^\[profile (.+)\]') | Out-Null
        $matches[1]
    }
    if (-not $profiles) {
        Write-Host "No AWS profiles found." -ForegroundColor Yellow
    }
    return $profiles
}

function Invoke-AwsSsoLogin{
    $configFile = "$HOME\.aws\config"
    if (-not (Test-Path $configFile)) {
        Write-Host "AWS config file not found at $configFile" -ForegroundColor Yellow
        return
    }

    $profiles = @()

    foreach ($line in Get-Content $configFile) {
        if ($line -match '^\[profile (.+)\]') {
            $profiles += $matches[1]
        } elseif ($line -match '^\[default\]') {
            $profiles += "default"
        }
    }

    if ($profiles.Count -eq 0) {
        Write-Host "No AWS profiles found in $configFile." -ForegroundColor Yellow
        return
    }

    Write-Host "Select AWS SSO profile:"
    for ($i = 0; $i -lt $profiles.Count; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $profiles[$i])
    }

    $choice = Read-Host "Enter the number of the profile to login"
    if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $profiles.Count) {
        $profile = $profiles[$choice - 1]
        Write-Host "Logging into $profile ..." -ForegroundColor Cyan
        aws sso login --profile $profile
    } else {
        Write-Host "Invalid choice." -ForegroundColor Red
    }
}

function Get-AwsCliVersion {
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Host "AWS CLI is not installed." -ForegroundColor Red
        return
    }
    aws --version
}

function Invoke-AwsSsoLogout {
    Write-Host "Logging out from all AWS SSO sessions..." -ForegroundColor Yellow
    aws sso logout
    Write-Host "All AWS SSO sessions logged out." -ForegroundColor Green
}

<# function Invoke-AwsSsoLogout2 {
    [CmdletBinding()]
    param(
        [switch]$ForceClearCache
    )

    Write-Host "=== AWS SSO Logout ===" -ForegroundColor Cyan

    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Host "AWS CLI not found. Install/ensure 'aws' is on PATH." -ForegroundColor Red
        return
    }

    # Parse all SSO profiles from ~/.aws/config
    $configPath = Join-Path $HOME ".aws\config"
    if (-not (Test-Path $configPath)) {
        Write-Host "AWS config not found at $configPath" -ForegroundColor Red
        return
    }

    # Extract profile names with sso_start_url
    $profiles = Get-Content $configPath |
        Select-String -Pattern '^\[profile (.+?)\]' -Context 0,5 |
        Where-Object { $_.Context.PostContext -match 'sso_start_url' } |
        ForEach-Object { $_.Matches[0].Groups[1].Value }

    if (-not $profiles) {
        Write-Host "No SSO-enabled AWS profiles found." -ForegroundColor Yellow
        return
    }

    foreach ($profile in $profiles) {
        Write-Host "`nLogging out of AWS SSO profile: $profile" -ForegroundColor Yellow
        $output = & aws sso logout --profile $profile 2>&1
        $exit = $LASTEXITCODE

        if ($exit -eq 0) {
            Write-Host "✔ Logged out: $profile" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to logout $profile (exit code $exit)" -ForegroundColor Red
            Write-Host $output
        }
    }

    if ($ForceClearCache) {
        Write-Host "`nClearing local AWS SSO cache..." -ForegroundColor Yellow

        $cacheDirs = @(
            (Join-Path $HOME ".aws\sso\cache"),
            (Join-Path $HOME ".aws\cli\cache")
        )

        foreach ($dir in $cacheDirs) {
            if (Test-Path $dir) {
                try {
                    Remove-Item -Path $dir\* -Force -ErrorAction Stop
                    Write-Host "Cleared cache in $dir" -ForegroundColor Green
                } catch {
                    Write-Warning "Could not clear cache in $dir: $_"
                }
            }
        }

        Write-Host "SSO cache cleanup complete." -ForegroundColor Cyan
    }

    Write-Host "`nAll logout operations finished." -ForegroundColor Cyan
}

#>





function Test-AwsSsoProfiles {
    $profiles = @("AWS-POC-VOC-Admin", "AWS-POC-VOC-Cluster", "vast-s3-reader")
    foreach ($profile in $profiles) {
        Write-Host "Checking AWS SSO Login Status for profile: $profile" -ForegroundColor Cyan
        try {
            aws sts get-caller-identity --profile $profile --output json | ConvertFrom-Json | Out-Host
        } catch {
            Write-Host "Not logged in for $profile" -ForegroundColor Red
        }
        Write-Host "---------------------------------------------"
    }
}

function Get-AwsProfileList {
    $profiles = Get-AwsProfiles
    if ($profiles) {
        Write-Host "Available AWS Profiles:" -ForegroundColor Cyan
        $profiles | ForEach-Object { Write-Host " - $_" }
    } else {
        Write-Host "No profiles found." -ForegroundColor Yellow
    }
}

# Aliases
Set-Alias awslogin Invoke-AwsSsoLogin
Set-Alias awslogout Invoke-AwsSsoLogout
Set-Alias awsprofiles Get-AwsProfileList
Set-Alias awscheck Test-AwsSsoProfiles
Set-Alias awsversion Get-AwsCliVersion
