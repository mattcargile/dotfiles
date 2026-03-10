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
    $typeName = 'MyProfileLib.ExpandObject'
    $grpSetCtrlName = "$typeName-GrpSetCtrl"
    $writeFormatControlSplat = @{
        Name = $grpSetCtrlName
        Action = {
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1B)[1;3;34mIndex:$([char]0x1B)[0m " } # Bold;Italics;Blue
            Write-FormatViewExpression -Property Index
            Write-FormatViewExpression -Newline
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1B)[1;3;34mProperty Name:$([char]0x1B)[0m " }
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

    #region CimInstance
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Process'
        Property = 'CSName', 'Pid', 'Name', 'WSMb', 'CPUSec', 'Path'
        Width = 15, 5, 48, 13, 13, 80
        VirtualProperty = @{
            Path = { ConvertTo-CompactPath -Path $_.ExecutablePath -Length 80 -Verbose:$false }
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Process#IncludeUser'
        Property = 'CSName', 'Pid', 'User', 'Name', 'WSMb', 'CPUSec', 'Path'
        Width = 15, 5, 25, 48, 13, 13, 80
        VirtualProperty = @{
            Path = { ConvertTo-CompactPath -Path $_.ExecutablePath -Length 80 -Verbose:$false }
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Process#IncludeCPUPercentage'
        Property = 'CSName', 'Pid', 'Name', 'WSMb', 'CPUSec', 'Path', 'CPUPercentage'
        Width = 15, 5, 48, 13, 13, 80, 13
        VirtualProperty = @{
            Path = { ConvertTo-CompactPath -Path $_.ExecutablePath -Length 80 -Verbose:$false }
        }
    }
    $formatList.Add( ( Write-FormatView @writeFormatViewSplat ) )
    $writeFormatViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Process#IncludeUserAndCPUPercentage'
        Property = 'CSName', 'Pid', 'User', 'Name', 'WSMb', 'CPUSec', 'Path', 'CPUPercentage'
        Width = 15, 5, 25, 48, 13, 13, 80, 13
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
    $gcpBaseTypeName = 'MyProfileLib.CommandParameterInfo'
    $grpSetCtrlName = "$gcpBaseTypeName.GrpSetCtrl"
    $writeFormatControlSplat = @{
        Name = $grpSetCtrlName
        Action = {
            Write-FormatViewExpression -Text '    Set: '
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1B)[38;2;124;220;254m$($_.Set)$([char]0x1B)[0m" } #7CDCFE Variable
            Write-FormatViewExpression -If { $_.IsDefaultSet } -ScriptBlock { ' (Default)' }
            Write-FormatViewExpression -Newline
            Write-FormatViewExpression -Newline
            Write-FormatViewExpression -ScriptBlock { "$([char]0x1b)[90m(# = Position, M = IsMandatory, D = IsDynamic)$([char]0x1b)[0m" }
        }
    }
    $formatList.Add( (Write-FormatControl @writeFormatControlSplat) )

    $writeFormatViewSplat = @{
        TypeName = $gcpBaseTypeName
        Name = $gcpBaseTypeName
        GroupByProperty = 'Set'
        GroupAction = $grpSetCtrlName
        Width = 2, 1, 1, 14, 25, 40
        AlignProperty = @{ '#' = 'Right' }
        Property = '#', 'M', 'D', 'ValueFrom', 'Type', 'Name', 'Attributes'
        VirtualProperty = @{
            '#' = {
                if ($_.Position -eq [int]::MinValue) { return '' }
                "$([char]0x1B)[38;2;147;206;168m$($_.Position)$([char]0x1B)[0m" #93CEA8 Number
            }
            'M' = {
                $esc = [char]0x1B
                $reset = "$esc[0m"
                $chkMark = "$esc[92m$([char]0x2713)"
                $xMark = "$esc[91mx"
                if ($_.IsMandatory) { "$chkMark$reset" }
                else { "$xMark$reset" }
            }
            'D' = {
                $esc = [char]0x1B
                $reset = "$esc[0m"
                $chkMark = "$esc[92m$([char]0x2713)"
                $xMark = "$esc[91mx"
                if ($_.IsDynamic) { "$chkMark$reset" }
                else { "$xMark$reset" }
            }
            'ValueFrom' = {
                (& {
                    $esc = [char]0x1B
                    $reset = "$esc[0m"
                    $memberColor = "$esc[38;2;228;228;228m" #E4E4E4 Member
                    if ($_.ValueFromPipeline) {
                        "${memberColor}Pipe$reset"
                    }

                    if ($_.ValueFromPipelineByPropertyName) {
                        "${memberColor}Property$reset"
                    }

                    if ($_.ValueFromRemainingArguments) {
                        "${$memberColor}RemainingArgs$reset"
                    }
                }) -join ', '
            }
            'Type' = {"$([char]0x1B)[38;2;78;201;176m$($_.Type)"} #4EC9B0 Type
            'Name' = {
                $esc = [char]0x1B
                $reset = "$esc[0m"
                $varColor = "$esc[38;2;124;220;254m" #7CDCFE Variable
                if (-not $_.Aliases) {
                    return "$varColor$($_.Name)$reset"
                }

                $sb = [System.Text.StringBuilder]::new()
                $null = & {
                    $sb.Append($_.Name).Append(' (')

                    $sb.Append($_.Aliases[0])
                    for ($i = 1; $i -lt $_.Aliases.Count; $i++) {
                        $sb.Append(', ')
                        $sb.Append($_.Aliases[$i])
                    }

                    $sb.Append(')')
                }

                return "$varColor$($sb.ToString())$reset"
            }
            'Attributes' = {
                "$([char]0x1B)[38;2;78;201;176m$(
                    ( & {
                    foreach ($attr in $_.Attributes) {
                        if ($attr.GetType().Name -in [Parameter].Name, 'NullableAttribute') {
                            continue
                        }
                        $attr.GetType().Name -replace 'Attribute$'
                    }
                } ) -join ', ')$([char]0x1B)[0m" #4EC9B0 Type
            }
        }
    }
    $formatList.Add( (Write-FormatView @writeFormatViewSplat) )
    #endregion

    #region FileSystemInfo Wide

    $writeFormatSelSetName = 'HumanFileSystemTypes'
    $writeFormatSelSetWideName = "${writeFormatSelSetName}Wide"
    $grpSetCtrlName = "$writeFormatSelSetWideName-GroupingFormat"
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
    $writeFormatViewSplat = @{
        FormatXML = Write-FormatWideView -ScriptBlock { Format-FileSystemInfoName $_ }
        IsSelectionSet = $true
        Name = 'humanchildrenwide'
        TypeName = $writeFormatSelSetWideName 
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

