[CmdletBinding()]
param (
)
end {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $publicFunctionsRootFiles = Get-ChildItem -Path "$PSScriptRoot\MyProfile\functions" -Filter *.ps1*
    $publicFunctionAliasesAll = [System.Collections.Generic.List[string]]::new()
    $publicFunctionAliasesDesktop = [System.Collections.Generic.List[string]]::new()
    $publicFunctionAliasesCore = [System.Collections.Generic.List[string]]::new()
    [System.Management.Automation.Language.Token[]]$tkns = $null
    [System.Management.Automation.Language.ParseError[]]$err = $null
    $findFunctionDelegate = {
        param([System.Management.Automation.Language.Ast]$ast)
        if ($ast -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            $true
        }
        else {
            $false
        }
    }
    $currentFile = $null
    foreach ($currentFile in $publicFunctionsRootFiles) {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile( $currentFile, [ref]$tkns, [ref]$err )
        if ($err) {
            Write-Information -MessageData $err -Tags 'ParserError'
            Write-Error "[$($currentFile.Name)] $($err.Message) Start Line $($err.Extent.StartLineNumber) and Start Column $($err.Extent.StartColumnNumber)."
            continue
        }
        if ($ast.BeginBlock -or $ast.CleanBlock -or $ast.DynamicParamBlock -or $ast.ProcessBlock -or $ast.ParamBlock -or $ast.ScriptRequirements) {
            Write-Error -Message "[$($currentFile.Name)] Ast in a form that isn't expected and includes more code blocks than only End Block. Continuing to next item."
            continue
        }
        Write-Information -MessageData $ast -Tags Ast
        $scriptFunctions = $ast.FindAll( $findFunctionDelegate, $false ) # Only want outer functions and not nested ones
        foreach ($currentFunc in $scriptFunctions) {
            $aliasValues = $currentFunc |
                ForEach-Object -MemberName Body |
                ForEach-Object -MemberName ParamBlock |
                ForEach-Object -MemberName Attributes |
                Where-Object -FilterScript { $_.TypeName.Name -eq 'Alias' } |
                ForEach-Object -MemberName PositionalArguments
            foreach ($currentAlias in $aliasValues) {
                if ($currentFile.BaseName -match '\.desktop$') {
                    $publicFunctionAliasesDesktop.Add( $currentAlias.Value )
                }
                elseif ($currentFile.BaseName -match '\.core$') {
                    $publicFunctionAliasesCore.Add( $currentAlias.Value )
                }
                else {
                    $publicFunctionAliasesAll.Add( $currentAlias.Value )
                }
            }
        }
    }
        '' # Empty CRLF to allow parseable psd1 and correct chezmoi output
    $publicFunctionAliasesAll | Sort-Object | ForEach-Object -Process {
        "    '$_'"
    }
        '    if ($PSEdition -eq ''Core'') {'
    $publicFunctionAliasesCore | Sort-Object | ForEach-Object -Process {
        "        '$_'"
    }
        '    }'
        '    else {'
    $publicFunctionAliasesDesktop | Sort-Object | ForEach-Object -Process {
        "        '$_'"
    }
        '    }'

}
