###=================================================================================###
#  Filename: psgrep.ps1
#  
#  Description:
#   Find text in files in the current folder and report the line # and contents. 
#
#  Written By: Karl Vietmeier and ChatGPT                                            
#                                                                            
###=================================================================================###
# Set the current directory as the folder path
$folderPath = Get-Location

# Check if a search string is provided as a command-line argument
if ($args.Count -eq 0) {
    # Prompt the user for the search string
    $searchString = Read-Host "Enter the search text"
} else {
    # Use the provided search string
    $searchString = $args[0]
}

# Search for the string in all files in the current directory, excluding .tfstate files
Get-ChildItem -Path $folderPath -Exclude "*.tfstate" | Select-String -Pattern $searchString | ForEach-Object {
    [PSCustomObject]@{
        FilePath = $_.Path
        LineNumber = $_.LineNumber
        MatchingLine = $_.Line
    }
}