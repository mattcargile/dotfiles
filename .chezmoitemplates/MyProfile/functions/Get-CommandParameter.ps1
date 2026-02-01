function Get-CommandParameter {
    [Alias('gcp')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline, Position = 0)]
        [ValidateNotNull()]
        [Alias('c')]
        [CommandInfoArgumentConverter()]
        [System.Management.Automation.CommandInfo] $Command,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('Parameter','n')]
        [SupportsWildcards()]
        [string[]] $Name,

        [Parameter()]
        [Alias('ic')]
        [switch] $IncludeCommon
    )
    begin {
        [WildcardPattern[]] $targetParameters = foreach ($target in $Name) {
            [WildcardPattern]::Get($target, [System.Management.Automation.WildcardOptions]::IgnoreCase -bor 'CultureInvariant')
        }

        if (-not $targetParameters) {
            $targetParameters = [WildcardPattern]::Get('*', [System.Management.Automation.WildcardOptions]::IgnoreCase -bor 'CultureInvariant')
        }
    }
    process {
        # Without importing module the parameter sets may be empty on FunctionInfo
        $moduleName = $Command.Source
        # Core Module doesn't show as actual module. Other modules have this behavior too for various reasons so using Ignore Error Action
        if ($moduleName -ne '' -and $null -ne $moduleName -and $moduleName -ne 'Microsoft.PowerShell.Core') {
            $module = Get-Module -Name $moduleName -ErrorAction Ignore
            if (-not $module) {
                Import-Module $module -ErrorAction Ignore
            }
        }
        foreach ($set in $Command.ParameterSets) {
            foreach ($param in $set.Parameters) {
                if (-not $IncludeCommon -and [System.Management.Automation.Cmdlet]::CommonParameters.Contains($param.Name)) {
                    continue
                }

                foreach ($target in $targetParameters) {
                    if ($target.IsMatch($param.Name)) {
                        $result = [UtilityCommandParameterInfo]@{
                            Set = $set.Name
                            Aliases = $param.Aliases
                            Position = $param.Position
                            IsDynamic = $param.IsDynamic
                            IsMandatory = $param.IsMandatory
                            ValueFromPipeline = $param.ValueFromPipeline
                            ValueFromPipelineByPropertyName = $param.ValueFromPipelineByPropertyName
                            ValueFromRemainingArguments = $param.ValueFromRemainingArguments
                            Type = $param.ParameterType
                            Name = $param.Name
                            Attributes = $param.Attributes
                            IsDefaultSet = $set.IsDefault
                        }

                        $result
                    }
                }
            }
        }
    }
}
