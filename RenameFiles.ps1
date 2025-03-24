###=================================================================================###
<# 
  Filename: RenameFiles.ps1
  
  Description:
  Useful if you need to duplicate a Terraform config with many files. 
   * Lists files in the current directory that match the old prefix before doing anything.
   * Displays the list of files that will be renamed.
   * Asks for your confirmation to proceed with renaming all files.
   * If you confirm, it renames all the files matching the old prefix without further prompting.
   * After renaming the files, the script will list the new contents of the directory.
  
  Written By: Karl Vietmeier and ChatGPT                                        
                                                                            
  
#>
###=================================================================================###
# Get the current directory
$PathToDir = Get-Location

# Prompt user for filename prefixes
$oldPrefix = Read-Host "Enter the old filename prefix (e.g., cluster3)"
$newPrefix = Read-Host "Enter the new filename prefix (e.g., cluster4)"

# Trim spaces from inputs
$oldPrefix = $oldPrefix.Trim()
$newPrefix = $newPrefix.Trim()

# Validate inputs
if ($oldPrefix -eq "" -or $newPrefix -eq "") {
    Write-Host "Error: Old and new filename prefixes cannot be empty." -ForegroundColor Red
    exit
}

# List files that match the old prefix
$filesToRename = Get-ChildItem "$PathToDir" -Filter "$oldPrefix.*"

if ($filesToRename.Count -eq 0) {
    Write-Host "No files found with the prefix '$oldPrefix'." -ForegroundColor Red
    exit
}

Write-Host "The following files will be renamed:"
$filesToRename | ForEach-Object { Write-Host $_.Name }

# Confirm the operation before proceeding
$proceed = Read-Host "Rename all '$oldPrefix.*' files to '$newPrefix.*' in '$PathToDir'? (Y/N)"
if ($proceed -eq "Y" -or $proceed -eq "y") {
    # Rename all matching files without prompting for each one
    $filesToRename | ForEach-Object {
        $newName = $_.Name -replace "^$oldPrefix", $newPrefix
        try {
            Rename-Item $_.FullName -NewName $newName -ErrorAction Stop
            Write-Host "Renamed: $($_.Name) -> $newName" -ForegroundColor Green
        } catch {
            Write-Host "Error renaming '$($_.Name)': $_" -ForegroundColor Red
        }
    }
     
    # List the contents of the folder after renaming
    Write-Host "Renaming complete. New contents of the folder:"
    Get-ChildItem "$PathToDir" | ForEach-Object { Write-Host $_.Name }

} else {
    Write-Host "Operation canceled." -ForegroundColor Red
}
