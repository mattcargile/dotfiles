# https://github.com/SeeminglyScience/dotfiles/blob/main/Documents/PowerShell/Utility.psm1
class CommandInfoArgumentConverterAttribute : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics] $engineIntrinsics, [object] $inputData) {
        # Need `Get-Command` to auto load module. using `GetCommand` doesn't 
        $cmd = $inputData
        if ($cmd -is [string]) {
            $cmd = Get-Command -Name ([WildcardPattern]::Escape($cmd)) 
            if (-not $cmd) { $cmd = $inputData }
        }
        # Weird behavior with ActiveDirectory module and accounting for nested aliases
        while ($cmd -is [System.Management.Automation.AliasInfo]) {
            $cmd = Get-Command ([WildcardPattern]::Escape($cmd.Definition))
        }
        if ($cmd -is [System.Management.Automation.CommandInfo]) {
            # Force module auto load
            # string module overrides Join-String in an interesting way so need to select the first one
            return ( $cmd | Get-Command | Select-Object -First 1)
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
