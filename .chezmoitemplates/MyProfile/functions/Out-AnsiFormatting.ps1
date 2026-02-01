function Out-AnsiFormatting {
    [Alias('oaf')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [scriptblock] $Pipeline = { Out-String @BoundParameters },

        [Parameter(Position = 1)]
        [System.Collections.IDictionary] $BoundParameters = @{},

        [Parameter()]
        [Alias('s')]
        [switch] $Stream
    )
    begin {
        $pipe = $null
        try {
            if ($PSVersionTable.PSVersion -lt [version]'7.3.0') {
                throw [System.NotSupportedException]'$PSStyle.OutputRendering not supported in this version of PowerShell.'
            }
            if ($Stream) {
                $BoundParameters['Stream'] = $Stream
            }

            if ($InputObject) {
                $BoundParameters['InputObject'] = $InputObject
            }

            $old = $global:PSStyle.OutputRendering
            try {
                $global:PSStyle.OutputRendering = 'Ansi'
                $pipe = $Pipeline.Ast.GetScriptBlock().GetSteppablePipeline($MyInvocation.CommandOrigin)
                $pipe.Begin($PSCmdlet)
            }
            finally {
                $global:PSStyle.OutputRendering = $old
            }
        }
        catch [System.NotSupportedException] {
            throw
        }
        catch {
            $PSCmdlet.WriteError($PSItem)
        }
    }
    process {
        $BoundParameters['InputObject'] = $InputObject
        try {
            $old = $PSStyle.OutputRendering
            try {
                $PSStyle.OutputRendering = 'Ansi'
                $pipe.Process($PSItem)
            }
            finally {
                $PSStyle.OutputRendering = $old
            }
        }
        catch {
            $PSCmdlet.WriteError($PSItem)
        }
    }
    end {
        $BoundParameters['InputObject'] = $InputObject
        try {
            $old = $PSStyle.OutputRendering
            try {
                $PSStyle.OutputRendering = 'Ansi'
                $pipe.End()
            }
            finally {
                $PSStyle.OutputRendering = $old
            }
        }
        catch {
            $PSCmdlet.WriteError($PSItem)
        }
    }
}
