$esc = [char]0x1B
$bg = "$esc[48;2;40;40;40m"
$underline = "$esc[27m$esc[4m$bg"
$splat = @{
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
    HistorySavePath = "$env:USERPROFILE\.config\PSReadLine\All$($Host.Name)_history.txt"
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
        $splat.Colors.ListPrediction = "$esc[38;2;195;100;241m"
        $splat.Colors.ListPredictionToolTip = "$esc[38;5;243m$esc[3m"
    }
    # When Colors.InlinePrediction was added
    # See above link
    if ($psReadLnVersion -ge '2.1.0') {
        $splat.Colors.InlinePrediction = "$esc[38;5;243m" # Bumped up from 238 to make it easier to read on laptop ( e.g. smaller screens )
    }

    if ($PSVersionTable.PSVersion -ge [version]'7.2') {
        $splat.PredictionSource = 'HistoryAndPlugin'
    }
    else {
        $splat.PredictionSource = 'History'
    }
}
Set-PSReadLineOption @splat

# For part way completion of History PredictionSource
$splat = @{
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
Set-PSReadLineKeyHandler @splat

# Save current line to history ( without execution ) and clear line.
$splat = @{
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
Set-PSReadLineKeyHandler @splat

# Prevent variable clutter in Get-Variable Output
$rmVar = @(
    'rmVar'
    'splat'
    'esc'
    'bg'
    'underline'
    'psReadLnVersion'
)
Remove-Variable -Name $rmVar
