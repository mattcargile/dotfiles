$modulesToImport = @(
    'ClassExplorer' # Helps with exploration of libraries and objects
    'PowerShellHumanizer' # Used for File and Directory time and length formatting. Need to import because libraries are used.
    'Terminal-Icons' # Need to import first so I can override the default formatter further downstream. Used for icons of File and Directory 
    'ZLocation2' # Forked z-cd jumper. Original repo isn't active.
    if ($IsCoreCLR) { 'PowerShellRun' } # Fuzzy Finger and filter like `fzf`.
    "$env:USERPROFILE\.config\powershell\MyProfile\MyProfile.psd1"
)
Import-Module -Name $modulesToImport 

<# string module configuration #>
if ($IsCoreCLR) {
    # Prefer core's implementation of join and have a proxied command
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","StringModule_DontInjectJoinString",Justification="Variable required in session for future implicit string module load.")]
    $StringModule_DontInjectJoinString = $true
}

# Fuzzy Finder for completion and history
# Need to reset action keys or else an `Enter` will automatically execute the command from the history. Muscle memory is already too strong.
if ($IsCoreCLR) {
    Set-PSRunActionKeyBinding -FirstActionKey 'Shift+Enter' -SecondActionKey 'Enter'
    Set-PSRunPSReadLineKeyHandler -PSReadLineHistoryChord 'Ctrl+r' -TabCompletionChord 'Ctrl+8,Tab'
    Get-PSRunDefaultSelectorOption | ForEach-Object -Process {
        $_.Theme.PreviewTextWrapMode = 'Character'
        $_
    } | Set-PSRunDefaultSelectorOption
}

# Helper Visual Studio Code Command Palette operations ( i.e. EditorServicesCommandSuite )
if($env:TERM_PROGRAM -eq 'vscode') {
    Import-CommandSuite
}
Remove-Variable -Name 'modulesToImport'
