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
        Add-TerminalIconsColorTheme -Path "$env:OneDrive\Documents\.config\pwsh\Terminal-Icons\colorThemes\mac.psd1" -Force
        Add-TerminalIconsIconTheme -Path "$env:OneDrive\Documents\.config\pwsh\Terminal-Icons\iconThemes\mac.psd1" -Force
        if ( (Get-TerminalIconsTheme).Icon.Name -ne 'mac') {
            Set-TerminalIconsTheme -ColorTheme 'mac' -IconTheme 'mac'
        }
    }
}