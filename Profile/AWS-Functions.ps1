function AWS-SSOLogin {
    param(
        [string]$AwsProfile = "AWS-POC-VOC-Cluster-600627351840"
    )

    Write-Host "Using AWS profile: $AwsProfile"
    $env:AWS_PROFILE = $AwsProfile

    # Force fresh SSO login for this profile
    Write-Host "Starting AWS SSO login for $AwsProfile..."
    aws sso login --profile $AwsProfile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "AWS SSO login failed for profile $AwsProfile"
        return
    }

    # Verify identity
    $identity = aws sts get-caller-identity
    if ($LASTEXITCODE -eq 0) {
        Write-Host "AWS SSO login successful. Current identity:"
        $identity | ConvertFrom-Json | Format-List
    } else {
        Write-Host "Still unable to get identity after re-login."
    }
}
