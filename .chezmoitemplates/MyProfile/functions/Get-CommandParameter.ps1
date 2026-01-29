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
class UtilityCommandParameterInfo {
    [string]$Set
    [System.Collections.ObjectModel.ReadOnlyCollection[string]]$Aliases
    [int]$Position
    [bool]$IsDynamic
    [bool]$IsMandatory
    [bool]$ValueFromPipeline
    [bool]$ValueFromPipelineByPropertyName
    [bool]$ValueFromRemainingArguments
    [type]$Type
    [string]$Name
    [System.Collections.ObjectModel.ReadOnlyCollection[System.Attribute]]$Attributes
    [bool]$IsDefaultSet
}
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

# Mainly just for Get-CommandParameter completers
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
function Get-InferredCommand {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $FakeBoundParameters,

        [System.Management.Automation.Language.CommandAst] $CommandAst
    )
    end {
        $command = $FakeBoundParameters['Command']
        if ($command = Get-CommandFromString $command) {
            return $command
        }

        if ($CommandAst.Parent -isnot [System.Management.Automation.Language.PipelineAst]) {
            return
        }

        $index = $CommandAst.Parent.PipelineElements.IndexOf($CommandAst)
        if ($index -le 0) {
            return
        }

        $previous = $CommandAst.Parent.PipelineElements[$index - 1]
        if ($previous -isnot [System.Management.Automation.Language.CommandAst]) {
            return
        }

        $previousName = $previous.GetCommandName()
        if ($previousName -notin 'gcm', 'Get-Command') {
            return
        }

        $firstArg = $Previous.CommandElements[1]
        if ($firstArg -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) {
            return
        }

        $firstArg = $firstArg.Value
        if (-not $firstArg) {
            return
        }

        return Get-CommandFromString $firstArg
    }
}

Register-ArgumentCompleter -CommandName Get-CommandParameter -ParameterName Name -ScriptBlock {
    param(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
    )
    end {
        if (-not $wordToComplete) {
            $wordToComplete = '*'
        } else {
            $wordToComplete += '*'
        }

        $command = Get-InferredCommand -FakeBoundParameters $fakeBoundParameters -CommandAst $commandAst
        if (-not $command) {
            return
        }

        foreach ($parameter in $command.Parameters.Values) {
            if (-not $fakeBoundParameters['IncludeCommon'] -and [System.Management.Automation.Cmdlet]::CommonParameters.Contains($parameter.Name)) {
                continue
            }
            if ($parameter.Name -like $wordToComplete) {
                # yield
                [System.Management.Automation.CompletionResult]::new(
                    $parameter.Name,
                    $parameter.Name,
                    [System.Management.Automation.CompletionResultType]::ParameterValue,
                    $parameter.Name)
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Get-CommandParameter -ParameterName Command -ScriptBlock {
    param(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
    )
    end {
        if (-not $wordToComplete) {
            $wordToComplete = '*'
        }

        return [System.Management.Automation.CompletionCompleters]::CompleteCommand($wordToComplete)
    }
}
