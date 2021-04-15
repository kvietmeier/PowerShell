# Modify .gitconfig to use proxy
$option = [System.StringSplitOptions]::RemoveEmptyEntries
if (Test-Path .\.gitconfig)
{
    Write-Host "Using git"
    foreach($line in Get-Content -Path .\.gitconfig)
    {
        $result = $line.split("=",1,$option)
        #if ($result -eq "#proxy"){ Write-Host $result}
        #Write-Host $result
    } 
    #set-content foo.txt
}
else { Write-Host "No git" }