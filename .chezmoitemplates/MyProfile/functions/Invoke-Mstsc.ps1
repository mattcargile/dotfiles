<#
.SYNOPSIS
    Invokes the mstsc.exe application
.DESCRIPTION
    Invokes mstsc.exe RDP application and uses cmdkey.exe for auto signing in. Credentials are deleted after usage.
.NOTES
    RemoteGuard works when network credentials are used while RestrictedAdmin works in a session with a nonelevated user.
.LINK
    
.EXAMPLE
    Invoke-Mstsc server -Credential user
    Attempts to connect via RDP protocol to Computer named server with a credential user name of user, prompting for the password in the
    process
#>
function Invoke-Mstsc {
    [Alias('irdp')]
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        # Name of Computer
        [Parameter(Mandatory,ParameterSetName = 'Default',Position=0)]
        [Parameter(Mandatory,ParameterSetName = 'RemoteGuard',Position=0)]
        [Parameter(Mandatory,ParameterSetName = 'RestrictedAdmin',Position=0)]
        [string]
        $ComputerName,
        # PSCredential to connect to server
        [Parameter(Mandatory,ParameterSetName = 'Default',Position=1)]
        [Parameter(Mandatory,ParameterSetName = 'RemoteGuard',Position=1)]
        [Parameter(Mandatory,ParameterSetName = 'RestrictedAdmin',Position=1)]
        [pscredential]
        $Credential,
        # Port for RDP. 3389 by default. Use with non-traditional port.
        [int]
        $Port = 3389,
        # Remote Guard Feature with credentials negotiated from local client. Disconnected sessions aren't vulnerabilty to pass-the-hash.
        [Parameter(ParameterSetName='RemoteGuard')]
        [switch]
        $RemoteGuard,
        # Restricted Admin feature for local admin without double hop capability and no credentials passed.
        [Parameter(ParameterSetName='RestrictedAdmin')]
        [switch]
        $RestrictedAdmin,
        # Prevent Interactive input and force failure
        [Parameter()]
        [switch]
        $Force
    )

    begin {
        $pass = $Credential.GetNetworkCredential().Password
        $usrName = $Credential.UserName
    }

    process {
        try {
            Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop | Out-Null

            # Get all IPs for a ComputerName. For instance, Web Servers have more than one IP
            # We want to check the connection based on all the IPAddresses.
            $isIpAddr = [bool]($ComputerName -as [ipaddress]) -and $ComputerName -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"
            if ($isIpAddr) {
                $ips = $ComputerName
            }
            else {
                $ips = (Resolve-DnsName -Name $ComputerName -ErrorAction 'Stop').IPAddress # DEBUG outputs seemingly random number
            }
            Write-Verbose "Computer Name IPAddress List: $($ips -join ', ')"

            # Create credentials
            # Using generic due to Windows Defender Credential Guard
            # https://superuser.com/a/1773264
            $addKeyMsg = cmdkey.exe "/generic:TERMSRV/$ComputerName" "/user:$usrName" "/pass:$pass"
            Write-Verbose $addKeyMsg[1]

            # Connect MSTSC with servername and credentials created before
            $argList =  "/v:$($ComputerName):$($Port)"
            if ($RemoteGuard) {
                $argList += ' /remoteGuard'
            }
            elseif ($RestrictedAdmin) {
                $argList += ' /restrictedAdmin'
            }
            $pMstsc = Start-Process -FilePath mstsc.exe -ArgumentList $argList -PassThru
            Write-Verbose "Starting mstsc.exe Process ID: $( $pMstsc.Id ) with arguments $argList"
            $netParm = @{
                RemoteAddress = $ips
                RemotePort = $Port
                State = 'Established'
                OwningProcess = $pMstsc.Id
                ErrorAction = 'Ignore'
            }

            # Check for connection. Prevents cmdkey from being deleted before mstsc can see it
            $conMstsc = Get-NetTCPConnection @netParm
            if ($conMstsc -and $VerbosePreference -ne 'SilentlyContinue') {
                Write-Verbose "NetTCP Connection 1: $( $conMstsc.RemoteAddress ):$( $conMstsc.RemotePort ) $( $conMstsc.State )"
            }
            $conAttempts = 3
            $conCtr = 0
            while (-not $conMstsc -and $conCtr -le $conAttempts) {
                Write-Verbose "TCP Established Check Counter: $conCtr"
                Start-Sleep -Milliseconds 400
                $conMstsc = Get-NetTCPConnection @netParm
                if ($conMstsc -and $VerbosePreference -ne 'SilentlyContinue') {
                    Write-Verbose "NetTCP Connection Loop: $( $conMstsc.RemoteAddress ):$( $conMstsc.RemotePort ) $( $conMstsc.State )"
                }
                if ($Force) {
                    $conCtr++
                    continue
                }
                elseif ($conCtr -lt $conAttempts) {
                    $conCtr++
                    continue
                }
                elseif ($conCtr -eq $conAttempts) {
                    if ($PSCmdlet.ShouldContinue('Wait period passed. Continue checking for a connection?', 'Check connection')) {
                        $conCtr = 0
                    }
                    $conCtr++
                    continue
                }
            }
            if ($conCtr -gt $conAttempts) {
                Write-Error 'Could not establish TCP Connect in the defined time limit.'
            }
        }
        catch {
            Write-Error -ErrorRecord $_
        }
        finally {
            # Delete the credentials after MSTSC session is done
            $delKeyMsg = cmdkey.exe "/delete:TERMSRV/$ComputerName"
            Write-Verbose $delKeyMsg[1]
        }
    }

    end {
    }
}