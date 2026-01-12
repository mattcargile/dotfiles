function Open-VMConsole {
    [CmdletBinding()]
    [Alias('opvmc')]
    param(
        # VM Name
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('Name', 'VM')]
        [object[]]
        $VMName
    )
    process {
        $vmlist = 
            foreach ($vm in $VMName) {
                if ($vm -is [string]) {
                    Write-Verbose "Converting String input ($($vm)) to VM object"
                    try {
                        VMware.VimAutomation.Core\Get-VM $vm -ErrorAction "Stop"
                    }
                    catch {
                        Write-Error "Unable to find VM: $($PSItem)"
                        continue
                    }
                }
                elseif ($vm -is [VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl] -or
                    $vm -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl] # -Tag outputs different type
                ) {
                    $vm
                }
                else {
                    Write-Warning "Input of invalid object of type $($vm.GetType())"
                }
            }
            
        foreach ($vm in $vmlist) {
            try {
                $currentVcenterServer = $vm.GetClient().Config.Server
                $SessMngr = VMware.VimAutomation.Core\Get-View -id SessionManager -Server $currentVcenterServer -ErrorAction Stop
                $ticket = $SessMngr.AcquireCloneTicket()
            }
            catch {
                Write-Error "Unable to get session ticket: $($PSItem)"
                continue
            }
            try {
                $vmrcUri = "vmrc://clone:$($ticket)@$currentVcenterServer/?moid=$($vm.ExtensionData.MoRef.Value)"

                Write-Verbose "Opening URL: $($vmrcUri)"
                Start-Process $vmrcUri -ErrorAction Stop
            }
            catch {
                Write-Error "Unable to open console for vm '$($vm)': $($PSItem)"
            }
        }
    }
}
