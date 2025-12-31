<#
.SYNOPSIS
    Creates a Powershell Proxy Command from an existing command
.DESCRIPTION
    Uses the CommandMetadata and ProxyCommand class and Create method to output the text to a file.
.LINK
    https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.proxycommand?view=powershellsdk-7.3.0
.EXAMPLE
    New-ProxyCommand Get-Command .\t.ps1
    Will create a t.ps1 powershell file with the the function Get-Command inside.
#>
function New-ProxyCommand {
    [Alias('npxc')]
    [CmdletBinding()]
    param (
        # Name of Cmdlet
        [Parameter(Mandatory,Position=0)]
        [string]
        $Name,
        # Destination File Path
        [Parameter(Mandatory,ParameterSetName='Path',Position=1)]
        [Alias('pt')]
        [string]
        $Path,
        # Pass through the text to output
        [Parameter(ParameterSetName='PassThru')]
        [Alias('pa')]
        [switch]
        $PassThru,
        # Force creation in current directory with same name as command
        [Parameter(ParameterSetName='Force')]
        [Alias('f')]
        [switch]
        $Force
    )
    
    end {
        $data = New-Object System.Management.Automation.CommandMetaData (Get-Command $Name)
        if ($Force) {
            $Path = ".\$Name.ps1"
        }
        $prxCmd = [System.Management.Automation.ProxyCommand]::Create($data)
        switch ($PSCmdlet.ParameterSetName) {
            'Path' { $prxCmd | Set-Content -Path $Path }
            'PassThru' { $prxCmd }
            Default { throw "Invalid Parameter Set" }
        }
    }
}