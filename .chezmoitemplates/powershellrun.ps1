Set-PSRunActionKeyBinding -FirstActionKey 'Shift+Enter' -SecondActionKey 'Enter'
Set-PSRunPSReadLineKeyHandler -PSReadLineHistoryChord 'Ctrl+r' -TabCompletionChord 'Ctrl+8,Tab'
Get-PSRunDefaultSelectorOption | ForEach-Object -Process {
    $_.Theme.PreviewTextWrapMode = 'Character'
    $_
} | Set-PSRunDefaultSelectorOption

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

Remove-Variable 'pwshRunSplat'
