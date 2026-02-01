function Out-Bat {
    [Alias('ob')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        $includeStyle = $MyInvocation.ExpectingInput
        $style = '--style', 'grid,numbers,snip'
        foreach ($arg in $ArgumentList) {
            if ($arg -match '^--style=') {
                $includeStyle = $false
                break
            }

            if ($arg -match '^--file-name') {
                $style = '--style', 'grid,numbers,snip,header-filename'
            }
        }

        if ($includeStyle) {
            $ArgumentList += $style
        }

        $pipe = { bat @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}
