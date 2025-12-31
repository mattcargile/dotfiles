<#
.SYNOPSIS
    Get Installed Software
.DESCRIPTION
    Gets uninstall registry location with the Registry library
.NOTES
    Uses PSTypeName types so autocompletion on members doesn't work. Explore implementing types.
.LINK
    https://github.com/SeeminglyScience/dotfiles/blob/eb62bb91eb889c290d607c8f57762a9ec1cedbe4/Documents/PowerShell/Utility.psm1#L327
.EXAMPLE
    Get-InstalledSoftware *sql*
    Gets any software with sql in the Name
.EXAMPLE
    Get-InstalledSoftware -Name *odbc* -ComputerName ServerName1
    Gets any software with odbc in the name on the remote host named ServerName1
#>
function Get-InstalledSoftware {
    [Alias('gsoft')]
    [OutputType('Utility.InstalledSoftware')]
    [OutputType('Utility.InstalledSoftware#IncludeComputerName', ParameterSetName = 'Computer')]
    [CmdletBinding()]
    param(
        # Name of installed software
        [Parameter(ValueFromPipeline, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Name,
        # Remote Computer Name
        [Parameter(ParameterSetName = 'Computer', Position = 1)]
        [Alias('cn')]
        [string[]]
        $ComputerName
    )
    begin {
        $allNames = $null
        # Don't use the registry provider for performance and to allow us to open the
        # 64 bit registry view from a 32 bit process.
        $hklm = $null
        $hkcu = $null
        $ownsKey = $false
        $registryPaths = @(
            [pscustomobject]@{ # This must remain first for downstream logic
                PSTypeName    = 'Utility.Internal.RegistryPath'
                Hive          = 'HKEY_LOCAL_MACHINE'
                Path          = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
                Is64Bit       = $true
                IsCurrentUser = $false
            },
            [pscustomobject]@{
                PSTypeName    = 'Utility.Internal.RegistryPath'
                Hive          = 'HKEY_LOCAL_MACHINE'
                Path          = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
                Is64Bit       = $false
                IsCurrentUser = $false
            },
            [pscustomobject]@{
                PSTypeName    = 'Utility.Internal.RegistryPath'
                Hive          = 'HKEY_CURRENT_USER'
                Path          = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
                Is64Bit       = $false
                IsCurrentUser = $true
            }
        )
        $advapi = New-CtypesLib Advapi32.dll
        function Write-SubKeyData (
            [Microsoft.Win32.RegistryKey]$HKeyLM,
            [Microsoft.Win32.RegistryKey]$HKeyCU,
            [pscustomobject[]]$RegPath,
            [WildcardPattern[]]$NameWildcard,
            [System.Management.Automation.PSCmdlet]$PSC,
            [string]$ComputerName
        ) {
            $propPSTypeName = 'Utility.InstalledSoftware'
            if ($ComputerName) {
                $propPSTypeName += '#IncludeComputerName'
            }
            foreach ($registryPath in $RegPath) {
                $software = $null
                try {
                    if ($registryPath.Hive -eq 'HKEY_LOCAL_MACHINE') {
                        $software = $HKeyLm.OpenSubKey($registryPath.Path)
                        $currentUser = $null
                    }
                    else {
                        if (-not $HKeyCU) {
                            continue
                        }
                        $software = $HKeyCU.OpenSubKey($registryPath.Path)
                        $currentUser = "$env:USERDOMAIN\$env:USERNAME"
                    }
                    foreach ($subKeyName in $software.GetSubKeyNames()) {
                        $subKey = $null

                        try {
                            $subKey = $software.OpenSubKey(
                                $subKeyName,
                                [System.Security.AccessControl.RegistryRights]::QueryValues)

                            $displayName = $subKey.GetValue('DisplayName')
                            if ([string]::IsNullOrEmpty($displayName)) {
                                continue
                            }

                            if ($NameWildcard.Length -gt 0) {
                                $wasMatchFound = $false
                                foreach ($wildcard in $NameWildcard) {
                                    if ($wildcard.IsMatch($displayName)) {
                                        $wasMatchFound = $true
                                        break
                                    }
                                }

                                if (-not $wasMatchFound) {
                                    continue
                                }
                            }

                            $installedOn = $subKey.GetValue('InstallDate')
                            # [ref] below has to be [datetime] without [nullable]
                            [datetime]$installedOnResult = Get-Date
                            [System.Nullable[datetime]]$installedOnDt = $null
                            $isParsed = $false
                            if (-not [string]::IsNullOrWhiteSpace($installedOn)) {
                                # $null is CurrentCulture
                                # https://source.dot.net/#System.Private.CoreLib/src/libraries/System.Private.CoreLib/src/System/Globalization/DateTimeFormatInfo.cs,324
                                if ($installedOn -match '[0-9]/[0-9]/[0-9]{4}') {
                                    $isParsed = [datetime]::TryParseExact($installedOn, 'M/d/yyyy', $null, [System.Globalization.DateTimeStyles]::None, [ref]$installedOnResult)
                                    if ($isParsed) { $installedOnDt = $installedOnResult }
                                }
                                else {
                                    $isParsed = [datetime]::TryParseExact($installedOn, 'yyyyMMdd', $null, [System.Globalization.DateTimeStyles]::None, [ref]$installedOnResult)
                                    if ($isParsed) { $installedOnDt = $installedOnResult }
                                }
                            }
                            if ($null -eq $installedOnDt) {
                                $filetime = New-Object System.Runtime.InteropServices.ComTypes.FILETIME
                                $res = $advapi.CharSet('Unicode').SetLastError().RegQueryInfoKey( $subKey.Handle, $null, $null, $null, $null, $null, $null, $null, $null, $null, $null, [ref]$filetime )
                                if ($res -ne 0) {
                                    $exp = [System.ComponentModel.Win32Exception]::new($res)
                                    $err = [System.Management.Automation.ErrorRecord]::new(
                                        $exp,
                                        "FailedToRetrieveRegistryFileTime",
                                        "NotSpecified",
                                        $subKey.Name)
                                    $err.ErrorDetails = "Failed to retrieve Registry FileTime '{0}' (0x{1:X8}): {2}" -f @(
                                        $subKey.Name, $exp.NativeErrorCode, $exp.Message)
                                    $PSC.WriteError($err)
                                }
                                $filetime64 = [uint64]$filetime.dwHighDateTime -shl 32 -bor ($filetime.dwLowDateTime -band [uint32]::MaxValue)
                                $installedOnDt = [datetime]::FromFileTime($filetime64)
                            }

                            $outInsSoft = [PSCustomObject]@{
                                PSTypeName       = $propPSTypeName
                                Name             = $displayName
                                Publisher        = $subKey.GetValue('Publisher')
                                DisplayVersion   = $subKey.GetValue('DisplayVersion')
                                Uninstall        = $subKey.GetValue('UninstallString')
                                Guid             = $subKeyName
                                InstallDate      = $installedOnDt
                                Is64Bit          = $registryPath.Is64Bit
                                IsCurrentUser    = $registryPath.IsCurrentUser
                                CurrentUser      = $currentUser
                                PSPath           = 'Microsoft.PowerShell.Core\Registry::{0}\{1}\{2}' -f (
                                    $registryPath.Hive,
                                    $registryPath.Path,
                                    $subKeyName)
                            }
                            if ($ComputerName) {
                                $outInsSoft | Add-Member -Name ComputerName -Value $ComputerName -MemberType NoteProperty
                            }
                            # yield
                            $outInsSoft
                        }
                        catch {
                            $PSC.WriteError($PSItem)
                        }
                        finally {
                            if ($null -ne $subKey) {
                                $subKey.Dispose()
                            }
                        }
                    }
                }
                finally {
                    if ($null -ne $software) {
                        $software.Dispose()
                    }
                }
            }
        }
    }
    process {
        if (-not $PSBoundParameters.ContainsKey('Name') -or [string]::IsNullOrEmpty($Name)) {
            return
        }
        
        if ($null -eq $allNames) {
            $startingCapacity = 1
            if ($MyInvocation.ExpectingInput) {
                $startingCapacity = 4
            }
            
            $allNames = [System.Collections.Generic.List[string]]::new($startingCapacity)
        }
        if ($Name.Count -gt 1) {
            foreach ($nm in $Name) { $allNames.Add($nm) }
        }
        else {
            $allNames.Add($Name)
        }
    }
    end {
        if ($null -ne $allNames) {
            $wildcards = [System.Management.Automation.WildcardPattern[]]::new($allNames.Count)
            for ($i = 0; $i -lt $allNames.Count; $i++) {
                $wildcards[$i] = [System.Management.Automation.WildcardPattern]::new(
                    $allNames[$i],
                    [System.Management.Automation.WildcardOptions]::IgnoreCase)
            }
        }
            
        if ($ComputerName) {
            $ownsKey = $true
            foreach ($cn in $ComputerName) {
                try {
                    $hklm = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey( [Microsoft.Win32.RegistryHive]::LocalMachine, $cn, [Microsoft.Win32.RegistryView]::Registry64)
                    # TODO: CurrentUser not available from Remote Registry. Explore adding HKEY_USERS
                    Write-SubKeyData -HKeyLM $hklm -RegPath $registryPaths -NameWildcard $wildcards -PSC $PSCmdlet -ComputerName $cn
                }
                catch [System.Management.Automation.MethodInvocationException] {
                    $innerExp = $PSItem.Exception.InnerException
                    $PSCmdlet.WriteError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.Exception]::new( "[$cn] $($innerExp.Message)", $innerExp ),
                            'OpenRemoteBaseKeyFailed',
                            [System.Management.Automation.ErrorCategory]::OperationStopped,
                            $cn
                        )
                    )
                }
                catch {
                    $PSCmdlet.WriteError( $PSItem )
                }
                finally {
                    if ($ownsKey -and $null -ne $hklm) {
                        $hklm.Dispose()
                    }
                }
            }
        }
        else {
            try {
                $hklm = [Microsoft.Win32.Registry]::LocalMachine
                if (-not [Environment]::Is64BitProcess) {
                    if ([Environment]::Is64BitOperatingSystem) {
                        $ownsKey = $true
                        $hklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
                            [Microsoft.Win32.RegistryHive]::LocalMachine,
                            [Microsoft.Win32.RegistryView]::Registry64)
                    }
                    else {
                        # Removing 32 bit path because it is 32bit Operating System
                        $registryPaths = @($registryPaths[0], $registryPaths[2])
                        $registryPaths[0].Is64Bit = $false
                    }
                }
                $hkcu = [Microsoft.Win32.Registry]::CurrentUser
                Write-SubKeyData $hklm $hkcu $registryPaths $wildcards $PSCmdlet
            }
            finally {
                if ($ownsKey -and $null -ne $hklm) {
                    $hklm.Dispose()
                }
            }
        }
    }
}
