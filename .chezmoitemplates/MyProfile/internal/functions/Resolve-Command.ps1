function Resolve-Command {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [psobject]
        $Command
    )

    process {
        if (-not $Command) {
            return $null
        }
        $supportedCommandTypes = 'Alias', 'Filter', 'Cmdlet', 'Function'
        # Need `Get-Command` to auto load module. using `GetCommand` doesn't 
        $cmd = $Command
        if ($cmd -is [string]) {
            $cmd = Get-Command -Name ([WildcardPattern]::Escape($cmd)) -CommandType $supportedCommandTypes
            if (-not $cmd) { $cmd = $inputData }
        }
        # Some commands have pre-loaded modules so they resolve properly.
        # Implicitly loaded commands won't have the `ResolvedCommand` property
        if ($cmd.ResolvedCommand -is [System.Management.Automation.CommandInfo] -and $null -ne $cmd.ResolvedCommand) {
            return $cmd.ResolvedCommand
        }
        while ($cmd -is [System.Management.Automation.AliasInfo]) {
            $cmdDefEsc = [WildcardPattern]::Escape($cmd.Definition)
            # Some fully qualified module and cmdlet names return the wrong ModuleName and Source like `Get-ScheduledTask`
            $cmdDefEscSplit = $cmdDefEsc -split '\\', 2
            if ($cmdDefEscSplit.Count -eq 2) {
                $cmd = Get-Command -Module $cmdDefEscSplit[0] -Name $cmdDefEscSplit[1] -CommandType $supportedCommandTypes
                if (-not $cmd) {
                    $cmd = Get-Command -Name $cmdDefEscSplit[1] -CommandType $supportedCommandTypes
                }
            }
            else {
                $cmd = Get-Command $cmdDefEsc -CommandType $supportedCommandTypes
            }
        }
        if ($cmd -is [System.Management.Automation.CommandInfo]) {
            return $cmd 
        }
        Write-Debug "Did not find CommandInfo for $Command."
        return $null
    }
}
