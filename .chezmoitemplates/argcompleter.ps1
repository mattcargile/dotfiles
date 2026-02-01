Register-ArgumentCompleter -Native -CommandName 'winget' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName Get-CommandParameter -ParameterName Name -ScriptBlock {
    param(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
    )
    end {
        if (-not $wordToComplete) {
            $wordToComplete = '*'
        } else {
            $wordToComplete += '*'
        }

        $command = Get-InferredCommand -FakeBoundParameters $fakeBoundParameters -CommandAst $commandAst
        if (-not $command) {
            return
        }

        foreach ($parameter in $command.Parameters.Values) {
            if (-not $fakeBoundParameters['IncludeCommon'] -and [System.Management.Automation.Cmdlet]::CommonParameters.Contains($parameter.Name)) {
                continue
            }
            if ($parameter.Name -like $wordToComplete) {
                # yield
                [System.Management.Automation.CompletionResult]::new(
                    $parameter.Name,
                    $parameter.Name,
                    [System.Management.Automation.CompletionResultType]::ParameterValue,
                    $parameter.Name)
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Get-CommandParameter -ParameterName Command -ScriptBlock {
    param(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
    )
    end {
        if (-not $wordToComplete) {
            $wordToComplete = '*'
        }

        return [System.Management.Automation.CompletionCompleters]::CompleteCommand($wordToComplete)
    }
}

Register-ArgumentCompleter -CommandName 'Get-UserVariable' -ParameterName 'Name' -ScriptBlock {
    param(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
    )
    Get-UserVariable -Name "$wordToComplete*" -Exclude 'commandName', 'parameterName', 'wordToComplete', 'commandAst', 'fakeBoundParameters' | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Visibility)
    }
}
