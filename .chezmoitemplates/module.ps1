# Necessary Modules
# 1. Helps with exploration of libraries and objects
# 2. Used for File and Directory time and length formatting
# 3. Used for icons of File and Directory 
# 4. Custom "MyProfile" module
$modulesToImport = @(
    'ClassExplorer'
    'PowerShellHumanizer'
    'Terminal-Icons'
    if ($PSEdition -eq 'Core') { 'PowerShellRun' }
    "$env:USERPROFILE\.config\powershell\MyProfile\MyProfile.psd1"
)
Import-Module -Name $modulesToImport 

# Fuzzy Finder for completion and history
# Need to reset action keys or else an `Enter` will automatically execute the command from the history. Muscle memory is already too strong.
if ($PSEdition -eq 'Core') {
    Set-PSRunActionKeyBinding -FirstActionKey 'Shift+Enter' -SecondActionKey 'Enter'
    Set-PSRunPSReadLineKeyHandler -PSReadLineHistoryChord 'Ctrl+r' -TabCompletionChord 'Ctrl+8,Tab'
    Get-PSRunDefaultSelectorOption | ForEach-Object -Process {
        $_.Theme.PreviewTextWrapMode = 'Character'
        $_
    } | Set-PSRunDefaultSelectorOption -Option { $_ }
}

# Helper Visual Studio Code Command Palette operations ( i.e. EditorServicesCommandSuite )
if($env:TERM_PROGRAM -eq 'vscode') {
    Import-CommandSuite
}
Remove-Variable -Name 'modulesToImport'
