# The PM Console Host doesn't support colors. One needs to check for `$Host.Name -eq 'Package Manager Host'`
# OhMyPosh prompt
# executiontime postfix invisible spacing character for bug in wt.exe (https://github.com/JanDeDobbeleer/oh-my-posh/discussions/668)
# Had to change the hourglass icon
$ompConfigPath = Join-Path -Path $HOME -ChildPath .config | Join-Path -ChildPath 'oh-my-posh' | Join-Path -ChildPath 'night-owl_mac.omp.json'
# chezmoi HomeBrew Shell Env if block {{ if lookPath "brew" }}
& $env:HOMEBREW_PREFIX/bin/brew shellenv | Invoke-Expression
# end {{ end }}
oh-my-posh init pwsh --config $ompConfigPath | Invoke-Expression

# Custom OMP Prompt Context
function Set-MyOmpContext {
    # Update process level directory. Helps with .Net Methods.
    [System.Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-MyOmpContext' -Description 'oh-my-posh Custom alias override' -Force

Remove-Variable 'ompConfigPath'
