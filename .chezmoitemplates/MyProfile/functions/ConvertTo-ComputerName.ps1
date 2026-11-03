<#
.SYNOPSIS
    Convert objects to friendly computer objects for downstream cmdlets
.DESCRIPTION
    Convert complex or poorly designed objects like ADComputer to consistent and stable PSCustomObjects
.NOTES
    Began this journey because ADComputer object dynamically creates object upon selection making piping to cmdlets like Get-CimInstance troublesome
.EXAMPLE
    Get-ADComputer Computer | ConvertTo-ComputerName | Get-CimInstance Win32_OperatingSystem
    Gets the ADComputer for Computer and converts to friendly object and then pipes into Get-CimInstance to retreive the Win32_OperatingSystem object
.EXAMPLE
    Get-ADComputer Computer | ConvertTo-ComputerName -Property Name
    Returns an object with the resolved computer name in its Name property
.EXAMPLE
    Get-ADComputer Computer | ConvertTo-ComputerName -ExpandProperty
    Returns the resolved computer name directly
#>
filter ConvertTo-ComputerName {
    [CmdletBinding(DefaultParameterSetName = 'Property')]
    [Alias('ctcn')]
    param (
        # Object to convert into friendly name
        [Parameter(Mandatory, ValueFromPipeline, Position = 1)]
        [Alias('io')]
        [object[]]
        $InputObject,
        # Property name for the output
        [Parameter(Position = 0, ParameterSetName = 'Property')]
        [Alias('p')]
        [string]
        $Property = 'ComputerName',
        # Return the resolved computer name directly
        [Parameter(ParameterSetName = 'ExpandProperty')]
        [Alias('e')]
        [switch]
        $ExpandProperty,
        # Whether to include the $InputObject in the output object
        [Parameter(ParameterSetName = 'Property')]
        [Alias('iio')]
        [switch]
        $IncludeInputObject
    )
    foreach ($currentInputObject in $InputObject) {
        if ('Microsoft.ActiveDirectory.Management.ADComputer' -as [type] -and $currentInputObject -is [Microsoft.ActiveDirectory.Management.ADComputer]) {
            if ([string]::IsNullOrWhiteSpace($currentInputObject.DNSHostName)) {
                $computerName = $currentInputObject.Name
            }
            else {
                $computerName = $currentInputObject.DNSHostName
            }
        }
        elseif ('VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl' -as [type] -and
            (
                $currentInputObject -is [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl] -or
                $currentInputObject -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl] # -Tag outputs different type
            )
        ) {
            $computerName = $currentInputObject.Name
        }
        elseif ('VMware.VimAutomation.ViCore.Impl.V1.VM.Guest.VMGuestImpl' -as [type] -and
            $currentInputObject -is [VMware.VimAutomation.ViCore.Impl.V1.VM.Guest.VMGuestImpl]
        ) {
            if ([string]::IsNullOrWhiteSpace($currentInputObject.HostName)) {
                $computerName = $currentInputObject.VM.Name
            }
            else {
                $computerName = $currentInputObject.HostName
            }
        }
        elseif ('Dataplat.Dbatools.Parameter.DbaInstanceParameter' -as [type] -and # Assuming dbatools is imported along with below classes
            (
                $currentInputObject -is [Microsoft.SqlServer.Management.RegisteredServers.RegisteredServer] -or
                $currentInputObject -is [Microsoft.SqlServer.Management.Smo.Server]
            )
        ) {
            $computerName = [Dataplat.Dbatools.Parameter.DbaInstanceParameter]::new($currentInputObject).ComputerName
        }
        else {
            $computerName = $null
            foreach ($propertyName in 'PSComputerName', 'DNSHostName', 'HostName', 'ComputerName', 'ServerName', 'Name') {
                $candidateProperty = $currentInputObject.psobject.Properties[$propertyName]
                if ($null -ne $candidateProperty -and -not [string]::IsNullOrWhiteSpace($candidateProperty.Value)) {
                    $computerName = $candidateProperty.Value
                    break
                }
            }

            if ($null -eq $computerName) {
                $computerName = [string]$currentInputObject
            }
        }

        if ($ExpandProperty) {
            $computerName
        }
        else {
            $outputProperties = [ordered]@{ $Property = $computerName }
            if ($IncludeInputObject) {
                $outputProperties['InputObject'] = $currentInputObject
            }
            [PSCustomObject]$outputProperties
        }
    }
}
