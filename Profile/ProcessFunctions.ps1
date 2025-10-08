### =========================================================================================
<# 
    FileName: pstree.ps1
    Created By: Karl Vietmeier

    Description:
    A PowerShell function to display the process tree similar to Unix `pstree`.
    Supports:
      - Fancy "branch style" output with ├── and └──
      - Flat indented output
      - Optional filtering by process name
      - Displays PID and CommandLine or process name if no command line available

    Usage Examples:
      pstree                     -> Basic tree
      pstree -Fancy              -> Fancy tree view
      pstree -Name chrome        -> Filtered flat view for "chrome"
      pstree -Fancy -Name explorer -> Fancy view filtered for "explorer"
#>
### =========================================================================================

function pstree {
    [CmdletBinding()]
    param (
        [switch]$Fancy,      # Show output with graphical tree branches
        [string]$Name        # Filter starting processes by name (wildcards allowed)
    )

    # Create hashtable to map PID to process info
    $ProcessesById = @{}
    foreach ($Process in Get-CimInstance Win32_Process) {
        $ProcessesById[$Process.ProcessId] = $Process
    }

    # Build parent-child relationships
    $ProcessesWithoutParents = @{}
    $ProcessesByParent = @{}

    foreach ($Process in $ProcessesById.Values) {
        if (($Process.ParentProcessId -eq 0) -or (-not $ProcessesById.ContainsKey($Process.ParentProcessId))) {
            # No parent found, root process
            $ProcessesWithoutParents[$Process.ProcessId] = $Process
        } else {
            # Add as a child to its parent
            if (-not $ProcessesByParent.ContainsKey($Process.ParentProcessId)) {
                $ProcessesByParent[$Process.ParentProcessId] = @()  # Initialize the array if not present
            }
            $ProcessesByParent[$Process.ParentProcessId] += $Process
        }
    }

    # Flat indented tree output
    function Show-ProcessFlat {
        param ([UInt32]$ProcessId, [int]$Level)

        $Process = $ProcessesById[$ProcessId]
        $Indent = " " * ($Level * 4)
        $Description = if ($Process.CommandLine) { $Process.CommandLine } else { $Process.Caption }
        Write-Output ("{0,6} {1}{2}" -f $Process.ProcessId, $Indent, $Description)

        foreach ($Child in ($ProcessesByParent[$ProcessId] | Sort-Object CreationDate)) {
            Show-ProcessFlat -ProcessId $Child.ProcessId -Level ($Level + 1)
        }
    }
# Fancy graphical tree output
	function Show-ProcessTree {
		param (
			[UInt32]$ProcessId, 
			[string]$Indent = "", 
			[bool]$IsLast = $true
		)

		$Process = $ProcessesById[$ProcessId]
		$Branch = if ($Indent) {
			if ($IsLast) { "$Indent`-- " } else { "$Indent|- " }
		} else { "" }

		$Description = if ($Process.CommandLine) { $Process.CommandLine } else { $Process.Caption }
		Write-Output ("{0,6} {1}{2}" -f $Process.ProcessId, $Branch, $Description)

		$Children = $ProcessesByParent[$ProcessId] | Sort-Object CreationDate
		$ChildCount = $Children.Count
		for ($i = 0; $i -lt $ChildCount; $i++) {
			$Child = $Children[$i]
			$ChildIsLast = ($i -eq ($ChildCount - 1))
			#$NewIndent = $Indent + (if ($IsLast) { "    " } else { "|   " })
			if ($IsLast) {
  				$NewIndent = $Indent + "    "
			} else {
		    	$NewIndent = $Indent + "|   "
			}
			Show-ProcessTree -ProcessId $Child.ProcessId -Indent $NewIndent -IsLast:$ChildIsLast
		}
	}

    # Print header
    Write-Output ("{0,6} {1}" -f "PID", "Command Line")
    Write-Output ("{0,6} {1}" -f "---", "------------")

    # Start from root processes
    $Roots = $ProcessesWithoutParents.Values | Sort-Object CreationDate

    foreach ($Process in $Roots) {
        if ($Name) {
            # If filtering by process name
            if ($Process.Caption -like "*$Name*") {
                if ($Fancy) {
                    Show-ProcessTree -ProcessId $Process.ProcessId
                } else {
                    Show-ProcessFlat -ProcessId $Process.ProcessId -Level 0
                }
            }
        } else {
            # No filter
            if ($Fancy) {
                Show-ProcessTree -ProcessId $Process.ProcessId
            } else {
                Show-ProcessFlat -ProcessId $Process.ProcessId -Level 0
            }
        }
    }
}
