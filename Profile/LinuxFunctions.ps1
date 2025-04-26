###====================================================================================###
<#   
  FileName: LinuxFunctions.ps1
  Created By: Karl Vietmeier
    
  Description:
   Functions and aliases that emulate Linux commands

#>
###====================================================================================###

function df { get-volume }

# Show hidden "." folders
function ll($name) { Get-ChildItemColor -Path . -Force }
function l($name) { Get-ChildItemColorFormatWide -Path . -Force }

function sed($file, $find, $replace){
	(Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function sed_recursive($filePattern, $find, $replace) {
	$files = Get-ChildItem . "$filePattern" -recursive
	foreach ($file in $files) {
		(Get-Content $file.PSPath) | Foreach-Object { $_ -replace "$find", "$replace" } | Set-Content $file.PSPath
	}
}

function grep($regex, $dir) {
	if ( $dir ) {
		Get-ChildItem $dir | select-string $regex
		return
	}
	$input | select-string $regex
}

function grepv($regex) {
	$input | Where-Object { !$_.Contains($regex) }
}

function which($name) {
	Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
	set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
	Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
	Get-Process $name
}

function touch($file) {
	"" | Out-File $file -Encoding ASCII
}

# "cd - not working "
function cddash {
    if ($args[0] -eq '-') {
        $_pwd = $OLDPWD;
    } else {
        $_pwd = $args[0];
    }
    $tmp = Get-Location;

    if ($_pwd) {
        Set-Location $_pwd;
    }
    Set-Variable -Name OLDPWD -Value $tmp -Scope global;
}

# From https://github.com/keithbloom/powershell-profile
# This function runs a specified executable with elevated (administrator) privileges.
function sudo {
    # Capture the file and optional arguments passed to the function
    $file, [string]$arguments = $args;

    # Create a new ProcessStartInfo object for the executable file
    $psi = new-object System.Diagnostics.ProcessStartInfo $file;

    # Set the arguments for the process, if any
    $psi.Arguments = $arguments;

    # Set the verb to "runas" to run the process with administrator privileges
    $psi.Verb = "runas";

    # Set the working directory to the current location
    $psi.WorkingDirectory = get-location;

    # Start the process and redirect output to null
    [System.Diagnostics.Process]::Start($psi) >> $null
}