# https://github.com/SeeminglyScience/dotfiles/blob/main/Documents/PowerShell/Utility.psm1
class CommandInfoArgumentConverterAttribute : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics] $engineIntrinsics, [object] $inputData) {
        $cmd = Resolve-Command -Command $inputData
        if ($cmd -is [System.Management.Automation.CommandInfo]) {
            return $cmd 
        }
        throw [System.Management.Automation.ArgumentTransformationMetadataException]"Did not find CommandInfo for $inputData."
    }
}
# Terrible dirty hack to get around using non-exported classes in some of the function
# parameter blocks. Don't use this in a real module pls.
# Mostly appears to not be needed. Leaving in at the behest of the original author.
$typeAccel = [ref].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$typeAccel::Add('CommandInfoArgumentConverterAttribute', [CommandInfoArgumentConverterAttribute])
$typeAccel::Add('CommandInfoArgumentConverter', [CommandInfoArgumentConverterAttribute])
Remove-Variable -Name typeAccel
