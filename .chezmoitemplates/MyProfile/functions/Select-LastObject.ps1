function Select-LastObject {
    [Alias('last')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Count = 1
    )
    begin {
        if ($Count -eq 1) {
            $objStore = $null
            return
        }

        $objStore = [psobject[]]::new($Count)
        $currentIndex = 0
    }
    process {
        if ($null -eq $InputObject) {
            return
        }

        if ($Count -eq 1) {
            $objStore = $InputObject
            return
        }

        $objStore[$currentIndex] = $InputObject
        $currentIndex++
        if ($currentIndex -eq $objStore.Length) {
            $currentIndex = 0
        }
    }
    end {
        if ($Count -eq 1) {
            return $objStore
        }

        for ($i = $currentIndex; $i -lt $objStore.Length; $i++) {
            # yield
            $objStore[$i]
        }

        for ($i = 0; $i -lt $currentIndex; $i++) {
            # yield
            $objStore[$i]
        }
    }
}
