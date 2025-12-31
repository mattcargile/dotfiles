function Enter-PSSessionBusy {
    [Alias('etsnb')]
    [CmdletBinding(DefaultParameterSetName='ComputerName')]
    param (
        # The ComputerName
        [Parameter(Mandatory,Position=0,ParameterSetName='SessionInstanceId')]
        [Parameter(Mandatory,Position=0,ParameterSetName='SessionName')]
        [Parameter(Mandatory,Position=0,ParameterSetName='ComputerName')]
        [Alias('cn')] 
        [string]
        $ComputerName,
        # The Session ID
        [Parameter(Position=1,ParameterSetName='InstanceId')]
        [guid]
        $InstanceId,
        # The Friendly Name of the Session
        [Parameter(Position=2,ParameterSetName='SessionName')]
        [string]
        $Name
    )
    
    begin {
        $PSBoundParameters.ErrorAction = 'Ignore'
        $allSes = Get-PSSession @PSBoundParameters
        $ses = $allSes | Where-Object Availability -eq 'Busy' | Sort-Object Id -Descending | Select-Object -First 1
        if (-not $ses) {
            $openSes = $allSes | Where-Object { $_.Availability -in @('None', 'Available') -and $_.State -in @('Disconnected', 'Opened')} | Sort-Object Id -Descending | Select-Object -First 1
            if ($openSes) {
                Enter-PSSession $openSes
                return
            }
            else {
                Write-Warning "Cannot find any busy or available PowerShell sessions with the provided parameters on $ComputerName."
                return
            }
        }
        $toCheckSn = Get-PSSession -ComputerName $ses.ComputerName -InstanceId $ses.InstanceId | Where-Object Availability -ne 'Busy'
        $progParms = @{
            Activity = 'Checking PSSession Availability'
        }
        # May be default 4 minute Timeout on Server Side. Increasing it to allow the full 4 minute to pass.
        $totalSecondsToWait = 10 * 60
        $secRemaining = $totalSecondsToWait
        $secondsBtwn = 10
        $totalIncrements = $totalSecondsToWait / $secondsBtwn
        $attempts = 1
        $percentComp = 0
        while (-not $toCheckSn) {
            $progParms.Status = "Attempt #$attempts"
            $progParms.SecondsRemaining = $secRemaining
            $progParms.PercentComplete = $percentComp
            Write-Progress @progParms
            $attempts++
            $secRemaining = $secRemaining - $secondsBtwn
            $percentComp = [System.Math]::Ceiling( $attempts / $totalIncrements * 100 )
            if ($secRemaining -le 0 -or $percentComp -gt 100) {
                Write-Warning "Could not reconnect to session with InstanceId of $($ses.InstanceId) on $ComputerName in the time allotted ( $totalSecondsToWait sec )."
                return
            }
            Start-Sleep -Seconds $secondsBtwn
            $toCheckSn = Get-PSSession -ComputerName $ses.ComputerName -InstanceId $ses.InstanceId | Where-Object Availability -ne 'Busy' 
        }
        Enter-PSSession $toCheckSn
    }
    
    process {
    }
    
    end {
    }
}