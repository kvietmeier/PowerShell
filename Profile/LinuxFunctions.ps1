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

# "cd -"
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
function sudo {
	$file, [string]$arguments = $args;
	$psi = new-object System.Diagnostics.ProcessStartInfo $file;
	$psi.Arguments = $arguments;
	$psi.Verb = "runas";
	$psi.WorkingDirectory = get-location;
	[System.Diagnostics.Process]::Start($psi) >> $null
}
