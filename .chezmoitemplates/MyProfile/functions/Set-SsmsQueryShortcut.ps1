<#
.SYNOPSIS
Set SQL Server Management Studio (SSMS) query shortcuts.

.DESCRIPTION
This script sets predefined query shortcuts in SQL Server Management Studio (SSMS) by modifying the UserSettings.xml file.

.EXAMPLE
Set-SsmsQueryShortcut
This command will set the predefined query shortcuts in SSMS.

.NOTES
Backup of the UserSettings.xml file is created before modification and saved in the same directory with a timestamp.
#>
function Set-SsmsQueryShortcut {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateSet(22, 21, 20, 19, 18)]
    [int]$Version
  )

  $queryXml = @'
        <Element>
          <Key>
            <int>-1</int>
          </Key>
          <Value>
            <string />
          </Value>
        </Element>
        <Element>
          <Key>
            <int>3</int>
          </Key>
          <Value>
            <string>sp_WhoIsActive @format_output = 2</string>
          </Value>
        </Element>
        <Element>
          <Key>
            <int>4</int>
          </Key>
          <Value>
            <string>sp_BlitzFirst</string>
          </Value>
        </Element>
        <Element>
          <Key>
            <int>5</int>
          </Key>
          <Value>
            <string>SELECT TOP (100) * FROM </string>
          </Value>
        </Element>
        <Element>
          <Key>
            <int>6</int>
          </Key>
          <Value>
            <string>sp_helpme </string>
          </Value>
        </Element>
        <Element>
          <Key>
            <int>7</int>
          </Key>
          <Value>
            <string>sp_BlitzWho</string>
          </Value>
        </Element>
        <Element>
          <Key>
            <int>8</int>
          </Key>
          <Value>
            <string>sp_WhoIsActive @format_output = 2 , @get_plans = 1 , @get_outer_command = 1 , @find_block_leaders = 1 , @sort_order = N'[blocked_session_count] DESC, [start_time]'</string>
          </Value>
        </Element>
        <Element>
          <Key>
            <int>9</int>
          </Key>
          <Value>
            <string>sp_WhoIsActive @format_output = 2 , @show_sleeping_spids = 2</string>
          </Value>
        </Element>
        <Element>
          <Key>
            <int>0</int>
          </Key>
          <Value>
            <string />
          </Value>
        </Element>
'@

  $ssmsUserSettingsDirectory = "$env:APPDATA\Microsoft\SQL Server Management Studio\$Version.0" 
  $ssmsUserSettingsFile = Join-Path $ssmsUserSettingsDirectory "UserSettings.xml"
  $ssmsUserSettingsBackupFile = Join-Path $ssmsUserSettingsDirectory "UserSettings_backup_$(Get-Date -Format "yyyyMMdd_HHmmssfff").xml"
  Copy-Item $ssmsUserSettingsFile $ssmsUserSettingsBackupFile 
  Write-Verbose "Backup of UserSettings.xml created at $ssmsUserSettingsBackupFile"

  [xml]$xmlDoc = Get-Content $ssmsUserSettingsFile
  $qeSettings = $xmlDoc.SqlStudio.SSMS.QueryExecution;
  $queryShortcutsElement = $qeSettings.SelectSingleNode('QueryShortcuts')
  if (-not $queryShortcutsElement) {
    Write-Error "Cannot find Query Shortcuts element. Xml Schema might have changed."
    return
  }
  $queryShortcutsElement.InnerXml = $queryXml
  $xmlDoc.Save($ssmsUserSettingsFile)
  Write-Verbose "SSMS query shortcuts have been set successfully."
}
