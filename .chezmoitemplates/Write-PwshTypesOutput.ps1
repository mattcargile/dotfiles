#Requires -Modules EZOut
[CmdletBinding()]
param (
)
end {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest

    #region Collect Types List
    $typesList = [System.Collections.Generic.List[string]]::new()

    #region CimInstance
    $writeTypeViewSplat = @{
        TypeName = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_OperatingSystem'
        ScriptProperty = @{
            Uptime = { [OutputType('System.TimeSpan')]param() (Get-Date) - $this.LastBootUpTime }
        }
    }
    $typesList.Add( ( Write-TypeView @writeTypeViewSplat ) )

    $cimCustomWin32ProcessClassBase = 'MacMicrosoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Process'
    $writeTypeViewSplat = @{
        TypeName = $cimCustomWin32ProcessClassBase
        ScriptProperty = @{
            WSMb = { [OutputType('double')]param() [Math]::Round( $this.WorkingSetSize / 1MB, 2 ) }
            CPUSec = { [OutputType('double')]param() [Math]::Round( ( $this.UserModeTime + $this.KernelModeTime ) / 100000000, 2 ) }
        }
        AliasProperty = @{
            Pid = 'ProcessId'
        }
    }
    $typesList.Add( ( Write-TypeView @writeTypeViewSplat ) )

    $writeTypeViewSplat = @{
        TypeName = "$cimCustomWin32ProcessClassBase#IncludeUser"
        ScriptProperty = @{
            Owner = { [OutputType('string')]param() $this | Invoke-CimMethod -MethodName GetOwner } 
            User = { [OutputType('string')]param() $this.Owner.User } 
            UserDomain = { [OutputType('string')]param() $this.Owner.Domain } 
        }
    }
    $typesList.Add( ( Write-TypeView @writeTypeViewSplat ) )

    $writeTypeViewSplat = @{
        TypeName = "$cimCustomWin32ProcessClassBase#IncludeCPUPercentage"
        ScriptProperty = @{
            CPUPercentage = {
                [OutputType('double')]
                param()
                $getCimInstanceSplat = @{
                    ClassName = 'Win32_PerfFormattedData_PerfProc_Process'
                    Property = 'PercentProcessorTime', 'IDProcess'
                    ComputerName =  $this.CSName
                    Filter = "( IDProcess = 0 AND Name = '_Total') OR ( IDProcess = $($this.ProcessId))"
                }
                $procTime = Get-CimInstance @getCimInstanceSplat | Sort-Object -Property IDProcess, Name
                $procTimeTotal = $procTime[0].PercentProcessorTime
                $procTimeProcess = $procTime[1].PercentProcessorTime
                [Math]::Round( $procTimeProcess / $procTimeTotal, 2 )
            }
        }
    }
    $typesList.Add( ( Write-TypeView @writeTypeViewSplat ) )
    #endregion

    #endregion

    #region Output Types Xml
    $typesList | Out-TypeData
    #endregion
}
