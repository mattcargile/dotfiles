[CmdletBinding()]
param()

begin {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest
    function New-ArgCompleterObject {
        [CmdletBinding()]
        param (
            # Path to completer file
            [Parameter(Mandatory, ParameterSetName = 'Path')]
            [string]
            $Path,
            # String of completer code
            [Parameter(Mandatory, ParameterSetName = 'String')]
            [string]
            $Script,
            # Comment about the completer
            [Parameter(Mandatory)]
            [string]
            $Comment
        )
        end {

            $code =
                if ($Path) {
                    Get-Content -Path $Path -Raw
                }
                else {
                    $Script
                }
            $commentFull = "#region $Comment" 
            [PSCustomObject]@{
                Script = $code
                Comment = $commentFull
            }

        }
    }
}
end {
    #region argument completer
    $argCompFiles = [System.Collections.Generic.List[psobject]]@()

    #region carapace completers first.
    # Prefer software made completions first
    $env:CARAPACE_ENV = 0 # Don't add environment helper functions
    $env:CARAPACE_EXCLUDES = 'ls,bat,rg,fd,gh,chezmoi,glow,bb,dotnet,winget,get-env,set-env,unset-env' # Exclude completions that conflict or already exist from software creator.
    # Need to add this to the path before running script because there is logic in the script to add this to the process. Need to make the script more consistent
    $env:Path += ";$env:APPDATA\carapace\bin" -replace '\\', '/' # carapace golang binary uses forward slashes to check for path
    $argCompFiles.Add( ( New-ArgCompleterObject -Script (carapace.exe _carapace powershell | Out-String) -Comment 'Carapace Various Completions' ) )
    Remove-Item Env:\CARAPACE_ENV, Env:\CARAPACE_EXCLUDES

    #endregion
    
    #region Resolve vendor provided completers.
    $argCompFiles.Add( ( New-ArgCompleterObject -Path "$env:USERPROFILE\scoop\apps\bat\current\autocomplete\_bat.ps1" -Comment 'bat PSReadline Argument Completer' ) )
    $argCompFiles.Add( ( New-ArgCompleterObject -Path "$env:USERPROFILE\scoop\apps\ripgrep\current\complete\_rg.ps1" -Comment 'ripgrep (rg) PSReadline Argument Completer' ) )
    $argCompFiles.Add( ( New-ArgCompleterObject -Path "$env:USERPROFILE\scoop\apps\fd\current\autocomplete\fd.ps1" -Comment 'fd PSReadline Argument Completer') )
    #endregion

    #region Add custom made files and strings for processing
    $argCompFiles.Add( ( New-ArgCompleterObject -Script (gh.exe completion --shell powershell | Out-String) -Comment 'gh GitHub.com Prompt Completions' ) )
    $argCompFiles.Add( ( New-ArgCompleterObject -Script (chezmoi.exe completion powershell | Out-String) -Comment 'chezmoi dotfile management Prompt Completions' ) )
    $argCompFiles.Add( ( New-ArgCompleterObject -Script (glow.exe completion powershell | Out-String) -Comment 'glow Markdown Viewer Prompt Completions' ) ) 
    $argCompFiles.Add( ( New-ArgCompleterObject -Script (bb.exe completion powershell | Out-String) -Comment 'bb Bitbucket Prompt Completions' ) ) 

    # Any custom hand written completers add to argcompleter.ps1
    #endregion

    #region output argcompleter script
    $newLine = [System.Environment]::NewLine
    [System.Management.Automation.Language.Token[]]$tkns = $null
    [System.Management.Automation.Language.ParseError[]]$err = $null
    foreach ($ac in $argCompFiles) {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput( $ac.Script, [ref]$tkns, [ref]$err )
        if ($err) {
            Write-Information -MessageData $err -Tags 'ParserError'
            Write-Error "[$($ac.Comment)] $($err.Message) Start Line $($err.Extent.StartLineNumber) and Start Column $($err.Extent.StartColumnNumber)."
            continue
        }
        if ($ast.BeginBlock -or $ast.CleanBlock -or $ast.DynamicParamBlock -or $ast.ProcessBlock -or $ast.ParamBlock -or $ast.ScriptRequirements) {
            Write-Warning -Message "[$($ac.Comment)] Ast in a form that isn't expected and includes more code blocks than only End Block. Continuing to next item."
            continue
        }
        Write-Information -MessageData $ast -Tags Ast
        
        "$($ac.Comment)$newLine$($ast.EndBlock.Extent.Text)$newLine#endregion$newLine"
    }
    #endregion
}
