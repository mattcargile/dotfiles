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
function Expand-Object {
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

    begin {
        $itemCounter = 0
    }
    process {
        foreach ($currentObject in $InputObject) {
            if ($null -eq $currentObject) {
                continue
            }
            $matchedProps = [System.Collections.Generic.OrderedDictionary[string, psobject]]::new()
            switch ($PSCmdlet.ParameterSetName) {
                'Like' {
                    foreach ($currentName in $Name) {
                        foreach ($currentLikeMatchedProp in $currentObject.psobject.Properties.Match($currentName)) {
                            if ( -not $matchedProps.ContainsKey($currentLikeMatchedProp.Name)) {
                                $currrentOutput = [MyProfileExpandObject]@{
                                    Name = $currentLikeMatchedProp.Name
                                    TypeName = $currentLikeMatchedProp.TypeNameOfValue
                                    Value = $currentLikeMatchedProp.Value
                                    Index = ($itemCounter++)
                                }
                                Write-Debug "Adding $($currentProp.Name)"
                                $matchedProps.Add( $currentLikeMatchedProp.Name, $currrentOutput )
                            }

                        }
                        
                    }
                }
                'Match' {
                    foreach ($currentProp in $currentObject.psobject.Properties) {
                        if (-not $matchedProps.ContainsKey($currentProp.Name) ) {
                            foreach ($currentName in $Name) {
                                if ($currentProp.Name -match $currentName) {
                                    $currentOutput = [MyProfileExpandObject]@{
                                        Name = $currentProp.Name
                                        TypeName = $currentProp.TypeNameOfValue
                                        Value = $currentProp.Value
                                        Index = ($itemCounter++)
                                    }
                                    Write-Debug "Adding $($currentProp.Name)"
                                    $matchedProps.Add($currentProp.Name, $currentOutput )
                                    break
                                }
                            }
                        }
                    }

                }
                Default {
                    Write-Error "Entered the default switch parameter set. Parameter set definitions are wrong."
                    return
                }
            }
            $matchedProps.Values
        }
    }
}
