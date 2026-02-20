#Requires -Version 7.5.4
[CmdletBinding()]
param (
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fileSystemInfoColorPath = Join-Path $PSScriptRoot .\filesysteminfocolor.psd1.tmpl
$fileSystemInfoColorScript =  chezmoi execute-template --file $fileSystemInfoColorPath | Out-String

[System.Management.Automation.Language.Token[]]$parserTokens = $null
[System.Management.Automation.Language.ParseError[]]$parserErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput( $fileSystemInfoColorScript, [ref]$parserTokens, [ref]$parserErrors )
if ($parserErrors) {
    Write-Information -MessageData $parserErrors -Tags 'ParserError'
    Write-Error "[$($fileSystemInfoIconPath)] $($parserErrors.Message) Start Line $($parserErrors.Extent.StartLineNumber) and Start Column $($parserErrors.Extent.StartColumnNumber)."
    return
}
Write-Information -MessageData $ast -Tags Ast
Write-Information -MessageData $parserTokens -Tags Tokens
if ($ast.BeginBlock -or $ast.CleanBlock -or $ast.DynamicParamBlock -or $ast.ProcessBlock -or $ast.ParamBlock -or $ast.ScriptRequirements) {
    Write-Error -Message "[$($currentFile.Name)] Ast in a form that isn't expected and includes more code blocks than only End Block. Continuing to next item."
    return
}
$outStringBuilder = [System.Text.StringBuilder]::new($ast.Extent.EndOffset)
$outStringBuilder.AppendLine( '[Diagnostics.CodeAnalysis.SuppressMessageAttribute( ''PSUseDeclaredVarsMoreThanAssignments'', ''formatFileSystemInfoColor'', Justification = ''Variable used as cache in later module calls.'')]' ) | Out-Null
$outStringBuilder.Append( '$script:formatFileSystemInfoColor = ' ) | Out-Null
for ($tkIdx = 0; $tkIdx -lt $parserTokens.Count; $tkIdx++) {
    if ($tkIdx -gt 0) { $previousToken = $parserTokens[$tkIdx - 1] }
    else { $previousToken = $null }
    Write-Debug "Previous Token text value is $previousToken"
    
    $currentToken = $parserTokens[$tkIdx]
    Write-Debug "Current Token text value is $currentToken"

    if ($tkIdx -ne $parserTokens.Count - 1) { $nextToken = $parserTokens[$tkIdx + 1] }
    else { $nextToken = $null }
    Write-Debug "Next Token text value is $nextToken"

    if ($currentToken.TokenFlags -contains 'AssignmentOperator') {
        $outStringBuilder.
            Append( ' ' ).
            Append( $currentToken ).
            Append( ' ' ) |
            Out-Null
    }
    elseif (
        $currentToken.TokenFlags -contains 'MemberName' -or
        ${nextToken}?.TokenFlags -contains 'AssignmentOperator' -or
        ( $currentToken.Kind -eq 'Comment' -and ${previousToken}?.Kind -eq 'NewLine') -or
        $currentToken.Kind -eq 'RCurly'
    ) {
        $outStringBuilder.
            Append(' ' * $currentToken.Extent.StartColumnNumber).
            Append($currentToken) |
            Out-Null
    }
    elseif ($currentToken.Kind -eq 'Comment' -and ${previousToken}?.Kind -ne 'NewLine') {
        $outStringBuilder.
            Append(' ').
            Append($currentToken) |
            Out-Null
    }
    elseif (${previousToken}?.TokenFlags -contains 'AssignmentOperator' -and $currentToken.Kind -eq 'StringLiteral' ) {
        $outStringBuilder.
            Append( "'" ).
            Append( $PSStyle.Foreground.FromRgb( "0x$($currentToken.Value)" ) ).
            Append( "'" ).
            Append( " #$($currentToken.Value)") | Out-Null
    }
    else {
        $outStringBuilder.Append($currentToken) | Out-Null
    }
}
# Remove final `0 converted to `<eof>` and return
$outStringBuilder.Remove($outStringBuilder.Length - 5, 5 ).ToString()
