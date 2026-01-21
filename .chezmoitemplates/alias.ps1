# Define below in this format so as not to override the definitions in defaultparams.ps1. Need to delete at the end of script.
# Handy definition here so as to make the below code simpler.
$PSDefaultParameterValues['New-Alias:Description'] = "Created with `$PROFILE.CurrentUserAllHosts at $($MyInvocation.MyCommand.Path)"
# Forcing to allow easy re-running of this script file.
$PSDefaultParameterValues['New-Alias:Force'] = $true

# Following guidelines here ( https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands )

# Microsoft.PowerShell.PSResourceGet Module
New-Alias -Name 'gires' -Value 'Get-InstalledPSResource'
New-Alias -Name 'usres' -Value 'Uninstall-PSResource'
# Core Cmdlets
New-Alias -Name 's' -Value 'Select-Object'
New-Alias -Name 'onl' -Value 'Out-Null'
New-Alias -Name 'tcn' -Value 'Test-Connection'
New-Alias -Name 'no' -Value 'New-Object'
New-Alias -Name 'rvdns' -Value 'Resolve-DnsName'
New-Alias -Name 'gwe' -Value 'Get-WinEvent'
New-Alias -Name 'gctr' -Value 'Get-Counter'
New-Alias -Name 'epcli' -Value 'Export-CliXml'
New-Alias -Name 'ipcli' -Value 'Import-CliXml'
New-Alias -Name 'scnt' -Value 'Set-Content'
New-Alias -Name 'acnt' -Value 'Add-Content'
New-Alias -Name 'ctjson' -Value 'ConvertTo-Json'
New-Alias -Name 'cfjson' -Value 'ConvertFrom-Json'
New-Alias -Name 'ctclix' -Value 'ConvertTo-CliXml'
New-Alias -Name 'cfclix' -Value 'ConvertFrom-CliXml'
New-Alias -Name 'ctsecs' -Value 'ConvertTo-SecureString'
New-Alias -Name 'cfsecs' -Value 'ConvertFrom-SecureString'
New-Alias -Name 'gscht' -Value 'Get-ScheduledTask'
New-Alias -Name 'cthtml' -Value 'ConvertTo-Html'
# ScheduledTasks
New-Alias -Name 'gscht' -Value 'ScheduledTasks\Get-ScheduledTask'
New-Alias -Name 'gschti' -Value 'ScheduledTasks\Get-ScheduledTaskInfo'
# NetTCPIP Module
New-Alias -Name 'gipa' -Value 'Get-NetIPAddress'
New-Alias -Name 'gtcpc' -Value 'Get-NetTCPConnection'
New-Alias -Name 'groute' -Value 'Get-NetRoute'
# VMWare PowerCLI
New-Alias -Name 'ccvi' -Value 'VMWare.VimAutomation.Core\Connect-VIServer'
New-Alias -Name 'gvm' -Value 'VMWare.VimAutomation.Core\Get-VM'
# Gsudo Binary And Module
New-Alias -Name 'isudo' -Value 'Invoke-Gsudo'
# ImportExcel Module
New-Alias -Name 'epxl' -Value 'Export-Excel'
New-Alias -Name 'ipxl' -Value 'Import-Excel'
# string Module
# NOTE: Using this method due to interplay with PSUtil ( which has slow load times ) and lack of aliases in the string module `psd1`
# https://github.com/PowershellFrameworkCollective/PSUtil/issues/67
New-Alias -Name 'add' -Value 'string\Add-String'
New-Alias -Name 'format' -Value 'string\Format-String'
# Using proxy Join-String command for Core edition.
# Join-String only exposed in the `psd1` for the Desktop edition 
if ($PSEdition -eq 'Desktop') {
  New-Alias -Name 'join' -Value 'string\Join-String'
}
New-Alias -Name 'replace' -Value 'string\Set-String'
New-Alias -Name 'split' -Value 'string\Split-String'
New-Alias -Name 'trim' -Value 'string\Get-SubString'
New-Alias -Name 'wrap' -Value 'string\Add-String'
# PSFzf Module
New-Alias -Name 'frg' -Value 'Invoke-PsFzfRipgrep'
New-Alias -name 'fscoop' -Value 'Invoke-FuzzyScoop'
# dbatools Module
New-Alias -Name 'gddr' -Value 'Get-DbaDbRole'
New-Alias -Name 'nddr' -Value 'New-DbaDbRole'
New-Alias -Name 'gddrm' -Value 'Get-DbaDbRoleMember'
New-Alias -Name 'rddr' -Value 'Remove-DbaDbRole'
New-Alias -Name 'rdsr' -Value 'Remove-DbaServerRole'
New-Alias -Name 'gdsr' -Value 'Get-DbaServerRole'
New-Alias -Name 'ndsr' -Value 'New-DbaServerRole'
New-Alias -Name 'gdsrm' -Value 'Get-DbaServerRoleMember'
New-Alias -Name 'adsrm' -Value 'Add-DbaServerRoleMember'
New-Alias -Name 'rdsrm' -Value 'Remove-DbaServerRoleMember'
New-Alias -Name 'addrm' -Value 'Add-DbaDbRoleMember'
New-Alias -Name 'rddrm' -Value 'Remove-DbaDbRoleMember'
New-Alias -Name 'badb' -Value 'Backup-DbaDatabase'
New-Alias -Name 'gdreg' -Value 'Get-DbaRegServer'
New-Alias -Name 'gdb' -Value 'Get-DbaDatabase'
New-Alias -Name 'rdb' -Value 'Remove-DbaDatabase'
New-Alias -Name 'fddaj' -Value 'Find-DbaAgentJob'
New-Alias -Name 'fddb' -Value 'Find-DbaDatabase'
New-Alias -Name 'gdaj' -Value 'Get-DbaAgentJob'
New-Alias -Name 'gdash' -Value 'Get-DbaAgentSchedule'
New-Alias -Name 'sdaj' -Value 'Set-DbaAgentJob'
New-Alias -Name 'sadaj' -Value 'Start-DbaAgentJob'
New-Alias -Name 'spdaj' -Value 'Stop-DbaAgentJob'
New-Alias -Name 'rdaj' -Value 'Remove-DbaAgentJob'
New-Alias -Name 'ndaj' -Value 'New-DbaAgentJob'
New-Alias -Name 'gdajh' -Value 'Get-DbaAgentJobHistory'
New-Alias -Name 'tdcn' -Value 'Test-DbaConnection'
New-Alias -Name 'idq' -Value 'Invoke-DbaQuery'
New-Alias -Name 'epdl' -Value 'Export-DbaLogin'
New-Alias -Name 'epdu' -Value 'Export-DbaUser'
New-Alias -Name 'epdsr' -Value 'Export-DbaServerRole'
New-Alias -Name 'epddr' -Value 'Export-DbaDbRole'
New-Alias -Name 'epdscr' -Value 'Export-DbaScript'
New-Alias -Name 'gdbf' -Value 'Get-DbaDbFile'
New-Alias -Name 'gdds' -Value 'Get-DbaDiskSpace'
New-Alias -Name 'gdsv' -Value 'Get-DbaService'
New-Alias -Name 'sadsv' -Value 'Start-DbaService'
New-Alias -Name 'spdsv' -Value 'Stop-DbaService'
New-Alias -Name 'ndb' -Value 'New-DbaDatabase'
New-Alias -Name 'gdl' -Value 'Get-DbaLogin'
New-Alias -Name 'ndl' -Value 'New-DbaLogin'
New-Alias -Name 'rdl' -Value 'Remove-DbaLogin'
New-Alias -Name 'sdl' -Value 'Set-DbaLogin'
New-Alias -Name 'ndbu' -Value 'New-DbaDbUser'
New-Alias -Name 'gdbu' -Value 'Get-DbaDbUser'
New-Alias -Name 'rdbu' -Value 'Remove-DbaDbUser'
New-Alias -Name 'gderr' -Value 'Get-DbaErrorLog'
New-Alias -Name 'idwho' -Value 'Invoke-DbaWhoIsActive'
New-Alias -Name 'fddcmd' -Value 'Find-DbaCommand'
New-Alias -Name 'ccdi' -Value 'Connect-DbaInstance'
New-Alias -Name 'gdsp' -Value 'Get-DbaDbStoredProcedure'
New-Alias -Name 'fddsp' -Value 'Find-DbaStoredProcedure'
New-Alias -Name 'gduf' -Value 'Get-DbaDbUdf'
New-Alias -Name 'gdvw' -Value 'Get-DbaDbView'
New-Alias -Name 'fddvw' -Value 'Find-DbaView'
New-Alias -Name 'gdtb' -Value 'Get-DbaDbTable'
New-Alias -Name 'gdps' -Value 'Get-DbaProcess'
New-Alias -Name 'spdps' -Value 'Stop-DbaProcess'
New-Alias -Name 'gddbh' -Value 'Get-DbaDbBackupHistory'
New-Alias -Name 'gdxeo' -Value 'Get-DbaXEObject'
New-Alias -Name 'gdxest' -Value 'Get-DbaXEStore'
New-Alias -Name 'gdxesta' -Value 'Get-DbaXESessionTarget'
New-Alias -Name 'gdxestaf' -Value 'Get-DbaXESessionTargetFile'
New-Alias -Name 'gdxestp' -Value 'Get-DbaXESessionTemplate'
New-Alias -Name 'gdxes' -Value 'Get-DbaXESession'
New-Alias -Name 'rxes' -Value 'Remove-DbaXESession'
New-Alias -Name 'ndxes' -Value 'New-DbaXESession'
New-Alias -Name 'epdxes' -Value 'Export-DbaXESession'
New-Alias -Name 'sadxes' -Value 'Start-DbaXESession'
New-Alias -Name 'spdxes' -Value 'Stop-DbaXESession'
New-Alias -Name 'wcdxes' -Value 'Watch-DbaXESession'
New-Alias -Name 'ctdxes' -Value 'ConvertTo-DbaXESession'

# SecretManagement Module
New-Alias -Name 'gsci' -Value 'Get-SecretInfo'
New-Alias -Name 'gsc' -Value 'Get-Secret'
New-Alias -Name 'ukv' -Value 'Unlock-SecretVault'
# ActiveDirectory Module
New-Alias -Name 'gadu' -Value 'Get-ADUser'
New-Alias -Name 'gadg' -Value 'Get-ADGroup'
New-Alias -Name 'gadgm' -Value 'Get-ADGroupMember'
New-Alias -Name 'gadc' -Value 'Get-ADComputer'
New-Alias -Name 'gado' -Value 'Get-ADObject'
# TerminalSessions Module
New-Alias -Name 'gwts' -Value 'Get-WTSSession'
New-Alias -Name 'rwts' -Value 'Remove-WTSSession'
# PSParseHTML
New-Alias -Name 'cfhtml' -Value 'PSParseHTML\ConverFrom-HTML'
# Native Commands
$prg86 = ${env:ProgramFiles(x86)}
$prgFiles = $env:ProgramFiles
New-Alias -Name 'choco.exe' -Value 'choco' # Hack for autocomplete.
New-Alias -Name 'git.exe' -Value 'git' # Hack for autocomplete.
# Python Alias
# No longer needed or functional for oh-my-posh. Need to disable the App Execution Aliases in Windows
# Appears one would need to clear entry from `HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths` and
# the file at `$env:LOCALAPPDATA\Microsoft\WindowsApps`. https://superuser.com/a/1746939
# Use `py -m pip list` instead of `pip`

# Additional exe's
$ssms86Path = Convert-Path -Path "$prg86\Microsoft SQL Server Management Studio *\Common7\IDE\Ssms.exe" | Sort-Object -Descending | Select-Object -First 1
$ssmsPath = Convert-Path -Path "$prgFiles\Microsoft SQL Server Management Studio *\Release\Common7\IDE\Ssms.exe" | Sort-Object -Descending | Select-Object -First 1
if ($ssmsPath) {
  New-Alias -Name 'ssms' -Value $ssmsPath
}
elseif ($ssms86Path) {
  New-Alias -Name 'ssms' -Value $ssms86Path
}
New-Alias -Name 'npp' -Value "$prgFiles\Notepad++\notepad++.exe"
New-Alias -Name 'ostress' -Value "$prgFiles\Microsoft Corporation\RMLUtils\ostress.exe"
# Helper vs variables
$vsVer = '2022'
$vsPrefix = "$prgFiles\Microsoft Visual Studio\$vsVer\Community"
$vsIDE = "$vsPrefix\Common7\IDE"
$vsMsBldBin = "$vsPrefix\MSBuild\Current\Bin"
if ($vsPrefix) {
  # For VS 2019 launching. Sometimes Invoke-Item will launch older versions.
  New-Alias -Name 'devenv' -Value "$vsIDE\devenv.exe"
  # For tf.exe TFS source control. This may change with new versions.
  New-Alias -Name 'tf' -Value "$vsIDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\tf.exe"
  # sqlpackage.exe 150/2019 DacPac diff
  New-Alias -Name 'sqlpackage' -Value "$vsIDE\Extensions\Microsoft\SQLDB\DAC\150\sqlpackage.exe"
  # C# interactive
  New-Alias -Name 'csi' -Value "$vsMsBldBin\Roslyn\csi.exe"
  # C# Compiler
  New-Alias -Name 'csc' -Value "$vsMsBldBin\Roslyn\csc.exe"
  # MsBuild tool
  New-Alias -Name 'msbuild' -Value "$vsMsBldBin\MsBuild.exe"
}
# Avoiding using the old Lua 7z or the like
New-Alias -Name '7z' -Value "$env:USERPROFILE\scoop\shims\7z.exe"
# Cisco Anyconnect (Secure Client) VPN ( vpncli.exe )
$ciscoPaths = @(
  "$prg86\Cisco\Cisco Secure Client\vpncli.exe"
  "$prg86\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe"
)
foreach ($currentCiscoPath in $ciscoPaths) {
  if(Test-Path $currentCiscoPath) {
    New-Alias -Name 'vpncli' -Value $currentCiscoPath
    break
  }
}
# Wally keyboard Flash CLI tool
New-Alias -Name 'wally-cli' -Value "$prg86\Wally\wally-cli.exe"
# Microsoft Kerberos Configuration Manager
New-Alias -Name 'KerberosConfigMgr' -Value "$prgFiles\Microsoft\Kerberos Configuration Manager for SQL Server\KerberosConfigMgr.exe"
# SentinelOne Control for checking status
if ($senOnePath = Convert-Path "$prgFiles\SentinelOne\Sentinel Agent*\SentinelCtl.exe" -ErrorAction Ignore | Sort-Object -Descending | Select-Object -First 1) {
    New-Item -Path function:\SentinelCtl -Value "gsudo `"& '$senOnePath' `$args`"" -Force | Out-Null
}
# Spacesniffer GUI check disk space. Relies on $env:PATH
if ( $spcSnif = Get-Command -Name 'SpaceSniffer.exe' -CommandType Application -ErrorAction Ignore | Select-Object -First 1 -ExpandProperty 'Definition' ) {
    New-Item -Path function:\SpaceSniffer -Value "gsudo `"& '$spcSnif'`"" -Force | Out-Null
}


$PSDefaultParameterValues.Remove( 'New-Alias:Description' )
$PSDefaultParameterValues.Remove( 'New-Alias:Force' )
$rmVar = @(
  'rmVar'
  'prgFiles'
  'prg86'
  'vsVer'
  'vsPrefix'
  'vsIDE'
  'vsMsBldBin'
  'senOnePath'
  'spcSnif'
  'ssmsPath'
  'ssms86Path'
  'ciscoPaths'
  'currentCiscoPath'
)
Remove-Variable -Name $rmVar

# scoop aliases
# scoop alias add fsearch 'scoop-search.exe $args[0]' 'Fast search with scoop-search.exe'
# scoop alias add describe 'sfsu.exe describe $args[0]' 'Fast info with sfsu.exe'
