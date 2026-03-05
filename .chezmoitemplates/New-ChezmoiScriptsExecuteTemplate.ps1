[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (
)

$chezmoiScriptsPath = Join-Path $PSScriptRoot .. .chezmoiscripts
Write-Verbose "Chezmoi Scripts Path is $chezmoiScriptsPath"
$tempOutPath = Join-Path $PSScriptRoot outchezmoiscripts
Write-Verbose "Output base path is $tempOutPath"
if (-not ( Test-Path $tempOutPath ) ) {
    if ($PSCmdlet.ShouldProcess($tempOutPath, 'Creating .gitignored output directory for scripts')) {
        Write-Verbose "Creating out directory $tempOutPath"
        New-Item -Path $tempOutPath -ItemType Directory | Out-Null
    }
}
Get-ChildItem -Path $chezmoiScriptsPath -Filter *tmpl -Recurse | ForEach-Object -Process {
    $currentOutFilePath = Join-Path $tempOutPath $_.BaseName
    $currentScriptTemplateFilePath = $_.FullName
    if ($PSCmdlet.ShouldProcess($_.FullName, "Creating actual script from template")) {
        chezmoi execute-template --file $currentScriptTemplateFilePath | Set-Content -Path $currentOutFilePath
        Write-Verbose "Generated script $currentOutFilePath"
    }
}
