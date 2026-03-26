#Requires -Modules PSToml
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

switch ($PSCmdlet.ParameterSetName) {
    'All' { $tomlData.pwshAlias.all.Add($Name, $Value) }
    'Windows' { $tomlData.pwshAlias.windows.Add($Name, $Value) }
    'Desktop' { $tomlData.pwshAlias.desktop.Add($Name, $Value) }
    'Core' { $tomlData.pwshAlias.core.Add($Name, $Value) }
    Default {}
}

$tomlData | ConvertTo-Toml -Depth 3 | Set-Content $pwshAliasFile
