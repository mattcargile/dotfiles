function Format-FileSystemInfoName {
    <#
    .SYNOPSIS
        Prepend a custom icon (with color) to the provided file or folder object when displayed.
    .DESCRIPTION
        Take the provided file or folder object and look up the appropriate icon and color to display.
    .PARAMETER FileInfo
        The file or folder to display. Must be System.IO.FileSystemInfo or Deserialized variant
    .EXAMPLE
        Get-Item ./README.md | Format-FileSystemInfoName

        Get a file object and pass directly to Format-FileSystemInfoName.
    .INPUTS
        System.IO.FileSystemInfo

        You can pipe an objects that derive from System.IO.FileSystemInfo (System.IO.DIrectoryInfo and System.IO.FileInfo) to 'Format-FileSystemInfoName'.
    .OUTPUTS
        System.String

        Outputs a colorized string with an icon prepended.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    [Alias('ffs','fls', 'fdir')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [psobject]$FileSystemInfo
    )

    begin {
        $fileSystemInfoType = 'System.IO.FileSystemInfo'
        $fileSystemInfoDeserType = "Deserialized.$fileSystemInfoType"
        $colorReset = "$([char]27)[0m"
    }

    process {
        if ($FileSystemInfo -isnot $fileSystemInfoType -and $FileSystemInfo.pstypenames -notcontains $fileSystemInfoDeserType) {
            Write-Error -Message 'Only System.IO.FileSystemInfo and Deserialized variant is supported.' -Category InvalidType
            return
        }
        $displayInfo = Resolve-FileSystemInfoNameFormat -FileSystemInfo $FileSystemInfo
        if ($displayInfo.Icon) {
            "$($displayInfo.Color)$($displayInfo.Icon)  $($FileSystemInfo.Name)$($displayInfo.Target)$($colorReset)"
        } else {
            "$($displayInfo.Color)$($FileSystemInfo.Name)$($displayInfo.Target)$($colorReset)"
        }
    }
}
