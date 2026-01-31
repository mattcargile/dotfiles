filter ConvertTo-CimEscapedFilterValue {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $InputObject
    )
    $InputObject -replace '\\', '\\' -replace "'", "\'"
}
