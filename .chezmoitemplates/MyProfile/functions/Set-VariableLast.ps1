function Set-VariableLast {
    [CmdletBinding()]
    [Alias('svl')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [Alias('n', 'nm')]
        $Name,
        [Parameter()]
        [Alias('p', 'pa')]
        [switch]
        $PassThru
    )

    begin {
        if ($global:PSDefaultParameterValues['Out-Default:OutVariable'] -ne '__') {
            throw 'Out-Default -OutVariable not set as __ in global scope'
        }
    }

    process {
        if ( $Global:__ -isnot [System.ICloneable]) {
            Write-Warning "Cannot clone the last variable because it doesn't implement 'ICloneable'"
            return
        }
        $cloned = $Global:__.Clone()
        $cloneIsList = $cloned -is [System.Collections.ICollection] -or $cloned -is [System.Collections.IEnumerable] -or $cloned -is [System.Collections.IList]
        if ($cloneIsList -and $cloned.Count -eq 1) {
            $cloned = $cloned[0]
        }
        Set-Variable -Name $Name -Value $cloned -Scope Global -PassThru:$PassThru 
    }
}
