#Requires -Modules EZOut
[CmdletBinding()]
param (
)
end {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest

    #region Collect formatter Xml
    $formatList = [System.Collections.Generic.List[string]]::new()

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

    $writeFormatWidth = [Int32[]]@(7, 25, 14)
    $writeFormatAlign = @{
        Mode = 'Left'
        LastWriteTime = 'Right'
        Length = 'Right'
        Name = 'Left'
    }
    $writeFormatLengthSb = {
        if ($_.Attributes -is [System.IO.FileAttributes] -and $_.Attributes.HasFlag( [System.IO.FileAttributes]::Offline) ) {
            "($($_.Length | ConvertTo-HumanByteSize '0.00'))"
        }
        else {
            $_.Length | ConvertTo-HumanByteSize '0.00'
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
        TypeName = $writeFormatSelSetName
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
