<#
.SYNOPSIS
Shorten a path to a friendly viewing

.DESCRIPTION
Shortens a path with ellipse so you can more easily see the beginning and the end of the path

.EXAMPLE
ConvertTo-CompactPath -Path 'C:\Users\matt' -Length 5
Converts the path to be only 5 characters long

.NOTES
Can use to convert full command lines
#>
function ConvertTo-CompactPath {
    [CmdletBinding()]
    [Alias('ctcpt')]
    param (
        # Path or command line to compact
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [string[]]
        $Path,
        # Length of the final string.
        # Defaults to 80 as max formatter table column width in EZOut.
        [Parameter()]
        [int]
        $Length = 80
    )
    
    begin {
        $shl = New-CtypesLib Shlwapi.dll
    }
    
    process {
        foreach ($currentPath in $Path) {
            $currentProviderPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath( $currentPath )
            $outCharArray = [char[]]::new($Length)
            $res = $shl.CharSet('Unicode').SetLastError().Returns([bool]).PathCompactPathEx( $outCharArray, $currentProviderPath, $Length, 0)

            if (-not $res) {
                $exp = [System.ComponentModel.Win32Exception]::new($shl.LastError)
                $err = [System.Management.Automation.ErrorRecord]::new(
                    $exp,
                    'FailedToCompactPath',
                    "NotSpecified",
                    $currentPath
                )
                $err.ErrorDetails = "Failed to compact path for '{0}' (0x{1:X8}): {2}" -f @(
                    $currentPath, $exp.NativeErrorCode, $exp.Message
                )
                $PSCmdlet.WriteError($err)
                continue
            }
            [string]::new($outCharArray)
        }
        
    }
}
