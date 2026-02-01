function Format-Json {
    [Alias('fjson')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        if ($ArgumentList.Count -eq 0 -or $null -eq $ArgumentList) {
            $ArgumentList = '.'
        }
        $pipe = { Out-Jq @ArgumentList | Out-Bat }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}
