[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (
)

$chezmoiScriptsPath = Join-Path (chezmoi source-path) .chezmoiscripts
Write-Verbose "Chezmoi Scripts Path is $chezmoiScriptsPath"
$tempOutPath = Join-Path $chezmoiScriptsPath '..' 'outchezmoiscripts'
Write-Verbose "Output base path is $tempOutPath"
if (-not ( Test-Path $tempOutPath ) ) {
    if ($PSCmdlet.ShouldProcess($tempOutPath, 'Creating .gitignored output directory for scripts')) {
        Write-Verbose "Creating out directory $tempOutPath"
        New-Item -Path $tempOutPath -ItemType Directory | Out-Null
    }
}
$chezmoiScripts = Get-ChildItem -Path $chezmoiScriptsPath -Filter *tmpl -Recurse
foreach ( $currentScript in $chezmoiScripts ) {
    $currentOutFilePath = Join-Path $tempOutPath $currentScript.BaseName
    $currentScriptTemplateFilePath = $currentScript.FullName
    if ($PSCmdlet.ShouldProcess($currentScript.FullName, "Creating actual script from template")) {
        $currentScriptOutput = chezmoi execute-template --file $currentScriptTemplateFilePath 2>&1
        if ($LASTEXITCODE -gt 0) {
            Write-Error "Failed to execute template for $currentScriptTemplateFilePath | $currentScriptOutput"
            continue
        }
        $currentScriptOutput | Set-Content -Path $currentOutFilePath
        Write-Verbose "Generated script $currentOutFilePath"
    }
}
