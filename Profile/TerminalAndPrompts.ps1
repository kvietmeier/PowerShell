###====================================================================================###
<#   
  FileName:  TerminalAndPrompts.ps1
  Created By: Karl Vietmeier
    
  Description:
    Terminal and Prompt mods

#>
###====================================================================================###


###====================================================================================================###
###--- Terminal related
###====================================================================================================###

# Open a Windows Terminal as Admin
function AdminTerminal { powershell "Start-Process -Verb RunAs cmd.exe '/c start wt.exe  -p ""Windows PowerShell""'" }
Set-Alias tadmin AdminTerminal

###==== Set colors for dir listings ====#
# Configuration for PSColor
# https://github.com/Davlind/PSColor
$global:PSColor = @{
  File = @{
      Default    = @{ Color = 'White' }
      Directory  = @{ Color = 'blue'}
      Hidden     = @{ Color = 'DarkGray'; Pattern = '^\.' } 
      Code       = @{ Color = 'Magenta'; Pattern = '\.(java|c|cpp|cs|js|css|html|xml|yml|yaml|md|markdown|json)$' }
      Executable = @{ Color = 'Green'; Pattern = '\.(exe|bat|cmd|sh|py|pl|ps1|psm1|vbs|rb|reg)$' }
      Text       = @{ Color = 'Yellow'; Pattern = '\.(docx|doc|ppt|pptx|xls|xlsx|vsdx|vsd|pdf|txt|cfg|conf|ini|csv|log|config)$' }
      Compressed = @{ Color = 'Green'; Pattern = '\.(zip|tar|gz|rar|jar|war|gzip)$' }
  }
  Service = @{
      Default = @{ Color = 'White' }
      Running = @{ Color = 'DarkGreen' }
      Stopped = @{ Color = 'DarkRed' }     
  }
  Match = @{
      Default    = @{ Color = 'White' }
      Path       = @{ Color = 'Cyan'}
      LineNumber = @{ Color = 'Yellow' }
      Line       = @{ Color = 'White' }
  }
NoMatch = @{
      Default    = @{ Color = 'White' }
      Path       = @{ Color = 'Cyan'}
      LineNumber = @{ Color = 'Yellow' }
      Line       = @{ Color = 'White' }
  }
}
###==== End Set colors for dir listings ====#

###==== Make history act like bash history - sort of ====#
<# 
  https://github.com/PowerShell/PowerShell/issues/12061
  This will format (Get-PSReadLineOption).HistorySavePath so that the multiline commands
  (like when you paste in a function) appear as a single function. It will then allow you 
  to search across your history. 
  You can do something like Select -Expand Command once
  you find what you are looking for and itll display the whole command.
#>
function Format-PSReadLineHistory {
  $historyList = [System.Collections.ArrayList]::new()
  $history = $(Get-Content (Get-PSReadLineOption).HistorySavePath)
  $i = 0
  while( $i -lt $($history.Length - 1) ){
      # If it ends in a backtic then the command continues onto the next line
      if( $history[$i] -match "``$" ){
          $commands = [System.Collections.ArrayList]::new()
          $commands.Add($history[$i].Replace('`','')) | Out-Null
          $i++
          while($history[$i] -match "``$"){
              $commands.Add($history[$i].Replace('`','')) | Out-Null 
              $i++       
          }
          $commands.Add($history[$i].Replace('`','')) | Out-Null
          $i++
          # Now we join it all together with newline characters
          $command = $commands -join "`n"
          $historyList.Add([pscustomobject]@{
          Number = $i + 1
              Command = $command
        }) | Out-Null
      } else {
          $historyList.Add([pscustomobject]@{
          Number = $i + 1
              Command = $history[$i]
        }) | Out-Null
          $i++  
      }                           
  }
  return $historyList
} 

function Get-PSReadLineHistory {
  [CmdletBinding()]
  [Alias('gph')]
  param()
  Format-PSReadLineHistory | Format-Table -HideTableHeaders -AutoSize
}
Set-Alias hist Get-PSReadLineHistory

function Find-PSReadLineHistory {
  [CmdletBinding()]
  [Alias('fph')]
  param([parameter(Position=0)]$keyword)
  Format-PSReadLineHistory | Where-Object { $($_.Command.Replace('`n','; ')) -match $keyword } | Format-Table -HideTableHeaders -AutoSize 
}
Set-Alias searchhist Get-PSReadLineHistory


###====================================================================================================###
###--- Prompt mods
###====================================================================================================###

function prompt
{
  $color = "Cyan"
  
  # Emulate standard PS prompt with location followed by ">"
  Write-Host ("KV " + $(Get-Location) +">") -NoNewLine -ForegroundColor $Color
  
  return " "

  # Don't know what this does - 
  #$out = "PS $loc> "
  #$loc   = Get-Location
  #$out += "$([char]27)]9;12$([char]7)"
  #
  #if ($loc.Provider.Name -eq "FileSystem") {
  #  $out += "$([char]27)]9;9;`"$($loc.Path)`"$([char]7)"
  #}
  #
  #return $out

}
