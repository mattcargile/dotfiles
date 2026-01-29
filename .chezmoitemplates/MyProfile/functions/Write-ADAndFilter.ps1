<#
.SYNOPSIS
Write out string of ActiveDirectory `-Filter` using `-and` logic.

.DESCRIPTION
Write out string for `-Filter` in ActiveDirectory module and handle `-and`.

.EXAMPLE
Write-ADAndFilter -CurrentFilter $PSBoundParameters['Filter'] -PropertyName 'Description'
Take the currently bound `-Filter` and add the `-and` if necessary and the `Description -like ``$Description`
and then return the string
#>
function Write-ADAndFilter {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # The `-Filter` value to add to or return
        [Parameter(ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $CurrentFilter,
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
        if (-not $CurrentFilter) {
            Write-Verbose 'Current filter is null or empty.'
            if (-not $PropertyValue) {
                Write-Verbose "PropertyValue for the PropertyName ($PropertyName) is empty or null. Immediately returning."
                # Returning Null to allow property pipeling and downstream process blocks to run
                $null
            }
            else {
                "$baseFilter"
            }
        }
        else {
            Write-Verbose 'Current filter has a value.'
            if (-not $PropertyValue) {
                Write-Verbose "PropertyValue for the PropertyName ($PropertyName) is empty or null. Returning the CurrentFilter ($CurrentFilter)"
                $CurrentFilter
            }
            else {
                Write-Verbose 'CurrentFilter and PropertyValue has a value return the combination.'
                "$CurrentFilter -and $baseFilter"
            }
        }
    }
}
