# Set your profile folder path
$profileFolder = Split-Path -Parent $PROFILE

# Find all .ps1 files
$ps1Files = Get-ChildItem -Path $profileFolder -Filter '*.ps1' -File

# Initialize array for results
$results = @()

# Scan each file
foreach ($file in $ps1Files) {
    $content = Get-Content $file.FullName

    # Extract functions
    $functions = $content | Select-String -Pattern '^\s*function\s+([a-zA-Z0-9_]+)' | ForEach-Object {
        ($_ -match 'function\s+([a-zA-Z0-9_]+)') | Out-Null
        $matches[1]
    }

    # Extract aliases
    $aliases = $content | Select-String -Pattern '^\s*(Set-Alias|New-Alias)\s+([a-zA-Z0-9_]+)\s+([^\s]+)' | ForEach-Object {
        ($_ -match '(Set-Alias|New-Alias)\s+([a-zA-Z0-9_]+)\s+([^\s]+)') | Out-Null
        [PSCustomObject]@{
            Alias   = $matches[2]
            Command = $matches[3]
        }
    }

    # Save file, functions, and aliases
    $results += [PSCustomObject]@{
        File      = $file.Name
        Functions = $functions
        Aliases   = $aliases
    }
}

# Output grouped by file
foreach ($item in $results) {
    Write-Host "`n=== $($item.File) ===" -ForegroundColor Cyan

    if ($item.Functions.Count -gt 0) {
        Write-Host "-- Functions --" -ForegroundColor Green
        $item.Functions | ForEach-Object { Write-Host $_ }
    }

    if ($item.Aliases.Count -gt 0) {
        Write-Host "-- Aliases --" -ForegroundColor Yellow
        foreach ($alias in $item.Aliases) {
            Write-Host ("{0} -> {1}" -f $alias.Alias, $alias.Command)
        }
    }
}
