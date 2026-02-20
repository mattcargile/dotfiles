#Requires -Version 7.5.4
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [int]
    $RefreshSeconds
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$glyphPath = Join-Path $PSScriptRoot glyphnames.json
Write-Debug "Glyph file path is $glyphPath"
$haveCurrentGlyph = $true
if (Test-Path $glyphPath) {
    $glyphPathFileInfoLastWrite = (Get-Item $glyphPath).LastWriteTime
    $currentDatetime = Get-Date
    $refreshSecondsTimespan = [timespan]::new(0, 0, $RefreshSeconds)
    Write-Debug "LastWriteTime On $glyphPath is $glyphPathFileInfoLastWrite"
    Write-Debug "Current Date Time is $currentDatetime"
    Write-Debug "Refresh Seconds Timespan is $refreshSecondsTimespan"
    if ( $currentDatetime - $glyphPathFileInfoLastWrite -gt $refreshSecondsTimespan) {
        $haveCurrentGlyph = $false
    }
}
else {
    $haveCurrentGlyph = $false
}
if (-not $haveCurrentGlyph) {
    Write-Verbose 'Do not have current glyph based on RefreshSeconds. Downloading the file.'
    Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json' -OutFile $glyphPath -Verbose:$false -Debug:$false
}
$glyphNamesData = Get-Content $glyphPath -Raw | ConvertFrom-Json

$fileSystemInfoIconPath = Join-Path $PSScriptRoot .\filesysteminfoicon.psd1.tmpl
$fileSystemInfoIconScript =  chezmoi execute-template --file $fileSystemInfoIconPath | Out-String

[System.Management.Automation.Language.Token[]]$parserTokens = $null
[System.Management.Automation.Language.ParseError[]]$parserErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput( $fileSystemInfoIconScript, [ref]$parserTokens, [ref]$parserErrors )
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
$outStringBuilder.AppendLine( '[Diagnostics.CodeAnalysis.SuppressMessageAttribute( ''PSUseDeclaredVarsMoreThanAssignments'', ''formatFileSystemInfoIcon'', Justification = ''Variable used as cache in later module calls.'')]' ) | Out-Null
$outStringBuilder.Append( '$script:formatFileSystemInfoIcon = ' ) | Out-Null
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
        $currentGlyphProperty = $currentToken.Value.Substring(3) # Trim leading nf- as json download doesn't have it while the website does
        Write-Debug "Current modified Glyph Property for Json look up is $currentGlyphProperty"
        $currentGlyphData = $glyphNamesData.$currentGlyphProperty
        $outStringBuilder.
            Append( "'" ).
            Append( $currentGlyphData.char ).
            Append( "'" ).
            Append( " # $currentGlyphProperty|$($currentGlyphData.code)") | Out-Null
    }
    else {
        $outStringBuilder.Append($currentToken) | Out-Null
    }
}
# Remove final `0 converted to `<eof>` and return
$outStringBuilder.Remove($outStringBuilder.Length - 5, 5 ).ToString()
