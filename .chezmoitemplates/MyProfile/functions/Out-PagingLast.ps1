function Out-PagingLast {
    [CmdletBinding()]
    [Alias('opl')]
    param (
    )

    begin {
        if ($global:PSDefaultParameterValues['Out-Default:OutVariable'] -ne '__') {
            throw 'Out-Default -OutVariable not set as __ in global scope'
        }
    }
    process {
        $global:__ | Out-Paging
    }
}