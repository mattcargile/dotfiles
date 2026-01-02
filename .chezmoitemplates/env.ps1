# Helps work with `less` output. Could impact native command impact with cmdlets
$OutputEncoding = [System.Console]::InputEncoding = [System.Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Set Environment variables for fzf binary progam includes dependency on bat and fd
# Note on performance: --color=always on fd using --ansi on fzf is too slow for over 100k files. It is the 
# --ansi flag that ultimately slows it down.
# Note on file attributes: --hidden --exclude .git can be used to see hidden files and exclude .git. --no-ignore
# has to be used in order to find files within the .gitignore file. By default fd doesn't show these files.
$env:FZF_DEFAULT_COMMAND = 'fd.exe' <# Has interplay with `$env:SHELL`. Requires `cmd.exe`. #>
# -1 is default terminal color. Hexcodes derived from oh-my-posh config.
# gutter's color implementation changed along the lines and the default didn't work and produces and ugly white bar so hard coding to Dracula (Official) wezterm background
# So VSCode may not look as nice.
$FzfGutterColor =
    if ($env:TERM_PROGRAM -eq 'vscode') {
        '#181818' # Default Dark Modern ( Found with Color Picker in PowerToys )
    }
    else {
        '#282a36' # Dracula (Official) Background
    }
$FzfTheme = "--color='hl+:#5fd7ff,hl:#5f87af,bg:-1,bg+:-1,fg:-1,fg+:#919092,gutter:$FzfGutterColor'"
$FzfIconTheme = "--color='prompt:#00897b,pointer:#c386f1,marker:#ff479c'"
# powershell.exe doesn't handle the raw UTF-8 character because of $OutputEncoding and [Console]::OutputEncoding/InputEncoding
$FzfIcons = "--prompt='$([char]0xF054) ' --pointer='$([char]0xDB81)$([char]0xDF0B) ' --marker='$([char]0xF444)'"
$FzfLayout = '--border=rounded --padding=1 --margin=1'
$FzfHistory = "--history='$env:OneDrive\Documents\.fzf_history'"
# Go to first item upon key entry change
$FzfBind = '--bind change:first'
$env:FZF_DEFAULT_OPTS = "$FzfTheme $FzfIconTheme $FzfIcons $FzfLayout $FzfHistory $FzfBind"

# PsFzf module. 
# Below parameter is default for fzf. If want to avoid using $env:FZF_DEFAULT_OPTS
$env:_PSFZF_FZF_DEFAULT_OPTS = ''
$env:FZF_CTRL_T_COMMAND = ''
$env:FZF_CTRL_T_OPTS = ''
$env:FZF_ALT_C_COMMAND = 'fd.exe --type directory'
$env:FZF_ALT_C_OPTS = ''
$env:FZF_CTRL_R_OPTS = ''

# User level environment variable. Not sure how it was configured.
$env:ChocolateyToolsLocation = "C:\tools"

# carapace completions use PSReadLine tooltip
$env:CARAPACE_TOOLTIP = 1 # Powershell tooltip

$envvarPathSeperator = [System.IO.Path]::PathSeparator
$envvarPathsToAdd = [System.Collections.Generic.List[string]]@(
    # Custom miscellaneous exe folder
    "$env:OneDrive\Documents\exe"
    # For wsdl.exe to handle SOAP endpoints to web services.
    'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64'
    # carapace likes to have this in the process path for a feature. The binary does use forward slashes though
    "$env:APPDATA\carapace\bin"
) 
if (Get-Command py -CommandType Application -ErrorAction Ignore) {
    # Something broke in Windows with py.exe Launcher and oh-my-posh.exe
    # This keeps the python segment from breaking on the Downloads folder and others
    # Additionally python.exe and python3.exe exist in the path as stubs that further complicate things.
    $envvarPathsToAdd.Add( [System.IO.Directory]::GetParent( (py -3 -c "import sys; print (sys.executable)")).FullName )
}
$envvarP = $null
$envvarEscP = $null
foreach ($envvarP in $envvarPathsToAdd) {   
    $envvarEscP = [regex]::Escape($envvarP) 
    if ($env:Path -notmatch $envvarEscP ) {
        $env:Path += "$envvarPathSeperator$envvarP"
    }
}


# Allows `pwsh` `help` function to use nicer pager program than `more` for easier paging
$env:PAGER = 'less'
$lessDefaultParams = '--raw-control-chars --ignore-case --quit-if-one-screen --quiet'

# less.exe Settings
$env:LESS = $lessDefaultParams # Options which are passed to less.exe automatically.
$env:LESSHISTFILE = "$HOME\_lesshst"
$env:LESSCHARSET = 'utf-8'
$env:VISUAL = 'code' # Read by less.exe. Otherwise vi is the default. EDITOR is used also but not sure if other applications use this variable.
$env:LESSEDIT = '%E ?l--goto %g\:%l:%g.' # If line number is known, go to it. Otherwise open the file.

# Read by git.exe. If not set, `$env:VISUAL` is used instead and 'code.cmd' exits prematurely with an empty commit.
$env:GIT_EDITOR = 'vim'

# lf.exe Terminal File Manager
$env:EDITOR = 'code' # e key mapping
$env:SHELL = 'cmd.exe' # w key mapping. Need to use cmd.exe for fzf DEFAULT_COMMAND to work.

# rg.exe (ripgrep) path to default flags
$env:RIPGREP_CONFIG_PATH = "$env:OneDrive\Documents\.ripgreprc"

# pretty pager batcat theme
$env:BAT_THEME = 'Visual Studio Dark+'
$env:BAT_PAGER = "less $lessDefaultParams"

# Class Explorer Module for pretty output. A fancy check mark in this case.
$env:CLASS_EXPLORER_TRUE_CHARACTER = [char]0x2713

# Prevent variables from clashing in current session
$helpRemoveVar = @(
    'helpRemoveVar'
    'FzfGutterColor'
    'FzfTheme'
    'FzfIconTheme'
    'FzfIcons'
    'FzfLayout'
    'FzfHistory'
    'FzfBind'
    'envvarPathSeperator'
    'envvarPathsToAdd'
    'envvarP'
    'envvarEscP'
    'lessDefaultParams'
)
Remove-Variable -Name $helpRemoveVar
