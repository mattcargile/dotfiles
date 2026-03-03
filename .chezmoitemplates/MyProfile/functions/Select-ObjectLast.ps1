function Select-ObjectLast {
    [CmdletBinding()]
    [Alias('selectl', 'sell', 'scl')]
    param (
        [Parameter(Position = 0)]
        [Alias('pr')]
        [object[]]
        $Property = '*',
        [Parameter()]
        [Alias('p', 'pa')]
        [switch]
        $Pager
    )

    begin {
        if ($global:PSDefaultParameterValues['Out-Default:OutVariable'] -ne '__') {
            throw 'Out-Default -OutVariable not set as __ in global scope'
        }
    }

    process {
        if ($Pager) {
            $global:__ | Select-Object -Property $Property | Out-Paging
        }
        else {
            $global:__ | Select-Object -Property $Property
        }
    }
}
