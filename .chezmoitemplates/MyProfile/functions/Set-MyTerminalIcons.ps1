function Set-MyTerminalIcons {
    [CmdletBinding()]
    [Alias('smyticn')]
    param (
    )
    
    begin {
    }
    
    process {
    }
    
    end {
        Add-TerminalIconsColorTheme -Path ( [System.IO.Path]::Combine( [string[]]@( $HOME, '.config', 'powershell', 'Terminal-Icons', 'colorThemes', 'mac.psd1' ) ) ) -Force
        Add-TerminalIconsIconTheme -Path ( [System.IO.Path]::Combine( [string[]]@( $HOME, '.config', 'powershell', 'Terminal-Icons', 'iconThemes', 'mac.psd1' ) ) ) -Force
        if ( (Get-TerminalIconsTheme).Icon.Name -ne 'mac') {
            Set-TerminalIconsTheme -ColorTheme 'mac' -IconTheme 'mac'
        }
    }
}