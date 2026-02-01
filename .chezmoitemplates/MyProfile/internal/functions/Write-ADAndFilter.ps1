<#
.SYNOPSIS
Write out string of ActiveDirectory `-Filter` using `-and` logic.

.DESCRIPTION
Write out string for `-Filter` in ActiveDirectory module and handle `-and`.

.EXAMPLE
Write-ADAndFilter -Filter $PSBoundParameters['Filter'] -PropertyName 'Description'
Take the currently bound `-Filter` and add the `-and` if necessary and the `Description -like ``$Description`
and then return the string
#>
function Write-ADAndFilter {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # The `-Filter` value to add to or return
        [Parameter(ValueFromPipeline, Position = 2)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $Filter,
        # The property to filter on
        [Parameter(Mandatory, Position = 0)]
        [string]
        $PropertyName,
        # The propery value to check
        [Parameter(Position = 1)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $PropertyValue
    )
    
    process {
        $baseFilter = "$PropertyName -like `$$PropertyName" 
        if (-not $Filter) {
            Write-Verbose 'Filter is null or empty.'
            if (-not $PropertyValue) {
                Write-Verbose "PropertyValue for the PropertyName ($PropertyName) is empty or null. Immediately returning."
                # Returning Null to allow property pipeling and downstream process blocks to run
                $null
            }
            else {
                $baseFilter
            }
        }
        else {
            Write-Verbose 'Filter has a value.'
            if (-not $PropertyValue) {
                Write-Verbose "PropertyValue for the PropertyName ($PropertyName) is empty or null. Returning the Filter ($Filter)"
                $Filter
            }
            else {
                Write-Verbose 'Filter and PropertyValue has a value return the combination.'
                "$Filter -and $baseFilter"
            }
        }
    }
}
