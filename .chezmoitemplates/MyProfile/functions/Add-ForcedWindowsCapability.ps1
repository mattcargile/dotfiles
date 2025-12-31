<#
TODO:
1. Add handling for windows server. Code below to install RSAT Active Directory
   `get-windowsfeature RSAT-AD-PowerShell | Add-WindowsFeature`
2. Research how to install other RSAT tools
3. Add the below checks, namely the setting of the `CacheSet002` and/or `CacheSet001 **DONE**

if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name DeferFeatureUpdatesPeriodInDays) {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name DeferFeatureUpdatesPeriodInDays -Force
}
if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetDisableUXWUAccess) {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetDisableUXWUAccess -Force
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name DisableWindowsUpdateAccess -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetPolicyDrivenUpdateSourceForDriverUpdates -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetPolicyDrivenUpdateSourceForFeatureUpdates -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetPolicyDrivenUpdateSourceForOtherUpdates -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetPolicyDrivenUpdateSourceForQualityUpdates -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name UseUpdateClassPolicySource  -Value 0
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet001\WindowsUpdate" -Recurse -Force
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet002\WindowsUpdate" -Recurse -Force
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet001\WindowsUpdate"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet001\WindowsUpdate\AU"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet002\WindowsUpdate"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet002\WindowsUpdate\AU"


#>
function Add-ForcedWindowsCapability {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $Name
    )
    
    $currentPrincipal = [System.Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $sb = {
        param ( [string[]]$Name )
        # Guessing the the progress bar is interfering with script block execution
        $ProgressPreference = 'SilentlyContinue'
        $regPathsAndUseWuServer = @{
            'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' = $null
            'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet001\WindowsUpdate\AU' = $null
            'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet002\WindowsUpdate\AU' = $null
        }
        foreach ($p in @($regPathsAndUseWuServer.GetEnumerator())) {
            if (Test-Path $p.Name) {
                if ($currentWU = Get-ItemProperty -Path $p.Name -Name "UseWUServer" -ErrorAction Ignore) {
                    Set-ItemProperty -Path $p.Name -Name "UseWUServer" -Value 0
                    $regPathsAndUseWuServer[$p.Name] = $currentWU.UseWUServer
                }
            }
        }
        Restart-Service wuauserv
        foreach ($currentName in $Name) {
            Get-WindowsCapability -Name $currentName -Online | Where-Object -Property State -EQ 'NotPresent' | Add-WindowsCapability -Online
        }
        foreach ($p in @($regPathsAndUseWuServer.GetEnumerator())) {
            if ($null -ne $p.Value) {
                Set-ItemProperty -Path $p.Name -Name "UseWUServer" -Value $p.Value
            }
        }
        Restart-Service wuauserv
    }
    
    if (-not $isAdmin) {
        Write-Warning "User $($currentPrincipal.Identities.Name) is not Administrator. Attempting gsudo."
        if (-not (Get-Command invoke-gsudo -ErrorAction Ignore)) {
            Write-Warning "gsudo.exe tool is not installed. Install with choco or the like. Exiting."
            return
        }
        else { Invoke-Gsudo $sb -ArgumentList $Name }
    }
    else { & $sb $Name }
}
