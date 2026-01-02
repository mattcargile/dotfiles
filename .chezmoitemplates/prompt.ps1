# ZLocation. Current build on PSGallery is broken. Problem with Error Handling. oh-my-posh prompt code 
# needs to be first to get the errors within the function:\prompt.
# https://github.com/vors/ZLocation/issues/117
# Loading first in file to prevent pwsh.exe from auto loading the wrong module.
# Applicable Function added to Set-MyOmpContext
<#$ZLocationParam = @{
    Name = "$PSScriptRoot\ZLocation\ZLocation\ZLocation\ZLocation.psd1"
    ArgumentList = @{ AddFrequentFolders = $false; RegisterPromptHook = $false }
}
Import-Module @ZLocationParam#>

# The PM Console Host doesn't support colors. One needs to check for `$Host.Name -eq 'Package Manager Host'`
# OhMyPosh prompt
# executiontime postfix invisible spacing character for bug in wt.exe (https://github.com/JanDeDobbeleer/oh-my-posh/discussions/668)
# Had to change the hourglass icon
$OhMyPoshConfig = "$env:OneDrive\Documents\oh-my-posh\themes\night-owl_mac.omp.json"
if ($IsCoreCLR) { oh-my-posh.exe init pwsh --config $OhMyPoshConfig | Invoke-Expression }
else { oh-my-posh.exe init powershell --config $OhMyPoshConfig | Invoke-Expression }

# Custom OMP Prompt Context
function Set-MyOmpContext {
    # Update process level directory. Helps with .Net Methods.
    [System.Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath

    # Update ZLocation Module database
    # Poor interplay with PSModuleDevelopment's find aliased command
    # https://github.com/PowershellFrameworkCollective/PSModuleDevelopment/issues/214
    # Update-ZLocation $PWD

    <#
    #region Cisco Any Connect Vpn
    $CimClass = 'Win32_NetworkAdapterConfiguration'
    $CimFilter = "ServiceName = 'vpnva'"
    $IPEnabled = (Get-CimInstance -ClassName $CimClass -Filter $CimFilter -Verbose:$false -ErrorAction Ignore -Property IPEnabled).IPEnabled
    if( $IPEnabled ) {
        $env:OMP_ANYCONNECT = [char]0xF0AC # nf-fa-globe
    }
    else { Remove-Item -Path Env:\OMP_ANYCONNECT -ErrorAction Ignore }
    #endregion 
    #region VIServer Connection envvar
    if (${global:DefaultVIServer} -and -not $env:OMP_VISERVER) {
        $env:OMP_VISERVER = [char]0xF24D # nf-fa-clone
        $global:omp_lastVIServerConn = Get-Date
    }
    elseif ( ${global:DefaultVIServer} -and $env:OMP_VISERVER -and 
    ( ( Get-Date ) - $omp_lastVIServerConn ).TotalHours -ge 7.0 ){
        try{ $conn = VMware.VimAutomation.Core\Get-Datacenter } catch{}
        if($conn) { $global:omp_lastVIServerConn = Get-Date }
        else {
            # $null out ${global:DefaultVIServer} and ${global:DefaultVIServers}
            VMWare.VimAutomation.Core\Disconnect-VIServer -Confirm:$false -ErrorAction Ignore | Out-Null
            Remove-Item -Path Env:\OMP_VISERVER -ErrorAction Ignore
            Remove-Variable -Name omp_lastVIServerConn -Scope Global -ErrorAction Ignore
        }
    }
    elseif (-not ${global:DefaultVIServer} -and $env:OMP_VISERVER) {
        Remove-Item -Path Env:\OMP_VISERVER
    }
    #endregion
    #>
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-MyOmpContext' -Description 'oh-my-posh Custom alias override' -Force

# Import last to avoid interference with `$?` variable and `$LASTEXITCODE`
Import-Module ZLocation2

# Prevent variable clutter in Get-Variable Output
# Remove-Variable -Name OhMyPoshConfig, ZLocationParam
Remove-Variable -Name OhMyPoshConfig
