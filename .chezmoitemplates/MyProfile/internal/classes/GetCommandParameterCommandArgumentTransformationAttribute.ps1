class GetCommandParameterCommandArgumentTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics] $engineIntrinsics, [object] $inputData) {
        $cmd = Resolve-Command -Command $inputData
        if ($cmd -is [System.Management.Automation.CommandInfo]) {
            return $cmd 
        }
        throw [System.Management.Automation.ArgumentTransformationMetadataException]"Did not find CommandInfo for $inputData."
    }
}
