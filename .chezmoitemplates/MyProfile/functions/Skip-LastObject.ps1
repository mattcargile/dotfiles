function Skip-LastObject {
    [Alias('skiplast')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Count = 1
    )
    begin {
        $pipe = { Skip-Object -Last @PSBoundParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($MyInvocation.ExpectingInput)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}
