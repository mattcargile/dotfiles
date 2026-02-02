#region PSReadLine Option
$esc = [char]0x1B
$bg = "$esc[48;2;40;40;40m"
$underline = "$esc[27m$esc[4m$bg"
$setPSReadLineOptionSplat = @{
    Colors = @{
        # ListPrediction handled further down
        # InlinePrediction handled further down
        Member             = "$esc[38;2;228;228;228m"   #e4e4e4
        Parameter          = "$esc[38;2;228;228;228m"   #e4e4e4
        Default            = "$esc[38;2;228;228;228m"   #e4e4e4
        Operator           = "$esc[38;2;197;197;197m"   #c5c5c5
        Keyword            = "$esc[38;2;197;134;192m"   #c586c0
        Command            = "$esc[38;2;220;220;125m"   #dcdc7d
        Emphasis           = "$underline$esc[48;2;38;79;120m" #264f78
        Selection          = "$esc[48;2;38;79;120m"     #264f78
        Type               = "$esc[38;2;78;201;176m"    #4ec9b0
        Variable           = "$esc[38;2;124;220;254m"   #7cdcfe
        String             = "$esc[38;2;206;145;120m"   #ce9178
        Comment            = "$esc[38;2;96;139;78m"     #608b4e
        Number             = "$esc[38;2;147;206;168m"   #93cea8
        Error              = "$esc[38;2;139;0;0m"       #8b0000
    }
    # HistorySavePath = "$env:OneDrive\Documents\.config\pwsh\PSReadLine\All$($Host.Name)_history.txt" # Microsoft Defender On Sharepoint throws malware warnings
    HistorySavePath = "$HOME\.config\PSReadLine\All$($Host.Name)_history.txt"
    MaximumHistoryCount = 500000
    HistoryNoDuplicates = $true
    # By default PSReadline removes "password", "cred", etc items from history. This forces save of all commands to history.
    AddToHistoryHandler = {
        param([string]$line)
        # Do not save any command line unless it has more than 4 characters.  Prevents storing gci, gps, etc.
        return $line.Length -gt 4
    }
}
$psReadLnVersion = (Get-Module -Name PSReadLine).Version
# When PredictionSource parameter was added.
# https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline_release_notes?view=powershell-7.4#v204---2020-08-05
if ($psReadLnVersion -ge '2.0.4' ) {
    # When Colors.ListPrediction was added
    # https://devblogs.microsoft.com/powershell/announcing-psreadline-2-1-with-predictive-intellisense/
    if ($psReadLnVersion -ge '2.2.2') {
        $setPSReadLineOptionSplat.Colors.ListPrediction = "$esc[38;2;195;100;241m"
        $setPSReadLineOptionSplat.Colors.ListPredictionToolTip = "$esc[38;5;243m$esc[3m"
    }
    # When Colors.InlinePrediction was added
    # See above link
    if ($psReadLnVersion -ge '2.1.0') {
        $setPSReadLineOptionSplat.Colors.InlinePrediction = "$esc[38;5;243m" # Bumped up from 238 to make it easier to read on laptop ( e.g. smaller screens )
    }

    if (-not [Console]::IsOutputRedirected) {
        if ($PSVersionTable.PSVersion -ge [version]'7.2') {
            $setPSReadLineOptionSplat.PredictionSource = 'HistoryAndPlugin'
        }
        else {
            $setPSReadLineOptionSplat.PredictionSource = 'History'
        }
    }
}
Set-PSReadLineOption @setPSReadLineOptionSplat
#endregion

#region For part way completion of History PredictionSource
$setPSReadLineKeyHandlerSplat = @{
    Chord = 'Ctrl+RightArrow'
    BriefDescription = 'NextWordAndAcceptNextSuggestionWord'
    Description = 'Move cursor one word to the right in the current editing line ' + 
        'and accept the next word in suggestion when it''s at the end of current editing line'
    ScriptBlock = {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($cursor -lt $line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::NextWord($key, $arg)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
        }
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat
#endregion

#region Save current line to history ( without execution ) and clear line.
$setPSReadLineKeyHandlerSplat = @{
    Key = 'Alt+y'
    BriefDescription = 'SaveInHistory'
    Description = 'Save current line to history ( without execution) and clear line.'
    ScriptBlock = {
        param($key, $arg)
        $line = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,[ref]$null)
        [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat
#endregion

#region SmartInsertQuote
$setPSReadLineKeyHandlerSplat = @{
    Chord = '"', "'"
    BriefDescription = 'SmartInsertQuote'
    Description = "Insert paired quotes if not already on a quote"
    ScriptBlock = {
        param($key, $arg)

        $quote = $key.KeyChar

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        # If text is selected, just quote it without any smarts
        if ($selectionStart -ne -1)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
            return
        }

        $ast = $null
        $tokens = $null
        $parseErrors = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

        function FindToken
        {
            param($tokens, $cursor)

            foreach ($token in $tokens)
            {
                if ($cursor -lt $token.Extent.StartOffset) { continue }
                if ($cursor -lt $token.Extent.EndOffset) {
                    $result = $token
                    $token = $token -as [StringExpandableToken]
                    if ($token) {
                        $nested = FindToken $token.NestedTokens $cursor
                        if ($nested) { $result = $nested }
                    }

                    return $result
                }
            }
            return $null
        }

        $token = FindToken $tokens $cursor

        # If we're on or inside a **quoted** string token (so not generic), we need to be smarter
        if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
            # If we're at the start of the string, assume we're inserting a new string
            if ($token.Extent.StartOffset -eq $cursor) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
                return
            }

            # If we're at the end of the string, move over the closing quote if present.
            if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
                return
            }
        }

        if ($null -eq $token -or
            $token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
            if ($line[0..$cursor].Where{$_ -eq $quote}.Count % 2 -eq 1) {
                # Odd number of quotes before the cursor, insert a single quote
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
            }
            else {
                # Insert matching quotes, move cursor to be in between the quotes
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            }
            return
        }

        # If cursor is at the start of a token, enclose it in quotes.
        if ($token.Extent.StartOffset -eq $cursor) {
            if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or 
                $token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
                $end = $token.Extent.EndOffset
                $len = $end - $cursor
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
                return
            }
        }

        # We failed to be smart, so just insert a single quote
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat
#endregion

#region InsertPariedBraces
$setPSReadLineKeyHandlerSplat = @{
    Chord = '(', '{', '['
    BriefDescription = 'InsertPairedBraces'
    Description = "Insert matching braces"
    ScriptBlock = {
        param($key, $arg)

        $closeChar = switch ($key.KeyChar)
        {
            <#case#> '(' { [char]')'; break }
            <#case#> '{' { [char]'}'; break }
            <#case#> '[' { [char]']'; break }
        }

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
        if ($selectionStart -ne -1)
        {
          # Text is selected, wrap it in brackets
          [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
          [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        } else {
          # No text is selected, insert a pair
          [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
          [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
        }
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat
#endregion

#region SmartCloseBraces
$setPSReadLineKeyHandlerSplat = @{
    Chord = ')', ']', '}'
    BriefDescription = 'SmartCloseBraces'
    Description = "Insert closing brace or skip"
    ScriptBlock = {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($line[$cursor] -eq $key.KeyChar)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
        }
        else
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
        }
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat
#endregion

#region SmartBackspace
$setPSReadLineKeyHandlerSplat = @{
    Chord = 'Backspace'
    BriefDescription = 'SmartBackspace'
    Description = "Delete previous character or matching quotes/parens/braces"
    ScriptBlock = {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($cursor -gt 0)
        {
            $toMatch = $null
            if ($cursor -lt $line.Length)
            {
                switch ($line[$cursor])
                {
                    <#case#> '"' { $toMatch = '"'; break }
                    <#case#> "'" { $toMatch = "'"; break }
                    <#case#> ')' { $toMatch = '('; break }
                    <#case#> ']' { $toMatch = '['; break }
                    <#case#> '}' { $toMatch = '{'; break }
                }
            }

            if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch)
            {
                [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
            }
            else
            {
                [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
            }
        }
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat
#endregion

#region ParenthesizeSelection
$setPSReadLineKeyHandlerSplat = @{
    Chord = 'Alt+('
    BriefDescription = 'ParenthesizeSelection'
    Description = "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis"
    ScriptBlock = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        }
        else
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
        }
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat
#endregion

#region ToggleQuoteArgument
$setPSReadLineKeyHandlerSplat = @{
    Chord = "Alt+'"
    BriefDescription = 'ToggleQuoteArgument'
    Description = 'Toggle quotes on the argument under the cursor'
    ScriptBlock = {
        param($key, $arg)

        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

        $tokenToChange = $null
        foreach ($token in $tokens)
        {
            $extent = $token.Extent
            if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor)
            {
                $tokenToChange = $token

                # If the cursor is at the end (it's really 1 past the end) of the previous token,
                # we only want to change the previous token if there is no token under the cursor
                if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext())
                {
                    $nextToken = $foreach.Current
                    if ($nextToken.Extent.StartOffset -eq $cursor)
                    {
                        $tokenToChange = $nextToken
                    }
                }
                break
            }
        }

        if ($tokenToChange -ne $null)
        {
            $extent = $tokenToChange.Extent
            $tokenText = $extent.Text
            if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"')
            {
                # Switch to no quotes
                $replacement = $tokenText.Substring(1, $tokenText.Length - 2)
            }
            elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'")
            {
                # Switch to double quotes
                $replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
            }
            else
            {
                # Add single quotes
                $replacement = "'" + $tokenText + "'"
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                $extent.StartOffset,
                $tokenText.Length,
                $replacement)
        }
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat
#endregion

#region ExpandAliases
$setPSReadLineKeyHandlerSplat = @{
    Chord = 'Alt+%'
    BriefDescription = 'ExpandAliases'
    Description = "Replace all aliases with the full command"
    ScriptBlock = {
        param($key, $arg)

        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

        $startAdjustment = 0
        foreach ($token in $tokens)
        {
            if ($token.TokenFlags -band [TokenFlags]::CommandName)
            {
                $alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
                if ($alias -ne $null)
                {
                    $resolvedCommand = $alias.ResolvedCommandName
                    if ($resolvedCommand -ne $null)
                    {
                        $extent = $token.Extent
                        $length = $extent.EndOffset - $extent.StartOffset
                        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                            $extent.StartOffset + $startAdjustment,
                            $length,
                            $resolvedCommand)

                        # Our copy of the tokens won't have been updated, so we need to
                        # adjust by the difference in length
                        $startAdjustment += ($resolvedCommand.Length - $length)
                    }
                }
            }
        }
    }
}
Set-PSReadLineKeyHandler @setPSReadLineKeyHandlerSplat

#endregion

Remove-Variable -Name @(
    'setPSReadLineOptionSplat'
    'setPSReadLineKeyHandlerSplat'
    'esc'
    'bg'
    'underline'
    'psReadLnVersion'
)
