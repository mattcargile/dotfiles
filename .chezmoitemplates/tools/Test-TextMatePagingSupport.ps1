[CmdletBinding()]
[OutputType([string])]
param (
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$pagerSupportedVersion = [version]'0.2.1'
$latestModuleVersion = ( Get-Module -Name TextMate -ListAvailable | Sort-Object -Property Version -Descending -Top 1 ).Version

if ($latestModuleVersion -ge $pagerSupportedVersion) {
    $true.ToString()
}
else {
    $false.ToString()
}
