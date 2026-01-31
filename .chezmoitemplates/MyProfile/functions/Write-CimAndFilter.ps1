<#
.SYNOPSIS
Write the applicable `Get-CimInstance` `-Filter

.DESCRIPTION
Write the applicable `Get-CimInstance` `-Filter` while handling empty values. 

.EXAMPLE
Write-CimFilter -Filter $null -ProperyName Name -PropertyValue 'pwsh.exe'
Output the the filter `Name LIKE 'pwsh.exe'`
#>
function Write-CimFilter {
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
        # The propery value to check. Upon multiple values they are separated by an OR
        [Parameter(Position = 1)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]
        $PropertyValue,
        # Escape PropertyValue characters like backslash and single quotes
        [Parameter()]
        [switch]
        $Escape,
        # Use exclusionary NOT filter. Uses AND in the predicate
        [Parameter()]
        [switch]
        $Not
    )
    
    process {
        $baseFilterPartial = "$PropertyName LIKE '"
        $baseFilterPredicateSeparator = 'OR'
        if ($Not) {
            $baseFilterPartial = "NOT $baseFilterPartial"
            $baseFilterPredicateSeparator = 'AND'
        }
        $baseFilterFormatJoin = "' $baseFilterPredicateSeparator $baseFilterPartial"
        $baseFilterFormatPrefix = "($baseFilterPartial"
        $baseFilterFormatSuffix = ''')'
        $hasPropertyValue = $null -ne $PropertyValue -and $PropertyValue -ne ''
        $currentFilter = $null
        if ($hasPropertyValue) {
            if ($Escape) {
                $PropertyValue = $PropertyValue | ConvertTo-CimEscapedFilterValue
            }
            $currentFilter = "$baseFilterFormatPrefix$($PropertyValue -join $baseFilterFormatJoin)$baseFilterFormatSuffix"
        }
        if (-not $Filter) {
            Write-Verbose 'Filter is null or empty.'
            Write-Verbose "PropertyValue for the PropertyName ($PropertyName) is '$PropertValue'"
            # May return Null to allow property pipeling and downstream process blocks to run
            $currentFilter
        }
        else {
            Write-Verbose 'Filter has a value.'
            if (-not $hasPropertyValue) {
                Write-Verbose "PropertyValue for the PropertyName ($PropertyName) is empty or null. Returning the Filter ($Filter)"
                $Filter
            }
            else {
                Write-Verbose 'Filter and PropertyValue has a value so return the combination.'
                "$Filter AND $currentFilter"
            }
        }
        
    }
}
