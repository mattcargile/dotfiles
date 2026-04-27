#Requires -Modules @{ ModuleName = 'PSToml'; ModuleVersion = '0.4.0' }
[CmdletBinding(DefaultParameterSetName = 'All')]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]
    $Name,
    [Parameter(Mandatory, Position = 1)]
    [string]
    $Value,
    [Parameter(ParameterSetName = 'All')]
    [switch]
    $All,
    [Parameter(ParameterSetName = 'Windows')]
    [switch]
    $Windows,
    [Parameter(ParameterSetName = 'Desktop')]
    [switch]
    $Desktop,
    [Parameter(ParameterSetName = 'Core')]
    [switch]
    $Core
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$pwshAliasFile = Join-Path (chezmoi source-path) .chezmoidata pwshAlias.toml
if (-not (Test-Path $pwshAliasFile)) {
    throw [InvalidOperationException]"Cannot find the data file for aliases at $pwshAliasFile"
}

$tomlData = Get-Content -Path $pwshAliasFile -Raw | ConvertFrom-Toml

$dictName = $PSCmdlet.ParameterSetName.ToLower()
$tomlData.pwshAlias.$dictName.Add($Name, $Value)
$workingDic = [System.Collections.Generic.OrderedDictionary[string,string]]::new($tomlData.pwshAlias.$dictName.Count)
$tomlData.pwshAlias.$dictName.GetEnumerator() | Sort-Object -Property Name | ForEach-Object -Process { $workingDic.Add($_.Name, $_.Value) }
$tomlData.pwshAlias.$dictName = $workingDic

$tomlData | ConvertTo-Toml -Depth 3 | Set-Content $pwshAliasFile
