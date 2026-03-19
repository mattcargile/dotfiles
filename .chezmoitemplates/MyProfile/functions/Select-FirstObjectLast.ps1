function Select-FirstObjectLast {
    [CmdletBinding()]
    [Alias('firstl', 'topl')]
    param (
        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Count = 1,
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
            $global:__ | Select-FirstObject -Count $Count | Out-Paging
        }
        else {
            $global:__ | Select-FirstObject -Count $Count
        }
    }
}

