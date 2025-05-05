###========================== Set colors for dir listings ==========================#
#
#   Put this in your PowerShell profile
#   Configuration for PSColor
#   https://github.com/Davlind/PSColor
#
#   The script defines a PowerShell hash table ($global:PSColor) that 
#   organizes color settings for different types of files and services.
#
#
###=================================================================================#


$global:PSColor = @{
  # Filetypes - 
  File = @{
      Default    = @{ Color = 'White' }
      Directory  = @{ Color = 'blue'}
      Hidden     = @{ Color = 'DarkGray'; Pattern = '^\.' } 
      Code       = @{ Color = 'Magenta'; Pattern = '\.(java|c|cpp|cs|js|css|html|xml|yml|yaml|md|markdown|json)$' }
      Executable = @{ Color = 'Green'; Pattern = '\.(exe|bat|cmd|sh|py|pl|ps1|psm1|vbs|rb|reg)$' }
      Text       = @{ Color = 'Yellow'; Pattern = '\.(docx|doc|ppt|pptx|xls|xlsx|vsdx|vsd|pdf|txt|cfg|conf|ini|csv|log|config)$' }
      Compressed = @{ Color = 'Green'; Pattern = '\.(zip|tar|gz|rar|jar|war|gzip)$' }
  }
  # Services
  Service = @{
      Default = @{ Color = 'White' }
      Running = @{ Color = 'DarkGreen' }
      Stopped = @{ Color = 'DarkRed' }     
  }
  # Colors used when there is a match found in a search or operation
  Match = @{
      Default    = @{ Color = 'White' }
      Path       = @{ Color = 'Cyan'}
      LineNumber = @{ Color = 'Yellow' }
      Line       = @{ Color = 'White' }
  }
  # Colors used when there is no match found
  NoMatch = @{
      Default    = @{ Color = 'White' }
      Path       = @{ Color = 'Cyan'}
      LineNumber = @{ Color = 'Yellow' }
      Line       = @{ Color = 'White' }
  }
}
###==== End Set colors for dir listings ====#
