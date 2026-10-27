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
        $baseFilterFormatSuffix = ''' )'
        if ($Not) {
            $baseFilterPartial = "NOT $baseFilterPartial"
            $baseFilterPredicateSeparator = 'AND'
            $baseFilterFormatSuffix = "' OR $PropertyName IS NULL )"
        }
        $baseFilterFormatJoin = "' $baseFilterPredicateSeparator $baseFilterPartial"
        $baseFilterFormatPrefix = "( $baseFilterPartial"
        $hasPropertyValue = $null -ne $PropertyValue -and $PropertyValue -ne ''
        $currentFilter = $null
        if ($hasPropertyValue) {
            if ($Escape) {
                $PropertyValue = $PropertyValue | ConvertTo-CimEscapedFilterValue
            }
            $currentFilter = "$baseFilterFormatPrefix$($PropertyValue -join $baseFilterFormatJoin)$baseFilterFormatSuffix"
        }
        if (-not $Filter) {
            Write-Debug "Filter is null/empty. Returning current filter. PropertyName:'$PropertyName' | PropertyValue:'$PropertyValue'"
            # May return Null to allow property pipeling and downstream process blocks to run
            $currentFilter
        }
        else {
            if (-not $hasPropertyValue) {
                Write-Debug "PropertyValue is null/empty. Returning Filter. PropertyName:'$PropertyName'"
                $Filter
            }
            else {
                "$Filter AND $currentFilter"
            }
        }
        
    }
}
