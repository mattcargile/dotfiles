#Requires -Modules EZOut
[CmdletBinding()]
param (
)
end {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest

    #region Collect formatter Xml
    $formatList = [System.Collections.Generic.List[string]]::new()

    #region Expand-Object
    $typeName = 'MyProfileExpandObject'
    $grpSetCtrlName = "$typeName-GrpSetCtrl"
    $writeFormatControlSplat = @{
        Name = $grpSetCtrlName
        Action = {
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1B)[1;3;34mIndex:$([char]0x1B)[0m " } # Bold;Italics;Blue
            Write-FormatViewExpression -Property Index
            Write-FormatViewExpression -Newline
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1B)[1;3;34mProperty Name:$([char]0x1B)[0m " } # Bold;Italics;Blue
            Write-FormatViewExpression -Property Name
            Write-FormatViewExpression -Newline
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1B)[1;3;34mType Name:$([char]0x1B)[0m " }
            Write-FormatViewExpression -Property TypeName
            Write-FormatViewExpression -Newline
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1B)[1;3;34mProperty ToString:$([char]0x1B)[0m " }
            Write-FormatViewExpression -Property Value
        }
    }
    $formatList.Add( (Write-FormatControl @writeFormatControlSplat) )
    $writeFormatViewSplat = @{
        Name = $typeName
        TypeName = $typeName
        GroupByProperty = 'Name'
        GroupAction = $grpSetCtrlName
        FormatXML = (
            Write-FormatCustomView -Action {
                if ($PSVersionTable.PSVersion -ge [version]'7.3.0') {
                    $_.Value | Format-List -Property * | Out-AnsiFormatting
                }
                else {
                    $_.Value | Format-List -Property * | Out-String
                }
            }
            )
    }

    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    #endregion

    #region ActiveDirectory
    $writeFormatViewSplat = @{
        TypeName = 'Microsoft.ActiveDirectory.Management.ADUser'
        Property = 'SamAccountName', 'DisplayName', 'Enabled', 'LockedOut', 'PasswordExpired', 'Title', 'Office'
        Width = 20, 25, 10, 10, 15, 35, 35
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )
    $writeFormatViewSplat = @{
        TypeName = 'Microsoft.ActiveDirectory.Management.ADComputer'
        Property = 'Name', 'Enabled', 'DistinguishedName'
        Width = 15, 10, 80
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )
    $writeFormatViewSplat = @{
        TypeName = 'Microsoft.ActiveDirectory.Management.ADGroup'
        Property = 'SamAccountName', 'Name', 'GroupCategory', 'GroupScope', 'whenCreated', 'Description'
        Width = 30, 30, 13, 15, 24, 80
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )
    $writeFormatViewSplat = @{
        TypeName = 'Microsoft.ActiveDirectory.Management.ADPrincipal'
        Property = 'ADGroup', 'SamAccountName', 'Name', 'objectClass', 'DistinguishedName'
        Width = 30, 30, 30, 13, 80
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )
    # Search-ADAccount returns this and has ADGroup added
    $writeFormatViewSplat = @{
        TypeName = 'Microsoft.ActiveDirectory.Management.ADAccount'
        Property = 'SamAccountName', 'Name', 'objectClass', 'DistinguishedName'
        Width = 30, 30, 13, 80
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )

    #endregion

    #region CimInstance
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Process'
        Property = 'CSName', 'Pid', 'Name', 'WSMb', 'CPUSec', 'Path'
        Width = 15, 5, 48, 8, 8, 80
        VirtualProperty = @{
            Path = { ConvertTo-CompactPath -Path $_.ExecutablePath -Length 80 -Verbose:$false }
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Process#IncludeUser'
        Property = 'CSName', 'Pid', 'User', 'Name', 'WSMb', 'CPUSec', 'Path'
        Width = 15, 5, 25, 48, 8, 8, 80
        VirtualProperty = @{
            Path = { ConvertTo-CompactPath -Path $_.ExecutablePath -Length 80 -Verbose:$false }
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Process#IncludeCPUPercentage'
        Property = 'CSName', 'Pid', 'Name', 'WSMb', 'CPUSec', 'Path', 'CPUPercentage'
        Width = 15, 5, 48, 8, 8, 80, 13
        VirtualProperty = @{
            Path = { ConvertTo-CompactPath -Path $_.ExecutablePath -Length 80 -Verbose:$false }
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Service'
        Property = 'SystemName', 'Name', 'DisplayName', 'StartMode', 'Started', 'StartName', 'PathName'
        Width = 15, 30, 30, 9, 7, 30, 80
        VirtualProperty = @{
            PathName = { ConvertTo-CompactPath -Path $_.PathName -Length 80 -Verbose:$false }
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )

    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_OperatingSystem'
        Property = 'CSName', 'Caption', 'Uptime'
        Width = 15, 45, 30
        VirtualProperty = @{
            Uptime = { [Humanizer.TimeSpanHumanizeExtensions]::Humanize($_.Uptime, 3) }
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    #endregion

    #region Installed Software
    $writeFormatViewSplat = @{
        TypeName = 'Utility.InstalledSoftware'
        Property = 'Name', 'Publisher', 'DisplayVersion', 'InstallDate'
        Width = 70, 25, 20, 15
        VirtualProperty = @{ InstallDate = { ConvertTo-HumanDate $_.InstallDate } }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    #endregion
    #region Installed Software ComputerName
    $writeFormatViewSplat = @{
        TypeName = 'Utility.InstalledSoftware#IncludeComputerName'
        Property = 'Name', 'Publisher', 'DisplayVersion', 'InstallDate', 'ComputerName'
        Width = 70, 25, 20, 15, 15
        VirtualProperty = @{ InstallDate = { ConvertTo-HumanDate $_.InstallDate } }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    #endregion

    #region Remote Shares
    $writeFormatViewSplat = @{
        TypeName = 'Win32Share.NativeMethods'
        Width = @(15,25,10,10,10)
        Property = 'ComputerName', 'Name', 'Type', 'FreeSpace', 'TotalSpace'
        VirtualProperty = @{
            FreeSpace= { [Humanizer.ByteSizeExtensions]::Humanize($_.TotalFreeBytes, '0.00') }
            TotalSpace={ [Humanizer.ByteSizeExtensions]::Humanize($_.TotalBytes, '0.00') } 
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    #endregion

    #region Command Parameter
    $grpSetCtrlName = 'UtilityCommandParameterInfo.GrpSetCtrl'
    $writeFormatControlSplat = @{
        Name = $grpSetCtrlName
        Action = {
            Write-FormatViewExpression -Text '    Set: '
            Write-FormatViewExpression -ScriptBlock { [ClassExplorer.Internal._Format]::Variable($_.Set) }
            Write-FormatViewExpression -If { $_.IsDefaultSet } -ScriptBlock { ' (Default)' }
            Write-FormatViewExpression -Newline
            Write-FormatViewExpression -Newline
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1b)[90m(# = Position, M = IsMandatory, D = IsDynamic)$([char]0x1b)[0m" }
        }
    }
    $formatList.Add( (Write-FormatControl @writeFormatControlSplat) )

    $writeFormatViewSplat = @{
        TypeName = 'UtilityCommandParameterInfo'
        Name = 'UtilityCommandParameterInfo'
        GroupByProperty = 'Set'
        GroupAction = $grpSetCtrlName
        Width = 2, 1, 1, 14, 25, 40
        AlignProperty = @{ '#' = 'Right' }
        Property = '#', 'M', 'D', 'ValueFrom', 'Type', 'Name', 'Attributes'
        VirtualProperty = @{
            '#' = {
                if ($_.Position -eq [int]::MinValue) { return '' }
                [ClassExplorer.Internal._Format]::Number($_.Position)
            }
            'M' = {[ClassExplorer.Internal._Format]::FancyBool($_.IsMandatory)}
            'D' = {[ClassExplorer.Internal._Format]::FancyBool($_.IsDynamic)}
            'ValueFrom' = {
                (& {
                    if ($_.ValueFromPipeline) {
                        [ClassExplorer.Internal._Format]::MemberName('Pipe')
                    }

                    if ($_.ValueFromPipelineByPropertyName) {
                        [ClassExplorer.Internal._Format]::MemberName('Property')
                    }

                    if ($_.ValueFromRemainingArguments) {
                        [ClassExplorer.Internal._Format]::MemberName('RemainingArgs')
                    }
                }) -join ', '
            }
            'Type' = {[ClassExplorer.Internal._Format]::Type($_.Type)}
            'Name' = {
                if (-not $_.Aliases) {
                    return [ClassExplorer.Internal._Format]::Variable($_.Name)
                }

                $sb = [System.Text.StringBuilder]::new()
                $null = & {
                    # $reset = "$([char]0x1b)[0m"
                    $reset = ''

                    $sb.Append([ClassExplorer.Internal._Format]::Variable($_.Name)).Append($reset).Append(' (')

                    $sb.Append([ClassExplorer.Internal._Format]::Variable($_.Aliases[0]))
                    for ($i = 1; $i -lt $_.Aliases.Count; $i++) {
                        $sb.Append(', ')
                        $sb.Append([ClassExplorer.Internal._Format]::Variable($_.Aliases[$i]))
                    }

                    $sb.Append(')')
                }

                return $sb.ToString()
            }
            'Attributes' = {
                ( & {
                    foreach ($attr in $_.Attributes) {
                        $typeName = $attr.GetType().Name
                        if ($attr.GetType().Name -in [Parameter].Name, 'NullableAttribute') {
                            continue
                        }

                        [ClassExplorer.Internal._Format]::Type($typeName -replace 'Attribute$')
                    }
                } ) -join ', '
            }
        }
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )
    #endregion

    #region System.IO.DirectoryInfo & System.IO.FileInfo
    $grpSetCtrlName = 'HumanFileSystemTypes-GroupingFormat'
    $writeFormatCustomViewSplat = @{
        Name = $grpSetCtrlName
        AsControl = $true
        Frame = $true
        LeftIndent = 4
        Action = {
            Write-FormatViewExpression -AssemblyName 'System.Management.Automation' -BaseName 'FileSystemProviderStrings' -ResourceID 'DirectoryDisplayGrouping'
            Write-FormatViewExpression -ScriptBlock {$_.PSParentPath.Replace("Microsoft.PowerShell.Core\FileSystem::", "")}
            Write-FormatViewExpression -Newline
        }
    }
    $formatList.Add( (Write-FormatCustomView @writeFormatCustomViewSplat) )

    $writeFormatDeserDirInfoNamespace = 'Deserialized.System.IO.DirectoryInfo'
    $writeFormatDeserFileInfoNamespace = 'Deserialized.System.IO.FileInfo'
    $writeFormatDirInfoNamespace = 'System.IO.DirectoryInfo'
    $writeFormatFileInfoNamespace = 'System.IO.FileInfo'
    $writeFormatSelSetName = 'HumanFileSystemTypes'
    $writeFormatSelSetWideName = "${writeFormatSelSetName}Wide"
    $writeFormatViewSplat = @{
        FormatXml = @"
        <SelectionSet>
            <Name>$writeFormatSelSetName</Name>
            <Types>
                <TypeName>$writeFormatDirInfoNamespace</TypeName>
                <TypeName>$writeFormatFileInfoNamespace</TypeName>
                <TypeName>$writeFormatDeserDirInfoNamespace</TypeName>
                <TypeName>$writeFormatDeserFileInfoNamespace</TypeName>
            </Types>
        </SelectionSet>
"@
        TypeName = 'NotApplicable'
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )

    # Get-ChildItemWide.ps1
    $writeFormatViewSplat = @{
        FormatXml = @"
        <SelectionSet>
            <Name>$writeFormatSelSetWideName</Name>
            <Types>
                <TypeName>MacSystem.IO.FileInfoWide</TypeName>
            </Types>
        </SelectionSet>
"@
        TypeName = 'NotApplicable'
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )

    $writeFormatWidth = [Int32[]]@(7, 25, 14)
    $writeFormatAlign = @{
        Mode = 'Left'
        LastWriteTime = 'Right'
        Length = 'Right'
        Name = 'Left'
    }
    $writeFormatLengthSb = {
        if ($_.Attributes.HasFlag( [System.IO.FileAttributes]::Offline) ) {
            "($([Humanizer.ByteSizeExtensions]::Humanize($_.Length, '0.00')))"
        }
        else {
            [Humanizer.ByteSizeExtensions]::Humanize($_.Length, '0.00')
        }
    }
    $writeFormatFileAndDirInfoProperty = 'ModeWithoutHardLink', 'LastWriteTime', 'Length', 'Name'
    $writeFormatFileAndDirInfoAliasProperty = @{
        ModeWithoutHardLink = 'Mode'
    }
    $writeFormatDeserFileAndDirInfoProperty = 'Mode', 'LastWriteTime', 'Length', 'Name'
    $writeFormatDirInfoVirtProp = @{
        LastWriteTime = {ConvertTo-HumanDate $_.LastWriteTime}
        Length = {[string]::Empty}
        Name = {Format-FileSystemInfoName $_}
    }

    $writeFormatTable = @(
        [PSCustomObject]@{
            Property = $writeFormatFileAndDirInfoProperty
            AlignProperty = $writeFormatAlign
            Width = $writeFormatWidth 
            Wrap = $true
            VirtualProperty = @{
                LastWriteTime = {ConvertTo-HumanDate $_.LastWriteTime}
                Length = $writeFormatLengthSb 
                Name = {Format-FileSystemInfoName $_}
            }
            AliasProperty = $writeFormatFileAndDirInfoAliasProperty
        },
        [PSCustomObject]@{
            ViewTypeName = $writeFormatDirInfoNamespace
            Property = $writeFormatFileAndDirInfoProperty 
            AlignProperty = $writeFormatAlign
            Width = $writeFormatWidth 
            Wrap = $true
            VirtualProperty = $writeFormatDirInfoVirtProp
            AliasProperty = $writeFormatFileAndDirInfoAliasProperty
        },
        [PSCustomObject]@{
            ViewTypeName = $writeFormatDeserDirInfoNamespace
            Property = $writeFormatDeserFileAndDirInfoProperty
            AlignProperty = $writeFormatAlign
            Width = $writeFormatWidth 
            Wrap = $true
            VirtualProperty = $writeFormatDirInfoVirtProp
            # Fix for https://github.com/StartAutomating/EZOut/issues/235
            AliasProperty = @{
                Mode = 'Mode'
                Name = 'Name'
            }
        }
    )
    $writeFormatViewSplat = @{
        FormatXml = ( $writeFormatTable | Write-FormatTableView )
        IsSelectionSet = $true
        Name = 'humanchildren'
        TypeName = $writeFormatSelSetName
        GroupByProperty = 'PSParentPath'
        GroupAction = $grpSetCtrlName
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )

    $writeFormatFileInfoProperty = 'Name', 'Length', 'CreationTime', 'LastWriteTime', 'LastAccessTime', 'Mode', 'LinkType', 'Target', 'VersionInfo'
    $writeFormatDirInfoProperty = 'Name', 'CreationTime', 'LastWriteTime', 'LastAccessTime', 'Mode', 'LinkType', 'Target'
    $writeFormatDirInfoVirtProp = @{
        Name = {Format-FileSystemInfoName $_}
        CreationTime = {ConvertTo-HumanDate $_.CreationTime}
        LastWriteTime = {ConvertTo-HumanDate $_.LastWriteTime}
        LastAccessTime = {ConvertTo-HumanDate $_.LastAccessTime}
    }
    $writeListView = @(
        [pscustomobject]@{
            Property = $writeFormatFileInfoProperty 
            VirtualProperty = @{
                Name = {Format-FileSystemInfoName $_}
                Length = $writeFormatLengthSb 
                CreationTime = {ConvertTo-HumanDate $_.CreationTime}
                LastWriteTime = {ConvertTo-HumanDate $_.LastWriteTime}
                LastAccessTime = {ConvertTo-HumanDate $_.LastAccessTime}
            }
        }
        [pscustomobject]@{
            Property = $writeFormatDirInfoProperty 
            ViewTypeName = $writeFormatDeserDirInfoNamespace
            VirtualProperty = $writeFormatDirInfoVirtProp
        },
        [pscustomobject]@{
            Property = $writeFormatDirInfoProperty 
            ViewTypeName = $writeFormatDirInfoNamespace
            VirtualProperty = $writeFormatDirInfoVirtProp 
        }
    )
    
    $writeFormatViewSplat = @{
        IsSelectionSet = $true
        Name = 'humanchildren'
        TypeName = $writeFormatSelSetName
        GroupByProperty = 'PSParentPath'
        GroupAction = $grpSetCtrlName
        FormatXml = ( $writeListView | Write-FormatListView )
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )

    $writeFormatViewSplat = @{
        FormatXML = Write-FormatWideView -ScriptBlock { Format-FileSystemInfoName $_ }
        IsSelectionSet = $true
        Name = 'humanchildren'
        TypeName = $writeFormatSelSetName, $writeFormatSelSetWideName 
        GroupByProperty = 'PSParentPath'
        GroupAction = $grpSetCtrlName
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat))
    #endregion
    #endregion

    #region Output Format Xml
    $formatList | Out-FormatData
    #endregion
}
