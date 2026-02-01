function Select-FirstObject {
    [Alias('first', 'top')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Count = 1
    )
    begin {
        $amountProcessed = 0
    }
    process {
        if ($null -eq $InputObject) {
            return
        }

        # yield
        $InputObject

        $amountProcessed++
        if ($amountProcessed -ge $Count) {
            [UtilityProfile.CommandStopper]::Stop($PSCmdlet)
        }
    }
}
