# Not using at the time. May use later...
# Custom build.https://github.com/kelleyma49/PSFzf/pull/201
Import-Module -Name "$PSScriptRoot\PSFzf_current\PSFzf.psd1"

# Meant to evoke globbing wild card pattern's with Asterisks which are Shift + 8
$PsFzfDesc = 'Uses PSReadline''s Completion results at any given cursor position and context ' +
    'as the source for PsFzf''s module wrapper for fzf.exe'
$PsFzfParam = @{
    Chord = 'Ctrl+8,Tab'
    BriefDescription = 'Fzf Tab Completion' 
    Description = $PsFzfDesc
    ScriptBlock = { Invoke-FzfTabCompletion }
}
Set-PSReadLineKeyHandler @PsFzfParam

Remove-PSReadLineKeyHandler -Chord 'Ctrl+s' # Below Replaces need for this

$PsFzfParam = @{
    PSReadlineChordReverseHistory = 'Ctrl+r'
    PSReadlineChordReverseHistoryArgs = 'Alt+A' # Translates to Alt + Shift + a
    EnableAliasFuzzyZLocation = $true
    EnableAliasFuzzyEdit = $true
    EnableAliasFuzzyGitStatus = $true
    GitKeyBindings = $true
}
Set-PsFzfOption @PsFzfParam

Remove-Variable -Name 'PsFzfParam', 'PsFzfDesc'
