<#
.SYNOPSIS
    A comfortable replacement for Select-Object -ExpandProperty.

.DESCRIPTION
    A comfortable replacement for Select-Object -ExpandProperty.
    Allows extracting properties with less typing and more flexibility:

    Like / Match comparison:
    By default like wildcard is used. Specifying match allows extracting any number of matching properties from each object.
    Note that this is a somewhat more CPU-expensive operation (which shouldn't matter unless with gargantuan numbers of objects).

.PARAMETER Name
    ParSet: Like, Match
    The name of the Property to expand. Defaults to wildcard

.PARAMETER Match
    ParSet: Match
    Expands all properties that match the -Name parameter using -match comparison.

.PARAMETER InputObject
    The objects whose properties are to be expanded.

.EXAMPLE
    PS C:\> dir | exp len*

    Expands the properties beginning with len of all objects returned by dir.

.EXAMPLE
    PS C:\> dir | exp name -match

    Expands all properties from all objects returned by dir that match the string "name" ("PSChildName", "FullName", "Name", "BaseName" for directories)
#>
filter Expand-Object {
    [CmdletBinding(DefaultParameterSetName = 'Like')]
    [Alias('eno', 'exp')]
    Param (
        [Parameter(Position = 0, ParameterSetName = 'Like', Mandatory)]
        [Parameter(Position = 0, ParameterSetName = "Match", Mandatory )]
        [string[]]
        $Name,

        [Parameter(ParameterSetName = "Match", Mandatory )]
        [switch]
        $Match,

        [Parameter(ValueFromPipeline)]
        [Alias('io')]
        [psobject]
        $InputObject
    )
	
    foreach ($currentObject in $InputObject) {
        if ($null -eq $currentObject) {
            continue
        }
        $matchedProps = foreach ($currentPropName in $currentObject.psobject.Properties.Name) {
            foreach ($currentName in $Name) {
                if ($PSCmdlet.ParameterSetName -eq 'Like' -and $currentPropName -like $currentName) {
                    $currentPropName
                    break
                }
                elseif ($PSCmdlet.ParameterSetName -eq 'Match' -and $currentPropName -match $currentName) {
                    $currentPropName
                    break
                }
            }
        }
        foreach ($prop in $matchedProps) {
            if ($null -ne $currentObject.$prop) {
                $currentObject.$prop
            }
        }
    }
}
