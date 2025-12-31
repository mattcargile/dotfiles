function global:Import-InvokePSSession {
    [Alias('ipisn')]
    [CmdletBinding()]
    param (
        # Name of Computer / FQDN
        [Parameter(Mandatory)]
        [string]
        $ComputerName,
        # Modules or PSSnapins to Import
        [string[]]
        $Module,
        # PSCredential for CredSsp
        [pscredential]
        $Credential
    )
    $newPSSessionSplat = @{
        ComputerName = $ComputerName
        ConfigurationName = 'Microsoft.PowerShell'
    }
    # Guess if passing in "localhost" so PSSnapins like '*TeamFoundation*' can work
    # Not super robust. See below.
    # https://stackoverflow.com/questions/28048337/how-to-check-in-powershell-if-ip-address-or-hostname-is-a-localhost-without-dom
    if ($ComputerName -in @('.', 'localhost',"$(hostname)", "$(hostname).$env:USERDNSDOMAIN")) {
        $newPSSessionSplat.Authentication = 'CredSsp'
        $newPSSessionSplat.Credential = $Credential
    }

    $nsn = New-PSSession @newPSSessionSplat
    Invoke-Command -Session $nsn -ScriptBlock {
        $i=$null
        foreach ($i in $using:Module) {
            if (Get-PSSnapin -Registered -Name $i -ErrorAction 'SilentlyContinue') {
                Add-PsSnapin -Name $i
            }
            else {
                Import-Module -Name $i
            }
        }
    }
    $sn = Import-PSSession -Session $nsn -Module $Module
    # Handling scope. Need to Import-Module or else the PSSession Import is lost
    Import-Module -ModuleInfo $sn -Scope 'Global'
}