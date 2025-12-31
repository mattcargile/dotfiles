# Invoke-Item with fzf filter at current path or path passed in.
function Invoke-FzfItem {
    [Alias('ifzfi')]
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Path
    )
    try { 
        if ($Path) {
            Write-Verbose -Message "Push Location $Path"
            Push-Location -Path $Path
        }
        $f = & fd.exe --type file | fzf.exe --multi --preview-window 'right:60%' --preview 'bat --color=always --style=header,grid --line-range :300 {}'
        if ($null -ne $f) { $fResolve = Resolve-Path -Path $f }
        else { return }
    }
    catch {
        return
    }
    finally {
        if ($Path) {
            Write-Verbose -Message "Pop Location"
            Pop-Location
        }
    }
    
    Write-Verbose -Message "`$f -ne `$null. `$f: $($f -join ',') Invoke-Item returned from fzf"
    Invoke-Item -Path ( $fResolve )
}