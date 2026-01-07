function Join-String {
    [CmdletBinding(DefaultParameterSetName = 'default', RemotingCapability = 'None')]
    [Alias('join')]
    param(
        [Parameter(Position = 1)]
        [pspropertyexpression]
        ${Property},

        [Parameter(Position = 0)]
        [AllowEmptyString()]
        [string]
        ${Separator},

        [Alias('op')]
        [string]
        ${OutputPrefix},

        [Alias('os')]
        [string]
        ${OutputSuffix},

        [Parameter(ParameterSetName = 'SingleQuote')]
        [Alias('sq')]
        [switch]
        ${SingleQuote},

        [Parameter(ParameterSetName = 'DoubleQuote')]
        [Alias('dq')]
        [switch]
        ${DoubleQuote},

        [Parameter(ParameterSetName = 'Format')]
        [string]
        ${FormatString},

        [switch]
        ${UseCulture},

        [Parameter(ValueFromPipeline = $true)]
        [psobject[]]
        ${InputObject})

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Join-String', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }

    clean {
        if ($null -ne $steppablePipeline) {
            $steppablePipeline.Clean()
        }
    }
}
<#

.ForwardHelpTargetName Microsoft.PowerShell.Utility\Join-String
.ForwardHelpCategory Cmdlet

#>
