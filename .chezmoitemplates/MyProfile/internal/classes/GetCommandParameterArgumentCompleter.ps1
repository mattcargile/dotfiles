class GetCommandParameterNameArgumentCompleter : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    ) {
        if (-not $WordToComplete) {
            $WordToComplete = '*'
        } else {
            $WordToComplete += '*'
        }

        $completionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        $command = Get-InferredCommand -FakeBoundParameters $FakeBoundParameters -CommandAst $CommandAst
        foreach ($parameter in $command.Parameters.Values) {
            if (-not $FakeBoundParameters['IncludeCommon'] -and
                [System.Management.Automation.Cmdlet]::CommonParameters.Contains($parameter.Name)
            ) {
                continue
            }
            if ($parameter.Name -like $WordToComplete) {
                $completionResults.Add([System.Management.Automation.CompletionResult]::new(
                    $parameter.Name,
                    $parameter.Name,
                    [System.Management.Automation.CompletionResultType]::ParameterValue,
                    $parameter.Name))
            }
        }
        return $completionResults
    }
}

class GetCommandParameterCommandArgumentCompleter : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    ) {
        if (-not $WordToComplete) {
            $WordToComplete = '*'
        }
        return [System.Management.Automation.CompletionCompleters]::CompleteCommand($WordToComplete)
    }
}