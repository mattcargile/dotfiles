[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (
)

$chezmoiScriptsPath = Join-Path (chezmoi source-path) .chezmoiscripts
Write-Verbose "Chezmoi Scripts Path is $chezmoiScriptsPath"
$tempOutPath = Join-Path $chezmoiScriptsPath '..' 'outchezmoiscripts'
Write-Verbose "Output base path is $tempOutPath"
if (-not ( Test-Path $tempOutPath ) ) {
    if ($PSCmdlet.ShouldProcess($tempOutPath, 'Creating .gitignored output directory for scripts')) {
        New-Item -Path $tempOutPath -ItemType Directory | Out-Null
    }
}
$chezmoiScripts = Get-ChildItem -Path $chezmoiScriptsPath -Filter *tmpl -Recurse
foreach ( $currentScript in $chezmoiScripts ) {
    $currentOutFileName = $currentScript.BaseName -replace '^run_(before_|after_|once_|onchange_)+', ''
    if ($currentScript.Extension -ne '.tmpl') {
        $currentOutFileName += $currentScript.Extension
    }
    $currentOutFilePath = Join-Path $tempOutPath $currentOutFileName
    $currentScriptTemplateFilePath = $currentScript.FullName
    if ($PSCmdlet.ShouldProcess($currentScript.FullName, "Creating actual script $currentOutFilePath from template")) {
        $currentScriptOutput = chezmoi execute-template --file $currentScriptTemplateFilePath 2>&1
        if ($LASTEXITCODE -gt 0) {
            Write-Error "Failed to execute template for $currentScriptTemplateFilePath | $currentScriptOutput"
            continue
        }
        $currentScriptOutput | Set-Content -Path $currentOutFilePath
    }
}
