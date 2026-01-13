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
