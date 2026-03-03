function Find-MemberLast {
    [CmdletBinding()]
    [Alias('fimel')]
    param (
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
            $global:__ | ClassExplorer\Find-Member | Out-Paging
        }
        else {
            $global:__ | ClassExplorer\Find-Member
        }
    }
}
