$pwshRunTabSplat = @{
    BriefDescription = 'PowerShellRunTabCompletion'
    Description = 'Tab completes anything'
    Chord = 'Ctrl+8,Tab'
    ScriptBlock = {
        param([ConsoleKeyInfo]$key, [object]$arg)
        function GetTabCompletionIcon($CompletionResult) {
            $resultType = $CompletionResult.ResultType
            $icon = switch ($resultType) {
                ProviderContainer { '📁' }
                ProviderItem { '📄' }
                History { '📙' }
                Command { '🔧' }
                default { '📝' }
            }
            $icon
        }
        function GetTabCompletionPreviewScript($CompletionResult) {
            $previewDefault = {
                param ($completionResult)
                $completionResult.ToolTip
            }

            $previewFolder = {
                param ($completionResult)
                $path = $completionResult.ToolTip
                $childItems = Get-ChildItem $path
                $childItems | ForEach-Object {
                    if ($_.PSIsContainer) {
                        $icon = '📁'
                    } else {
                        $icon = '📄'
                    }
                    '{0} {1}' -f $icon, $_.Name
                }
            }

            $previewFile = {
                param ($completionResult)
                $path = $completionResult.ToolTip
                Get-Item $path | Out-String
            }

            $previewCommand = {
                param ($completionResult)
                $commandName = $completionResult.ListItemText
                $command = Get-Command -Name $commandName -ErrorAction Ignore
                if (-not $command) {
                    return $completionResult.ToolTip
                }

                $preview = switch ($command.CommandType) {
                    { $_ -in 'Alias', 'Cmdlet', 'Function', 'Filter' } { Get-Help $commandName | Out-String }
                    default { $command | Select-Object -Property Version, Source | Out-String }
                }
                $preview
            }

            $resultType = $CompletionResult.ResultType
            $previewScript = switch ($resultType) {
                ProviderContainer { $previewFolder }
                ProviderItem { $previewFile }
                Command { $previewCommand }
                default { $previewDefault }
            }

            $previewScript, $CompletionResult
        }
        function ReplaceTabCompletionText($CommandCompletion, $CompletionResult) {
            $completionText = $CompletionResult.CompletionText
            $putCursorBeforeQuote = $false

            # If it's a folder, put DirectorySeparatorChar at the end for the next tab completion.
            if ($CompletionResult.ResultType -eq 'ProviderContainer') {
                $lastChar = $completionText[-1]
                if ($lastChar -eq "'" -or $lastChar -eq '"') {
                    $completionText = $completionText.Substring(0, $completionText.Length - 1) + [System.IO.Path]::DirectorySeparatorChar + $lastChar
                    $putCursorBeforeQuote = $true
                } else {
                    $completionText += [System.IO.Path]::DirectorySeparatorChar
                }
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($CommandCompletion.ReplacementIndex, $CommandCompletion.ReplacementLength, $completionText)
            if ($putCursorBeforeQuote) {
                [Microsoft.PowerShell.PSConsoleReadLine]::BackwardChar()
            }
        }
        # Force implicit module load at beginning
        $option = Get-PSRunDefaultSelectorOption
        $option.Theme.PreviewTextWrapMode = 'Character'
        $option.Theme.CanvasTopMargin += 1
        $actionKeys = @(
            [PowerShellRun.ActionKey]::new('Shift+Enter', 'Insert')
        )

        $inputScript = $null
        $cursorPos = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$inputScript, [ref]$cursorPos)

        $commandCompletion = TabExpansion2 -inputScript $inputScript -cursorColumn $cursorPos
        if ($commandCompletion.CompletionMatches.Count -eq 0) {
            return
        }

        if ($commandCompletion.CompletionMatches.Count -eq 1) {
            $completion = $commandCompletion.CompletionMatches[0]
            ReplaceTabCompletionText $commandCompletion $completion
            return
        }

        [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()

        $entries = [System.Collections.Generic.List[PowerShellRun.SelectorEntry]]::new()
        $noMatchRegex = [Regex]::new('\0')
        foreach ($completion in $commandCompletion.CompletionMatches) {
            $entry = [PowerShellRun.SelectorEntry]::new()
            $entry.UserData = $completion
            $entry.Icon = GetTabCompletionIcon $completion
            $entry.Name = $completion.ListItemText
            $entry.Description = "[$($completion.ResultType)] $($completion.CompletionText)"
            # Exclude Description from search.
            $entry.DescriptionSearchablePattern = $noMatchRegex
            $entry.PreviewAsyncScript, $entry.PreviewAsyncScriptArgumentList = GetTabCompletionPreviewScript $completion
            $entry.ActionKeys = $actionKeys
            $entries.Add($entry)
        }

        $result = Invoke-PSRunSelectorCustom -Entry $entries -Option $option 

        $completion = $result.FocusedEntry.UserData
        if (-not $completion) {
            # We have to call RevertLine twice to escape from PredictionViewStyle ListView.
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($inputScript)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursorPos)
            return
        }

        if ($result.KeyCombination -eq 'Shift+Enter') {
            ReplaceTabCompletionText $commandCompletion $completion
        }
    }
}
Set-PSReadLineKeyHandler @pwshRunTabSplat

$pwshRunReadlineHistorySplat = @{
    BriefDescription = 'PowerShellRunSearchPSReadLineHistory'
    Description = 'Searchs PSConsoleReadLine History Items'
    Chord = 'Ctrl+r'
    ScriptBlock = {
        param([ConsoleKeyInfo]$key, [object]$arg)
        # Force implicit module load at beginning
        $option = Get-PSRunDefaultSelectorOption
        $option.Theme.PreviewTextWrapMode = 'Character'
        $option.Theme.CanvasTopMargin += 1

        $actionKeys = @(
            [PowerShellRun.ActionKey]::new('Shift+Enter', 'Execute')
            [PowerShellRun.ActionKey]::new('Enter', 'Insert')
            [PowerShellRun.ActionKey]::new('Ctrl+c', 'Copy command to Clipboard')
        )

        $cursorPos = $null
        $initialQuery = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$initialQuery, [ref]$cursorPos)

        $historyItems = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()
        [Array]::Reverse($historyItems)

        $historySet = [System.Collections.Generic.Hashset[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $entries = [System.Collections.Generic.List[PowerShellRun.SelectorEntry]]::new()
        foreach ($item in $historyItems) {
            $isAdded = $historySet.Add($item.CommandLine)
            if ($isAdded) {
                $entry = [PowerShellRun.SelectorEntry]::new()
                $entry.UserData = $item
                $entry.Name = $item.CommandLine

                $startTime = if ($item.StartTime -ne [DateTime]::MinValue) {
                    $localTime = $item.StartTime.ToLocalTime()
                    '{0} {1}' -f $localTime.ToShortDateString(), $localTime.ToShortTimeString()
                } else {
                    '-'
                }
                $elapsedTime = if ($item.ApproximateElapsedTime -ne [TimeSpan]::Zero) {
                    $item.ApproximateElapsedTime.ToString()
                } else {
                    '-'
                }

                $entry.Preview = "{0}📅 {1} ⌚ {2}{3}`n`n{4}" -f $PSStyle.Underline, $startTime, $elapsedTime, $PSStyle.UnderlineOff, $item.CommandLine
                $entry.ActionKeys = $actionKeys

                $entries.Add($entry)
            }
        }

        $context = [PowerShellRun.SelectorContext]::new()
        $context.Query = $initialQuery

        $result = Invoke-PSRunSelectorCustom -Entry $entries -Context $context -Option $option

        $command = $result.FocusedEntry.UserData.CommandLine
        if (-not $command) {
            # We have to call RevertLine twice to escape from PredictionViewStyle ListView.
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($initialQuery)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursorPos)
            return
        }

        if ($result.KeyCombination -eq 'Shift+Enter') {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
        elseif ($result.KeyCombination -eq 'Enter') {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
        }
        elseif ($result.KeyCombination -eq 'Ctrl+c') {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            $command | Set-Clipboard
        }
    }
}
Set-PSReadLineKeyHandler @pwshRunReadlineHistorySplat

$pwshRunSplat = @{
    BriefDescription = 'PowerShellRunSelectProviderItems'
    Description = 'Select files names from current directory as a parameter value'
    Chord = 'Ctrl+t'
    ScriptBlock = {
        param([ConsoleKeyInfo]$key, [object]$arg)
        Get-ChildItem -Recurse -File |
            Invoke-PSRunSelector -DescriptionProperty 'FullName' -MultiSelection |
            Join-String -Separator "','" -OutputPrefix "'" -OutputSuffix "'" |
            ForEach-Object -Process {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($_)
            }
    }
}
Set-PSReadLineKeyHandler @pwshRunSplat

Remove-Variable -Name @(
    'pwshRunSplat'
    'pwshRunTabSplat'
    'pwshRunReadlineHistorySplat'
)
