#Requires -Modules PSToml, ctypes
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]
    $Path,
    [Parameter(Mandatory)]
    [ValidateSet('Windows')]
    [string]
    $Platform
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$tomlPath = "$PSScriptRoot\envPath.toml"
$data = Get-Content -Path $tomlPath -Raw | ConvertFrom-Toml

switch ($Platform) {
    'Windows' {
        $platformLower = $Platform.ToLower()
        $newWinArray = $data.$platformLower | Where-Object -FilterScript { $_ -ne $Path }
    }
    Default { throw [System.InvalidOperationException]'Default Platform not implemented' }
}

if ($newWinArray.Count -lt $data.$platformLower.Count) {
    if ($PSCmdlet.ShouldProcess($tomlPath, "Removing $Path")) {
        $data.$platformLower = $newWinArray
        $data | ConvertTo-Toml -Depth 3 | Set-Content -Path $tomlPath
    }
}

if ($IsWindows) {
    $pathSep = [System.IO.Path]::PathSeparator
    try {
        $envKey = Get-Item -Path 'HKCU:\Environment'
        $envKeyPropPath = $envKey.GetValue( 'Path', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames )
        Write-Verbose "Current HKCU:\Environment Path is $envKeyPropPath"
        $envKeyPropPathList = [System.Collections.Generic.List[string]]@($envKeyPropPath -split $pathSep)
        $envKeyPropPathListStartingCount = $envKeyPropPathList.Count
    }
    catch {
        Write-Error -ErrorRecord $_
        return
    }
    finally {
        if ($envKey) {
            $envKey.Dispose()
        }
    }
    if ($envKeyPropPathList -contains $Path) {
        Write-Verbose "Removing $Path from temp Path variable."
        $envKeyPropPathList.Remove($Path)
    }
    if ($envKeyPropPathList.Count -lt $envKeyPropPathListStartingCount) {
        $envKeyPropPathChanged = $envKeyPropPathList -join $pathSep
        if ($PSCmdlet.ShouldProcess('HKCU:\Environment', "Setting Path to $envKeyPropPathChanged")) {
            Set-ItemProperty -Path 'HKCU:\Environment' -Name Path -Value $envKeyPropPathChanged -Type ExpandString
            $usr = New-CtypesLib -Name user32.dll
            $res = [UIntPtr]::Zero # Purposefully ignoring this output as information on return data isn't readily available
            $out = $usr.CharSet('Unicode').SetLastError().SendMessageTimeout(
                [IntPtr]0xFFFF <# HWND_BROADCAST #>,
                0x1A <# WM_SETTINGSCHANGE #>,
                $null,
                'Environment',
                2 <# SMTO_ABORTIFHUNG #>,
                5000,
                [ref]$res
            )
            if ($out -eq 0) {
                throw [InvalidOperationException]'Failed to send message to all windows for environment. There may be a hung window.'
            }
        }
    }
}