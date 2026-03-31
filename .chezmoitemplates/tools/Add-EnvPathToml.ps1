#Requires -Modules PSToml
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]
    $Path,
    [Parameter(Mandatory)]
    [ValidateSet('windows')]
    [string]
    $Platform
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$tomlPath = "$PSScriptRoot\envPath.toml"
$data = Get-Content -Path $tomlPath -Raw | ConvertFrom-Toml

switch ($Platform) {
    'windows' {
        $platformLower = $Platform.ToLower()
        if ($data.$platformLower -notcontains $Path) {
            $data.$platformLower += $Path
        }
        else {
            Write-Verbose "$Path is already contained in file."
            return
        }
    }
    Default { throw [System.InvalidOperationException]'Default Platform not implemented' }
}

if ($PSCmdlet.ShouldProcess($tomlPath, "Adding $Path")) {
    $data | ConvertTo-Toml -Depth 3 | Set-Content -Path $tomlPath
}
