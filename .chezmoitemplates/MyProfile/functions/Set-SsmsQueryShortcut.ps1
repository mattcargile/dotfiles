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

    # Appears the ending commit hash is used in the folder name
    $ssmsSettingsDirectoryWildcard = "$env:LOCALAPPDATA\Microsoft\SSMS\$Version.0_*"
    $ssmsUserSettingsDirectory = "$env:APPDATA\Microsoft\SQL Server Management Studio\$Version.0" 
    $ssmsUserSettingsFile = Join-Path $ssmsUserSettingsDirectory 'UserSettings.xml'

    try {
        [xml]$xmlDoc = Get-Content $ssmsUserSettingsFile -Raw -ErrorAction Stop
    }
    catch {
        Write-Error -ErrorRecord $_
        return
    }

    $qeSettings = $xmlDoc.SqlStudio.SSMS.QueryExecution
    if (-not $qeSettings) {
        try {
            $ssmsSettingsDirectory = Resolve-Path $ssmsSettingsDirectoryWildcard -ErrorAction Stop
            if ($ssmsSettingsDirectory.Count -ne 1) {
                Write-Error "Cannot find $ssmsSettingsDirectoryWildcard or there was multiple paths resolved." -Category InvalidResult
                return
            }
            $ssmsSettingsFile = Join-Path $ssmsSettingsDirectory[0].Path 'settings.json'
            if (-not (Test-Path $ssmsSettingsFile)) {
                Write-Error "Cannot find $ssmsSettingsFile" -Category ObjectNotFound
                return
            }
            # Uses jsonc where the first line has a comment describing the file
            $jsonDoc = Get-Content -LiteralPath $ssmsSettingsFile | Select-Object -Skip 1 | ConvertFrom-Json -Depth 10 -ErrorAction Stop
            $jsonKeyName = 'environment.keyboard.queryShortcuts.shortcuts'
            if (-not $jsonDoc.$jsonKeyName) {
                $jsonDoc | Add-Member $jsonKeyName $null
            }
            $jsonDoc.$jsonKeyName = @(
                @{
                    key = '-2'
                    storedProcedure = 'sp_help'
                }
                @{
                    key = '-1'
                    storedProcedure = ''
                }
                @{
                    key = '1'
                    storedProcedure = 'sp_who'
                }
                @{
                    key = '2'
                    storedProcedure = 'sp_lock'
                }
                @{
                    key = '3'
                    storedProcedure = 'sp_WhoIsActive'
                }
                @{
                  key = '4'
                  storedProcedure = 'sp_BlitzFirst'
                }
                @{
                  key = '5'
                  storedProcedure = 'SELECT TOP (100) * FROM '
                }
                @{
                  key = '6'
                  storedProcedure = 'sp_helpme '
                }
                @{
                  key = '7'
                  storedProcedure = 'sp_BlitzWho'
                }
                @{
                  key = '8'
                  storedProcedure = 'sp_WhoIsActive @format_output = 2 , @get_plans = 1 , @get_outer_command = 1 , @find_block_leaders = 1 , @sort_order = N''[blocked_session_count] DESC, [start_time]'''
                }
                @{
                   key = '9'
                   storedProcedure = 'sp_WhoIsActive @format_output = 2 , @show_sleeping_spids = 2'
                },
                @{
                   key = '0'
                   storedProcedure = ''
                }
            )
            $ssmsUserBackupFile = Join-Path $ssmsSettingsDirectory "settings_backup_$(Get-Date -Format "yyyyMMdd_HHmmssfff").json"
            Copy-Item $ssmsSettingsFile $ssmsUserSettingsBackupFile -ErrorAction Stop
            Write-Verbose "Backup of settings.json created at $ssmsUserBackupFile"
            $jsonDoc | ConvertTo-Json -Depth 10 -ErrorAction Stop | Set-Content $ssmsSettingsFile -NoNewLine
        }
        catch {
            Write-Error -ErrorRecord $_
            return
        }

    }
    else {
        try {
            $queryShortcutsElement = $qeSettings.SelectSingleNode('QueryShortcuts')
            $ssmsUserSettingsBackupFile = Join-Path $ssmsUserSettingsDirectory "UserSettings_backup_$(Get-Date -Format "yyyyMMdd_HHmmssfff").xml"
            Copy-Item $ssmsUserSettingsFile $ssmsUserSettingsBackupFile -ErrorAction Stop
            Write-Verbose "Backup of UserSettings.xml created at $ssmsUserSettingsBackupFile"
            if (-not $queryShortcutsElement) {
                Write-Error "Cannot find Query Shortcuts element. Xml Schema might have changed."
                return
            }
            $queryShortcutsElement.InnerXml = $queryXml
            $xmlDoc.Save($ssmsUserSettingsFile)

        }
        catch {
            Write-Error -ErrorRecord $_
            return
        }
    }
}
