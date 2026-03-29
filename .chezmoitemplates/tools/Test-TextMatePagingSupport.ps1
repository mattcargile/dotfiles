[CmdletBinding()]
[OutputType([string])]
param (
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$pwshSupportedVersion = [version]'7.4.0'
$pagerSupportedVersion = [version]'0.2.1'
$latestModuleVersion = Get-Module -Name TextMate -ListAvailable | Sort-Object -Property Version -Descending -Top 1 | ForEach-Object -MemberName Version

if ($PSVersionTable.PSVersion -ge $pwshSupportedVersion -and $latestModuleVersion -ge $pagerSupportedVersion) {
    $true.ToString()
}
else {
    $false.ToString()
}
