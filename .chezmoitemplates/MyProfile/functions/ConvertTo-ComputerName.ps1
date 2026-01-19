<#
.SYNOPSIS
    Convert objects to friendly computer objects for downstream cmdlets
.DESCRIPTION
    Convert complex or poorly designed objects like ADComputer to consistent and stable PSCustomObjects
.NOTES
    Began this journey because ADComputer object dynamically creates object upon selection making piping to cmdlets like Get-CimInstance troublesome
.EXAMPLE
    Get-ADComputer Computer | ConverTo-ComputerName | Get-CimInstance Win32_OperatingSystem
    Gets the ADComputer for Computer and converts to friendly object and then pipes into Get-CimInstance to retreive the Win32_OperatingSystem object
#>
function ConvertTo-ComputerName {
    [CmdletBinding()]
    [Alias('ctcn')]
    param (
        # Object to convert into friendly name
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]
        $InputObject
    )
    
    begin {
        function Write-ComputerNameObject {
            [CmdletBinding()]
            param (
                [string]
                $Name
            )
            end {
                [PSCustomObject]@{
                    ComputerName = $Name
                }
            }
        }
        
    }

    process {
        if ('Microsoft.ActiveDirectory.Management.ADComputer' -as [type] -and $_ -is [Microsoft.ActiveDirectory.Management.ADComputer]) {
            return Write-ComputerNameObject -Name $_.DNSHostName
        }
        if ('VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl' -as [type] -and
            (
                $_ -is [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl] -or
                $_ -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl] # -Tag outputs different type
            )
        ) {
            return Write-ComputerNameObject -Name $_.Name
        }
        if ('VMware.VimAutomation.ViCore.Impl.V1.VM.Guest.VMGuestImpl' -as [type] -and
            $_ -is [VMware.VimAutomation.ViCore.Impl.V1.VM.Guest.VMGuestImpl]
        ) {
            return Write-ComputerNameObject -Name $_.HostName
        }
        if ('Dataplat.Dbatools.Parameter.DbaInstanceParameter' -as [type] -and # Assuming dbatools is imported along with below classes
            (
                $_ -is [Microsoft.SqlServer.Management.RegisteredServers.RegisteredServer] -or
                $_ -is [Microsoft.SqlServer.Management.Smo.Server]
            )
        ) {
            $dbaInst = [Dataplat.Dbatools.Parameter.DbaInstanceParameter]::new($_)
            return Write-ComputerNameObject -Name $dbaInst.ComputerName
        }
        if ($_.psobject.Properties.Name -contains 'PSComputerName') {
            return Write-ComputerNameObject -Name $_.PSComputerName
        }
        if ($_.psobject.Properties.Name -contains 'DNSHostName') {
            return Write-ComputerNameObject -Name $_.DNSHostName
        }
        if ($_.psobject.Properties.Name -contains 'HostName') {
            return Write-ComputerNameObject -Name $_.HostName
        }
        if ($_.psobject.Properties.Name -contains 'ComputerName') {
            return Write-ComputerNameObject -Name $_.ComputerName
        }
        if ($_.psobject.Properties.Name -contains 'ServerName') {
            return Write-ComputerNameObject -Name $_.ServerName
        }
        if ($_.psobject.Properties.Name -contains 'Name') {
            return Write-ComputerNameObject -Name $_.Name
        }
        return Write-ComputerNameObject -Name ([string]$_)
    }
}
