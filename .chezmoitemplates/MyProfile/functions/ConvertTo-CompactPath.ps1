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
        # Minimum to display is the three ellipses. Max is the
        # maximum of a command line.
        [Parameter()]
        [ValidateRange(3, 32768)]
        [int]
        $Length = 80,
        # Convert unresolved PS Paths to provider paths
        # Uses `GetUnresolvedProviderPathFromPSPath`
        [Parameter()]
        [Alias('pp', 'ppfp')]
        [switch]
        $ProviderPathFromPSPath
    )
    
    begin {
        $shl = New-CtypesLib Shlwapi.dll
    }
    
    process {
        foreach ($currentPath in $Path) {
            try {
                if ($ProviderPathFromPSPath) {
                    $currentPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath( $currentPath )
                }
            }
            catch {
                Write-Error -ErrorRecord $_
                continue
            }

            if ($currentPath.Length -lt $Length) {
                Write-Verbose "Path ($currentPath) is shorter than Length ($Length). Returning Path as is."
                $currentPath
                continue
            }
            # Single null character always added to end
            # And null characters are used as padding
            else {
                $Length += 1
            }
            
            $outCharArray = [char[]]::new($Length)
            # Not setting last error as it returns a bool
            $res = $shl.CharSet('Unicode').Returns([bool]).PathCompactPathExW( $outCharArray, $currentPath, $Length, 0)

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
            # Null 0 character at end managles Out-Pager output
            [string]::new($outCharArray, 0, $outCharArray.Length - 1)
        }
        
    }
}
