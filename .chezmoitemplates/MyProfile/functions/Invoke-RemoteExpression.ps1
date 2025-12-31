<#
.SYNOPSIS
    Invoke a Windows PowerShell expression on a remote machine.
.DESCRIPTION
    Using sysinternals tool psexec to call cmd /C powershell
    on a remote machine returning XML deserialized as PS objects.
.EXAMPLE
    PS C:\> Invoke-RemoteExpression servername {Get-Service}

    Get all services from servername
.EXAMPLE
    PS C:\> Get-Content .\t.txt |
        ForEach-Object {
            Invoke-RemoteExpression -Computer $PSItem -ScriptBlock {
                gps | select @{l='computer'; e={$env:COMPUTERNAME}
            }, ProcessName, Handles, CPU -first 2 }
        }

    Iterates over CRLF delimited computer name list pulling down a particular
    set of properties from Get-Process while adding the ComputerName.
.INPUTS
    None
.OUTPUTS
    Deserialized version of WindowsPowerShell output
.NOTES
    Write-Error Note: psexec appears to chop off some error messages under
    certain conditions. This causes a red error screen and the XML output
    must be parsed manually to find the error. There is potential to parse
    the beginning of the XML for the applicable error.
.LINK
    psexec Docs: https://docs.microsoft.com/en-us/sysinternals/downloads/psexec
.LINK
    Lee Holmes Reference: https://www.leeholmes.com/using-powershell-and-psexec-to-invoke-expressions-on-remote-computers/
#>
function Invoke-RemoteExpression {
    [Alias('ire')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param(
      # Name of Computer
      [string]
      $ComputerName = $env:COMPUTERNAME,
      # Script Block of commands {}
      [Parameter(Mandatory)]
      [scriptblock]
      $ScriptBlock,
      # PSCredential
      [pscredential]
      $Credential,
      # Executes powershell.exe with -NoProfile flag
      [switch]
      $NoProfilePowerShell,
      # Executes psexec.exe with -e flag to not load the specified account's profile
      [switch]
      $NoProfilePsexec,
      # Timeout in seconds for psexec.exe
      [int]
      $Timeout,
      # Uses psexec instead of psexec64 for 32 bit systems
      [switch]
      $PsExec32,
      # Run as System with -s flag on psexec
      [switch]
      $AsSystem,
      # Name of Service on Remote Machine.
      # Useful if service name is already running on machine.
      [string]
      $RemoteService,
      # Run as limited user
      [Parameter()]
      [switch]
      $LimitedUser
      )
      
    #region Dependency Check
    $psexec = 'psexec64'
    if ($PsExec32) { $psexec = 'psexec' }
    if (-not (Get-Command $psexec -CommandType Application -ErrorAction Ignore)) {
        Write-Warning "Cannot find $psexec. Install the application or add location to the PATH environment variable."
        return
    }        
    #endregion


    #region Prepare the command line for PsExec.
    # Using the XML output encoding so that PowerShell can convert
    # the output back into structured objects.
    $commandLine = "echo . | powershell -NoLogo -OutputFormat XML "
    $newLine = [System.Environment]::NewLine

    if($NoProfilePowerShell) { $commandLine += "-NoProfile "  }
    if($RemoteService){ $psexec += " -r ```"$RemoteService```""}
    if($LimitedUser) { $psexec += ' -l'}
    if($NoProfilePsexec) { $psexec += ' -e'}
    if($AsSystem) { $psexec += ' -s'}
    if($TimeoutPsexec) { $psexec += " -n $Timeout"}
    if($Credential) {
        $psexec += " -u $($Credential.UserName)"
        $psexec += " -p ```"$($Credential.GetNetworkCredential().Password)```""
    }

    # Disable the ProgressPreference. This feature causes the Progress Stream to go to standard error and dump
    # the standard out. InformationVariable MessageData returns _CLIXML_ with `Preparing modules for first use`
    $ScriptBlock = [scriptblock]::Create("`$ProgressPreference='SilentlyContinue'; $ScriptBlock")
    # Convert the command into an encoded command for PowerShell
    $commandBytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptBlock)
    $encodedCommand = [System.Convert]::ToBase64String($commandBytes)
    $commandLine += "-EncodedCommand $encodedCommand"
    #endregion

    #region Collect the error output
    $errorOutput = 'Temp File' # For -WhatIf
    if ($PSCmdlet.ShouldProcess("$env:COMPUTERNAME", "Create Temp File Name using Path::GetTempFileName")) {
        $errorOutput = [System.IO.Path]::GetTempFileName()
    }
    # If -Whatif, provide filename without creating it. Otherwise the command below would be incomplete.
    if ($WhatIfPreference) { $errorOutput = "$($MyInvocation.MyCommand.Name)_$([System.IO.Path]::GetRandomFileName())" }

    # NOTE:
    # Inner cmd local redirect into file allows for proper removal of junk characters.
    # PS redirects and parses the CLIXML. Outer redirect is for the PS execution
    # to disreguard the StdErr message and Connecting messages
    $finalCommand = "cmd /C `"$psexec -nobanner -acceptEula \\$ComputerName cmd /C `"`"$commandLine`"`" 2>$errorOutput`" 2>`$null"
    if ($PSCmdlet.ShouldProcess($ComputerName, $finalCommand)) {
        $output = Invoke-Expression $finalCommand
        $output | Add-Member -MemberType NoteProperty -Name 'PsexecComputerName' -Value $ComputerName
    }
    #endregion

    #region Check for any errors
    if ($PSCmdlet.ShouldProcess($errorOutput, "Check Errors")) {

        $errorContent = Get-Content $errorOutput
        Write-Information -MessageData $errorContent -Tags 'ErrorText'
        $hasErrRec = $errorContent[-2] -match "System.Management.Automation.ErrorRecord" -or $errorContent[-1] -eq '#< CLIXML'
        if($errorContent -match "Access is denied" -and -not $hasErrRec)
        {
            $errorMessage = "[$ComputerName] Could not execute remote expression. Ensure that your account has administrative " +
                "privileges on the target machine."
            Write-Error $errorMessage
        }
        elseif($errorContent -match "The service did not respond to the start or control request in a timely fashion" -and -not $hasErrRec)
        {
            $errorMessage = "[$ComputerName] Could not start PSEXESVC service. The service did not respond in a timely fashion."
            Write-Error $errorMessage
        }
        elseif($errorContent -match "This version of %1 is not compatible with the version of Windows you're running" -and -not $hasErrRec)
        {
            $errorMessage = "[$ComputerName] Could not start PSEXESVC service. The version is not compatible with the version " +
                'of Windows. Try the -PSExec32 switch.'
            Write-Error $errorMessage
        }
        elseif($errorContent -match "You can't connect to the file share because it's not secure." -and -not $hasErrRec)
        {
            $errorMessage = "[$ComputerName] Cannot connect to SMB1 protocol because it's not secure. System requires SMV2 or higher."
            Write-Error $errorMessage
        }
        elseif( ( $errorContent -match "The network path was not found" -or $errorContent -match "The handle is invalid" ) -and -not $hasErrRec)
        {
            $errorMessage = "[$ComputerName] Could not execute remote expression. Ensure that the machine is turned on and/or the default admin$ share is enabled."
            Write-Error $errorMessage
        }
        elseif( $errorContent -match "Error deriving session key" -and $errorContent -match "Object already exists" -and -not $hasErrRec)
        {
            $errorMessage = "[$ComputerName] Could not execute remote expression. PSEXESVC already running on the machine."
            Write-Error $errorMessage
        }
        elseif( $errorContent -match "Error deriving session key" -and $errorContent -match "The system cannot find the file specified" -and -not $hasErrRec)
        {
            $errorMessage = "[$ComputerName] Could not execute remote expression. Session may not be able to find the profile like 'runas.exe /noprofile' is being used."
            Write-Error $errorMessage
        }
        elseif ($errorContent -match 'Logon failure: the user has not been granted the requested logon type at this computer.' -and -not $hasErrRec)
        {
            $errorMessage = "[$ComputerName] Logon failure. Try the -AsSystem flag."
            Write-Error $errorMessage
        }
        elseif( ( $errorContent[1] -match "System.Management.Automation.ErrorRecord" -or $LASTEXITCODE -ne 0 ) -and
            $errorContent[-2] -eq '#< CLIXML')
        {
            $errorContentCli = "$($errorContent[-2])$newLine$($errorContent[-1])" -replace "</Objs>(Connecting|cmd exited on).*", "</Objs>"
            Set-Content -Path $errorOutput -Value $errorContentCli
            try {
                $cli = Import-Clixml $errorOutput | Where-Object { $_.psobject.TypeNames -contains "Deserialized.System.Management.Automation.ErrorRecord" }
                Write-Information -MessageData $cli -Tags ErrorRecord
                # Exception
                $params = @{
                    TypeName = 'System.Exception'
                    ArgumentList = $null
                    Property = @{ Source = $cli.Exception.Source }
                }
                if($null -ne $cli.Exception.InnerException){
                    $params.ArgumentList = @( $cli.Exception.Message, $cli.Exception.InnerException.Message )
                }
                else {
                    $params.ArgumentList = $cli.Exception.Message
                }
                $exception = New-Object @params
                # ErrorDetails
                $params = @{
                    TypeName = 'System.Management.Automation.ErrorDetails'
                    ArgumentList = $null
                    Property = @{ RecommendedAction = "`$errorContent $( $errorContent -join $newLine )" }
                }
                if ($cli.InvocationInfo.MyCommand.psobject.TypeNames -contains 'Deserialized.System.Management.Automation.CmdletInfo') {
                    $argListCmd = $cli.InvocationInfo.MyCommand.Name
                }
                else {
                    $argListCmd = $cli.InvocationInfo.MyCommand
                }
                $params.ArgumentList = "$ComputerName`: $argListCmd`: $($cli.Exception.Message) $newLine $($cli.InvocationInfo.PositionMessage)"
                $errorDetails = New-Object @params
                # ErrorRecord
                $params = @{
                    TypeName = 'System.Management.Automation.ErrorRecord'
                    ArgumentList = @( $exception
                        $cli.FullyQualifiedErrorId
                        $cli.ErrorCategory_Category
                        $null
                        )
                    Property = @{ ErrorDetails = $errorDetails }
                }
                $errorRecord = New-Object @params
                # Create Error
                $params = @{
                    ErrorRecord = $errorRecord
                    CategoryActivity = $cli.ErrorCategory_Activity
                    CategoryReason = $cli.ErrorCategory_Reason
                    CategoryTargetName = $cli.ErrorCategory_TargetName
                    CategoryTargetType = $cli.ErrorCategory_TargetType
                }
                Write-Error @params
            }
            catch [System.Xml.XmlException] {
                # All else fails parse the CLIXML manually and output raw text into Error Record object.
                $errorContentMatch = $errorContent[-1] -match '<ToString>(?<clixmlMsg>.*?)<\/ToString>'
                $extraMsg = 'See $Error[0].ErrorDetails.RecommendedAction for full CLIXML or use -InformationVariable.'
                if ($errorContentMatch) {
                    $clixmlMsg = $Matches['clixmlMsg']
                    $catchMessage = "$ComputerName`: $clixmlMsg $extraMsg"
                }
                else {
                    $catchMessage = "$ComputerName`: Failed to parse CLIXML. $extraMsg"
                }
                $exception = New-Object -TypeName 'System.Exception' -ArgumentList $catchMessage
                $params = @{
                    TypeName = 'System.Management.Automation.ErrorDetails'
                    ArgumentList = $catchMessage
                    Property = @{ RecommendedAction = "`$errorContent $( $errorContent -join $newLine )" }
                }
                $errorDetails = New-Object @params
                $params = @{
                    TypeName = 'System.Management.Automation.ErrorRecord'
                    ArgumentList = @( $exception,
                        'Invoke-RemoteExpression.ErrorRecord',
                        [System.Management.Automation.ErrorCategory]::FromStdErr,
                        $errorContentCli )
                    Property = @{ ErrorDetails = $errorDetails }
                }
                $errorRecord = New-Object @params
                Write-Error -ErrorRecord $errorRecord
            }
            catch {
                Write-Error $_
            }
        }
    }
    if ($PSCmdlet.ShouldProcess("Temp File", "Remove")) {
        Remove-Item $errorOutput
    }
    #endregion

    #region Return the output to the user
    if ($PSCmdlet.ShouldProcess("$ComputerName", "Write-Output")) {
        $output
    }
    #endregion
}