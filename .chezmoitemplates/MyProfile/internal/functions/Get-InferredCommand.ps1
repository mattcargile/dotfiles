function Get-InferredCommand {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $FakeBoundParameters,

        [System.Management.Automation.Language.CommandAst] $CommandAst
    )
    end {
        $command = $FakeBoundParameters['Command']
        if ($command = Get-CommandFromString $command) {
            return $command
        }

        if ($CommandAst.Parent -isnot [System.Management.Automation.Language.PipelineAst]) {
            return
        }

        $index = $CommandAst.Parent.PipelineElements.IndexOf($CommandAst)
        if ($index -le 0) {
            return
        }

        $previous = $CommandAst.Parent.PipelineElements[$index - 1]
        if ($previous -isnot [System.Management.Automation.Language.CommandAst]) {
            return
        }

        $previousName = $previous.GetCommandName()
        if ($previousName -notin 'gcm', 'Get-Command') {
            return
        }

        $firstArg = $Previous.CommandElements[1]
        if ($firstArg -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) {
            return
        }

        $firstArg = $firstArg.Value
        if (-not $firstArg) {
            return
        }

        return Get-CommandFromString $firstArg
    }
}
