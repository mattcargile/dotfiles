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
        Set-Variable -Name $Name -Value ($global:__.Clone()) -Scope Global -PassThru:$PassThru 
    }
}