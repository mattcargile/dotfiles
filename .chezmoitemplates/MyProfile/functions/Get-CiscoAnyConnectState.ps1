function Get-CiscoAnyConnectState {
    [Alias('gvpn')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Low')]
    param (
    )

    $vpnCliDef = Get-Command -Name 'vpncli*' | Select-Object -First 1 -ExpandProperty 'Definition'
    if(-not $vpnCliDef -or -not (Test-Path $vpnCliDef)) {
        Write-Error 'Cannot find vpncli.exe. Add as alias or to $env:Path. Install instructions here: https://www.cisco.com/c/en/us/support/docs/smb/routers/cisco-rv-series-small-business-routers/smb5686-install-cisco-anyconnect-secure-mobility-client-on-a-windows.html' -Category ObjectNotFound
        return
    }

    if ($PSCmdlet.ShouldProcess("$(hostname)", "Run vpncli.exe stats")) {
        $output = & $vpnCliDef stats | Where-Object { $_ -ne '' -and $_ -ne 'VPN> ' -and $_ -notlike '  >> *' }
        Write-Verbose ( ( $output -ne '' ) -join "$([System.Environment]::NewLine)" )
        
        # Splits on first colon (:) so second item is the data point.
        Write-Output ( [PSCustomObject]@{
            ConnectionState = ($output[3] -split ':',2)[1].Trim()
            TunnelModeIPv4 = ($output[4] -split ':',2)[1].Trim()
            TunnelModeIPv6 = ($output[5] -split ':',2)[1].Trim()
            DynamicTunnelExclusion = ($output[6] -split ':',2)[1].Trim()
            DynamicTunnelInclusion = ($output[7] -split ':',2)[1].Trim()
            Duration = if(($output[8] -split ':',2)[1].Trim() -ne 'Not Available' ) { [timespan]($output[8] -split ':',2)[1].Trim() } else { $null }
            SessionDisconnect = ($output[9] -split ':',2)[1].Trim()
            ClientAddressIPv4 = if( ($output[12] -split ':',2)[1].Trim() -ne 'Not Available' ) { [ipaddress]($output[12] -split ':',2)[1].Trim() } else { $null }
            ClientAddressIPv6 = if( ($output[13] -split ':',2)[1].Trim() -ne 'Not Available' ) { [ipaddress]($output[13] -split ':',2)[1].Trim() } else { $null }
            ServerAddress = if ( ($output[14] -split ':',2)[1].Trim() -ne 'Not Available' ) { [ipaddress]($output[14] -split ':',2)[1].Trim() } else { $null }
            BytesSent = if ( ($output[16] -split ':',2)[1].Trim() -ne 'Not Available' ) { [int64]($output[16] -split ':',2)[1].Trim() } else { [int64]0 }
            BytesReceived = if ( ($output[17] -split ':',2)[1].Trim() -ne 'Not Available' ) { [int64]($output[17] -split ':',2)[1].Trim() } else { [int64]0 }
            PacketsSent = if ( ($output[19] -split ':',2)[1].Trim() -ne 'Not Available' ) { [int64]($output[19] -split ':',2)[1].Trim() } else { [int64]0 }
            PacketsReceived = if ( ($output[20] -split ':',2)[1].Trim() -ne 'Not Available' ) { [int64]($output[20] -split ':',2)[1].Trim() } else { [int64]0 }
            ControlPacketsSent = if ( ($output[22] -split ':',2)[1].Trim() -ne 'Not Available' ) { [int64]($output[22] -split ':',2)[1].Trim() } else { [int64]0 }
            ControlPacketsReceived = if ( ($output[23] -split ':',2)[1].Trim() -ne 'Not Available' ) { [int64]($output[23] -split ':',2)[1].Trim() } else { [int64]0 }
            IsConnected = if( ($output[3] -split ':',2)[1].Trim() -eq 'Connected' ) { $true } else { $false }
        } )
    }
}