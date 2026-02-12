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
filter ConvertTo-ComputerName {
    [CmdletBinding()]
    [Alias('ctcn')]
    param (
        # Object to convert into friendly name
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [Alias('io')]
        [object[]]
        $InputObject,
        # Whether to include the $InputObject in the output object
        [Parameter()]
        [Alias('iio')]
        [switch]
        $IncludeInputObject
    )
    foreach ($currentInputObject in $InputObject) {
        $propertyName = $null
        $secondPropertyName = $null
        if ('Microsoft.ActiveDirectory.Management.ADComputer' -as [type] -and $currentInputObject -is [Microsoft.ActiveDirectory.Management.ADComputer]) {
            if ([string]::IsNullOrWhiteSpace($currentInputObject.DNSHostName)) {
                $propertyName = 'Name'
            }
            else {
                $propertyName = 'DNSHostName'
            }
        }
        elseif ('VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl' -as [type] -and
            (
                $currentInputObject -is [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl] -or
                $currentInputObject -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl] # -Tag outputs different type
            )
        ) {
            $propertyName = 'Name'
        }
        elseif ('VMware.VimAutomation.ViCore.Impl.V1.VM.Guest.VMGuestImpl' -as [type] -and
            $currentInputObject -is [VMware.VimAutomation.ViCore.Impl.V1.VM.Guest.VMGuestImpl]
        ) {
            if ([string]::IsNullOrWhiteSpace($currentInputObject.HostName)) {
                $propertyName = 'VM'
                $secondPropertyName = 'Name'
            }
            else {
                $propertyName = 'HostName'
            }
        }
        elseif ('Dataplat.Dbatools.Parameter.DbaInstanceParameter' -as [type] -and # Assuming dbatools is imported along with below classes
            (
                $currentInputObject -is [Microsoft.SqlServer.Management.RegisteredServers.RegisteredServer] -or
                $currentInputObject -is [Microsoft.SqlServer.Management.Smo.Server]
            )
        ) {
            $currentInputObject = [Dataplat.Dbatools.Parameter.DbaInstanceParameter]::new($currentInputObject)
            $propertyName = 'ComputerName'
        }
        elseif ($currentInputObject.psobject.Properties.Name -contains 'PSComputerName' -and -not [string]::IsNullOrWhiteSpace($currentInputObject.PSComputerName)) {
            $propertyName = 'PSComputerName'
        }
        elseif ($currentInputObject.psobject.Properties.Name -contains 'DNSHostName' -and -not [string]::IsNullOrWhiteSpace($currentInputObject.DNSHostName)) {
            $propertyName = 'DNSHostName'
        }
        elseif ($currentInputObject.psobject.Properties.Name -contains 'HostName' -and -not [string]::IsNullOrWhiteSpace($currentInputObject.HostName)) {
            $propertyName = 'HostName'
        }
        elseif ($currentInputObject.psobject.Properties.Name -contains 'ComputerName' -and -not [string]::IsNullOrWhiteSpace($currentInputObject.ComputerName)) {
            $propertyName = 'ComputerName'
        }
        elseif ($currentInputObject.psobject.Properties.Name -contains 'ServerName' -and -not [string]::IsNullOrWhiteSpace($currentInputObject.ServerName)) {
            $propertyName = 'ServerName'
        }
        elseif ($currentInputObject.psobject.Properties.Name -contains 'Name' -and -not [string]::IsNullOrWhiteSpace($currentInputObject.Name)) {
            $propertyName = 'Name'
        }

        if ($secondPropertyName) {
            if ($IncludeInputObject) {
                [PSCustomObject]@{
                    ComputerName = $currentInputObject.$propertyName.$secondPropertyName
                    InputObject = $InputObject
                }
            }
            else {
                [PSCustomObject]@{
                    ComputerName = $currentInputObject.$propertyName.$secondPropertyName
                }
            }
        }
        elseif ($propertyName) {
            if ($IncludeInputObject) {
                [PSCustomObject]@{
                    ComputerName = $currentInputObject.$propertyName
                    InputObject = $InputObject
                }
            }
            else {
                [PSCustomObject]@{
                    ComputerName = $currentInputObject.$propertyName
                }
            }
        }
        else {
            if ($IncludeInputObject) {
                [PSCustomObject]@{
                    ComputerName = [string]$currentInputObject
                    InputObject = $InputObject
                }
            }
            else {
                [PSCustomObject]@{
                    ComputerName = [string]$currentInputObject
                }
            }
        }
    }
}
