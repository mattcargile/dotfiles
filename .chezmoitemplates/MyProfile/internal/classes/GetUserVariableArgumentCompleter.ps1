class GetUserVariableNameArgumentCompleter : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    ) {
        $completionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        $currentScopeVariables = @( 
            'CommandName'
            'ParameterName'
            'WordToComplete'
            'CommandAst'
            'FakeBoundParameters'
            'completionResults'
            'currentScopeVariables'
        )
        Get-UserVariable -Name "$WordToComplete*" -Exclude $currentScopeVariables |
            ForEach-Object {
                $completionResults.Add( [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Visibility) )
            }
        return $completionResults
    }
}
