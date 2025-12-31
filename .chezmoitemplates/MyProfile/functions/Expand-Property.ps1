filter Expand-Property {
    <#
        .SYNOPSIS
            Expands an array property, creating a duplicate object for each value
        .EXAMPLE
            [PSCustomObject]@{ Name = "A"; Value = @(1,2,3) } | Expand-Property Value

            Name Value
            ---- -----
            A        1
            A        2
            A        3
        .EXAMPLE
            [PSCustomObject]@{
                Name = "DevOps"
                Members = "Joe", "Phil", "Barb"
                MemberOf = "Ops", "Dev"
            } |
            Expand-Property MemberOf |
            Expand-Property Members

            Name   MemberOf Members
            ----   -------- -------
            DevOps Ops      Joe
            DevOps Ops      Phil
            DevOps Ops      Barb
            DevOps Dev      Joe
            DevOps Dev      Phil
            DevOps Dev      Barb
    #>
    [Alias('enp')]
    param(
        # The name of a property on the input object, that has more than one value
        [Alias("Property")]
        [string]$Name,

        # The input object to duplicated
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    foreach ($Value in $InputObject.$Name) {
        $InputObject | Select-Object *, @{ Name = $Name; Expr = { $Value } } -Exclude $Name
    }
}
