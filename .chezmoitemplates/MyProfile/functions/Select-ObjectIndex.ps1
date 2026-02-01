function Select-ObjectIndex {
    [Alias('at')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0, Mandatory)]
        [int] $Index
    )
    begin {
        $currentIndex = 0
        $lastPipe = $null
        $isIndexNegative = $Index -lt 0

        if ($isIndexNegative) {
            $lastParams = @{
                Count = $Index * -1
            }

            $lastPipe = { Select-LastObject @lastParams }.GetSteppablePipeline([CommandOrigin]::Internal)
            $lastPipe.Begin($MyInvocation.ExpectingInput)
        }
    }
    process {
        if ($null -eq $InputObject) {
            return
        }

        if (-not $isIndexNegative) {
            if ($currentIndex -eq $Index) {
                # yield
                $InputObject
                [UtilityProfile.CommandStopper]::Stop($PSCmdlet)
            }

            $currentIndex++
            return
        }

        $lastPipe.Process($PSItem)
    }
    end {
        if ($null -ne $lastPipe) {
            # yield
            $lastPipe.End() | Select-Object -First 1
        }
    }
}
