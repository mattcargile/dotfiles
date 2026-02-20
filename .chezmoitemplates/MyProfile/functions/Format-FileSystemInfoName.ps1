function Format-FileSystemInfoName {
    <#
    .SYNOPSIS
        Prepend a custom icon (with color) to the provided file or folder object when displayed.
    .DESCRIPTION
        Take the provided file or folder object and look up the appropriate icon and color to display.
    .PARAMETER FileInfo
        The file or folder to display
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
        [IO.FileSystemInfo]$FileInfo
    )

    begin {
        $colorReset = "$([char]27)[0m"
    }

    process {
        $displayInfo = Resolve-FileSystemInfoNameFormat -FileInfo $FileInfo
        if ($displayInfo.Icon) {
            "$($displayInfo.Color)$($displayInfo.Icon)  $($FileInfo.Name)$($displayInfo.Target)$($colorReset)"
        } else {
            "$($displayInfo.Color)$($FileInfo.Name)$($displayInfo.Target)$($script:colorReset)"
        }
    }
}
