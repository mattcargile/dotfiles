function Get-CharUtfHex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [char]
        $Char
    )
    $charInt = [int][char]$Char
    Write-Verbose -Message "Char is $charInt as Integer."
    Write-Output ( "0x{0:X}" -f $( $charInt ) )
}
