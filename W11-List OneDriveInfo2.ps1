$baseKey = "HKCU:\Software\Microsoft\OneDrive\Accounts"
Get-ChildItem $baseKey | ForEach-Object {
    $props = Get-ItemProperty $_.PSPath
    [PSCustomObject]@{
        Account      = $props.UserEmail
        MountPoints  = (Get-ItemProperty -Path (Join-Path $_.PSPath "ScopeIdToMountPointPathCache") -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | ForEach-Object { $_.Value }
    }
}
