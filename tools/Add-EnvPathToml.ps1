#Requires -Modules @{ ModuleName = 'PSToml'; ModuleVersion = '0.4.0' }
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]
    $Path,
    [Parameter(Mandatory)]
    [string]
    $Comment,
    [Parameter(Mandatory)]
    [ValidateSet('Windows')]
    [string]
    $Platform
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$tomlPath = Join-Path (chezmoi source-path) .chezmoidata envPath.toml
$data = Get-Content -Path $tomlPath -Raw | ConvertFrom-Toml

$objToAdd = @{
    comment = $Comment
    path = $Path
}
switch ($Platform) {
    'windows' {
        $platformLower = $Platform.ToLower()
        if ($data.envPath.$platformLower.path -notcontains $Path) {
            $data.envPath.$platformLower += $objToAdd
        }
        else {
            Write-Verbose "$Path is already contained in file."
            return
        }
    }
    Default { throw [System.InvalidOperationException]'Default Platform not implemented' }
}

if ($PSCmdlet.ShouldProcess($tomlPath, "Adding $Path and Comment ($Comment)")) {
    $data | ConvertTo-Toml -Depth 4 | Set-Content -Path $tomlPath
}
