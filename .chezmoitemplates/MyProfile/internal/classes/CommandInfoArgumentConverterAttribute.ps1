# https://github.com/SeeminglyScience/dotfiles/blob/main/Documents/PowerShell/Utility.psm1
class CommandInfoArgumentConverterAttribute : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics] $engineIntrinsics, [object] $inputData) {
        # Need `Get-Command` to auto load module. using `GetCommand` doesn't 
        $cmd = $inputData
        if ($cmd -is [string]) {
            $cmd = Get-Command -Name ([WildcardPattern]::Escape($cmd)) 
            if (-not $cmd) { $cmd = $inputData }
        }
        # Some commands have pre-loaded modules so they resolve properly.
        # Implicitly loaded commands won't have the `ResolvedCommand` property
        if ($cmd.ResolvedCommand -is [System.Management.Automation.CommandInfo]) {
            return $cmd.ResolvedCommand
        }
        while ($cmd -is [System.Management.Automation.AliasInfo]) {
            $cmdDefEsc = [WildcardPattern]::Escape($cmd.Definition)
            # Some fully qualified module and cmdlet names return the wrong ModuleName and Source like `Get-ScheduledTask`
            $cmdDefEscSplit = $cmdDefEsc -split '\\', 2
            if ($cmdDefEscSplit.Count -eq 2) {
                $cmd = Get-Command -Module $cmdDefEscSplit[0] -Name $cmdDefEscSplit[1]
            }
            else {
                $cmd = Get-Command $cmdDefEsc 
            }
        }
        if ($cmd -is [System.Management.Automation.CommandInfo]) {
            return $cmd 
        }
        throw [System.Management.Automation.ArgumentTransformationMetadataException]"Did not find CommandInfo for $cmd."
    }
}
# Terrible dirty hack to get around using non-exported classes in some of the function
# parameter blocks. Don't use this in a real module pls.
# Mostly appears to not be needed. Leaving in at the behest of the original author.
$typeAccel = [ref].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$typeAccel::Add('CommandInfoArgumentConverterAttribute', [CommandInfoArgumentConverterAttribute])
$typeAccel::Add('CommandInfoArgumentConverter', [CommandInfoArgumentConverterAttribute])
Remove-Variable -Name typeAccel
