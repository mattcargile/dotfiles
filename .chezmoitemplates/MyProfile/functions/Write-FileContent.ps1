function Write-FileContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $FileToReplacePath,
        [Parameter(Mandatory)]
        [string]
        $TextToReplaceWith,
        [Parameter(Mandatory)]
        [string]
        $LineNumber,
        [Parameter(Mandatory)]
        [string]
        $TextToReplace
    )
    # Storing contents to avoid write errors because the file is still open.
    $Read = Get-Content -Path $FileToReplacePath
    $Read | ForEach-Object {
        if ($_.ReadCount -eq $LineNumber) {
            $_ -replace $TextToReplace, $TextToReplaceWith
        }
        else { $_ }
    } | Set-Content $FileToReplacePath
}