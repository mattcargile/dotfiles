[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [Alias('PSPath', 'LP')]
    [string[]]
    $LiteralPath,
    [Parameter(ParameterSetName = 'Desktop')]
    [Alias('d')]
    [switch]
    $Desktop
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$isPSCore = 'true' 
if ($Desktop) {
    $isPSCore = 'false'
}

foreach ($currentFile in $LiteralPath ) {
    $currentFileObj = Get-Item -LiteralPath $currentFile
    $currentFileRelative = $currentFileObj | Resolve-Path -Relative -RelativeBasePath $PWD.ProviderPath
    $currentTmplList = @(
@"
{{- `$tmplDict := mustMerge . ( dict 
        "isPSCore" $isPSCore
    )
-}}
"@
        "{{- `$currentFilePath := ``$currentFileObj`` -}}"
        '{{ includeTemplate $currentFilePath $tmplDict }}'
    )
    Write-Verbose "[$currentFileRelative]: '$($currentTmplList -join '')'"
    $currentTmplList | chezmoi execute-template
}

