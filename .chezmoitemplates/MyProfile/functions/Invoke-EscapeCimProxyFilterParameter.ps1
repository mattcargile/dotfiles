filter Invoke-EscapeCimProxyFilterParameter {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]$InputObject,
        [switch]$Escape
    )
    if ($Escape) {
        $InputObject -replace '\\', '\\' -replace "'", "\'"
    }
    else { $InputObject }
}
