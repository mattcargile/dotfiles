function Get-DbaRegServerInstanceParameter {
    [Alias('gregparm')]
    [CmdletBinding()]
    param (
        # Registered Sql Instance
        [Parameter(Mandatory)]
        [string]
        $SqlInstance,
        # SqlCredential for Get-DbaRegServer
        [pscredential]
        $SqlCredential,
        # User DNS Domain
        [string]
        $Domain = $env:USERDNSDOMAIN
    )
    
    begin {
    }
    
    process {
    }
    
    end {
        try {
            if(-not (Get-Module dbatools -ListAvailable)) {
                Write-Warning 'dbatools module is not installed. Run Install-Module dbatools.'
                return
            }
            $cimClass = 'Win32_NetworkAdapterConfiguration'
            $ciscoVpn = 'vpnva'
            $cimFilter = "IPEnabled = TRUE"
            $cimInstance = Get-CimInstance -ClassName $cimClass -Filter $cimFilter | Where-Object -FilterScript {
                $_.ServiceName -eq $ciscoVpn -or
                $_.DNSDomain -eq $Domain -or
                ( $_.DNSDomainSuffixSearchOrder -contains $Domain -and $null -eq $_.DNSDomain )
            }
            if (-not $cimInstance)  {
                Write-Warning "($cimFilter) plus DNS and Service Name filter via $cimClass CIM class doesn't return any adapter configurations. Aborting."
                return
            }

            $ins = Get-DbaRegServer -SqlInstance $SqlInstance -SqlCredential $SqlCredential -EnableException
            foreach ($i in $ins) {
                $dbaParm = [Dataplat.Dbatools.Parameter.DbaInstanceParameter]::new($i.ServerName)
                $sqlIns = $dbaParm.FullSmoName.ToLowerInvariant()
                # Mainly because of needless ',Port' add for Self for Registered Servers
                if ($dbaParm.Port -eq '1433' -and $dbaParm.InstanceName -eq 'MSSQLSERVER') {
                    $sqlIns = $dbaParm.ComputerName
                }
                [PSCustomObject]@{
                    PSTypeName = 'DataplatMac.RegisteredServer.DbaInstanceParameter'
                    SqlInstance = $sqlIns
                    ComputerName = $dbaParm.ComputerName
                    InstanceName = $dbaParm.InstanceName
                    Port = $dbaParm.Port
                    SqlInstanceMatch = "$($dbaParm.ComputerName)\$($dbaParm.InstanceName),$($dbaParm.Port)"
                    Description = if($i.Description) {$i.Description} else {$null}
                }
            }
        }
        catch {
            Write-Error $_
        }
    }
}