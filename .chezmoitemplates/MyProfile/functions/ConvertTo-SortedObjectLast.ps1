function ConvertTo-SortedObjectLast {
    [CmdletBinding()]
    [Alias('Sort-ObjectLast', 'sortl', 'ctsort', 'ctsol')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [Alias('pr')]
        [object[]]
        $Property,
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
            $global:__ | Sort-Object -Property $Property | Out-Paging
        }
        else {
            $global:__ | Sort-Object -Property $Property
        }
    }
}
