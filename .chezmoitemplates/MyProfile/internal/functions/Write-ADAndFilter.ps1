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
    [CmdletBinding(DefaultParameterSetName = 'Like')]
    [OutputType([string])]
    param (
        # The `-Filter` value to add to or return
        [Parameter(ParameterSetName = 'Like', ValueFromPipeline, Position = 2)]
        [Parameter(ParameterSetName = 'EqualTo', ValueFromPipeline, Position = 2)]
        [Parameter(ParameterSetName = 'GreaterThan', ValueFromPipeline, Position = 2)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $Filter,
        # The property to filter on
        [Parameter(ParameterSetName = 'Like', Mandatory, Position = 0)]
        [Parameter(ParameterSetName = 'EqualTo', Mandatory, Position = 0)]
        [Parameter(ParameterSetName = 'GreaterThan', Mandatory, Position = 0)]
        [string]
        $PropertyName,
        # The propery value to check
        [Parameter(ParameterSetName = 'Like', Position = 1)]
        [Parameter(ParameterSetName = 'EqualTo', Position = 1)]
        [Parameter(ParameterSetName = 'GreaterThan', Position = 1)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $PropertyValue,
        # Allow -like override for switch type or bool type properties which don't support -like
        # Forces the PropertyValue to match on the exact string value
        [Parameter(ParameterSetName = 'EqualTo')]
        [switch]
        $EQ,
        # Allow -like override for switch type or bool type properties which don't support -like
        # Forces the PropertyValue to match on the exact string value
        [Parameter(ParameterSetName = 'GreaterThan')]
        [switch]
        $GT
    )
    
    process {
        $baseFilterFormat = "$PropertyName {0} {1}" 
        if ($EQ) {
            $baseFilter = $baseFilterFormat -f '-eq', "'$($PropertyValue -replace "'", "''" )'"
        }
        elseif ($GT) {
            $baseFilter = $baseFilterFormat -f '-gt', "'$($PropertyValue -replace "'", "''" )'"
        }
        else {
            $baseFilter = $baseFilterFormat -f '-like', "`$$PropertyName"
        }
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
