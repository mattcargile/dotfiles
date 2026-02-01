function Get-CommandFromString ([string]$cmd) {
    if (-not $cmd) {
        return $null
    }
    $commandInfo = Get-Command ([WildcardPattern]::Escape($cmd)) | Select-Object -First 1
    while ($commandInfo -is [System.Management.Automation.AliasInfo]) {
        $commandInfo = Get-Command ([WildcardPattern]::Escape($commandInfo.Definition)) | Select-Object -First 1
    }
    if ($commandInfo -is [System.Management.Automation.CommandInfo]) {
        return $commandInfo
    }
}
