function Skip-Object {
    [Alias('skip')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Count = 1,

        [switch] $Last
    )
    begin {
        $currentIndex = 0
        if ($Last) {
            $buffer = [List[psobject]]::new()
        }
    }
    process {
        if ($Last) {
            $buffer.Add($InputObject)
            return
        }

        if ($currentIndex -ge $Count) {
            # yield
            $InputObject
        }

        $currentIndex++
    }
    end {
        if (-not $Last) {
            return
        }

        return $buffer[0..($buffer.Count - $Count - 1)]
    }
}
