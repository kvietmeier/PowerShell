###=================================================================================###
<# 
  Filename: Add a folder to the system path
  
  Description:
  
  Written By: ChatGPT
  
#>
###=================================================================================###


$scriptPath = "C:\Users\karl.vietmeier\repos\PowerShell"  # Change this to your actual folder
$envPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if ($envPath -notlike "*$scriptPath*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$scriptPath", "Machine")
    Write-Host "Added '$scriptPath' to system PATH. Restart your session for changes to take effect." -ForegroundColor Green
} else {
    Write-Host "'$scriptPath' is already in the system PATH." -ForegroundColor Yellow
}
