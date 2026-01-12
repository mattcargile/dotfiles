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
        function WriteComputerNameObject {
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
            return WriteComputerNameObject -Name $_.DNSHostName
        }
        if ('VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl' -as [type] -and
            $_ -is [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl]
        ) {
            return WriteComputerNameObject -Name $_.Name
        }
        if ('VMware.VimAutomation.ViCore.Impl.V1.VM.Guest.VMGuestImpl' -as [type] -and
            $_ -is [VMware.VimAutomation.ViCore.Impl.V1.VM.Guest.VMGuestImpl]
        ) {
            return WriteComputerNameObject -Name $_.HostName
        }
        if ('Microsoft.SqlServer.Management.RegisteredServers.RegisteredServer' -as [type] ) {
            if ( $_ -is [Microsoft.SqlServer.Management.RegisteredServers.RegisteredServer] -or
                $_ -is [Microsoft.SqlServer.Management.Smo.Server]
            ) {
                $dbaInst = [Dataplat.Dbatools.Parameter.DbaInstanceParameter]::new($_)
                return WriteComputerNameObject -Name $dbaInst.ComputerName
            }
        }
    }
}
