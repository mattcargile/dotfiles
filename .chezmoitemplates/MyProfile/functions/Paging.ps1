function Out-Paging {
    [Alias('op')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        # For some reason, `$env:LESS` config isn't propagating
        $pipe = { Out-AnsiFormatting -Stream | less $env:LESS @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}

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
function Out-Bat {
    [Alias('ob')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        $includeStyle = $MyInvocation.ExpectingInput
        $style = '--style', 'grid,numbers,snip'
        foreach ($arg in $ArgumentList) {
            if ($arg -match '^--style=') {
                $includeStyle = $false
                break
            }

            if ($arg -match '^--file-name') {
                $style = '--style', 'grid,numbers,snip,header-filename'
            }
        }

        if ($includeStyle) {
            $ArgumentList += $style
        }

        $pipe = { bat @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}
function Format-PowerShell {
    [Alias('fpsh')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        $ArgumentList += '--language', 'powershell'
        $pipe = { Out-Bat @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}

function Format-CSharp {
    [Alias('fcs')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        $ArgumentList += '--language', 'cs'
        $pipe = { Out-Bat @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}

function Format-Sql {
    [Alias('fsql')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        $ArgumentList += '--language', 'sql'
        $pipe = { Out-Bat @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}

function Format-Xml {
    #.Synopsis
    #   Pretty-print formatted XML source
    #.Description
    #   Runs an XmlDocument through an auto-indenting XmlWriter
    #.Example
    #   [xml]$xml = get-content Data.xml
    #   C:\PS>Format-Xml $xml
    #.Example
    #   get-content Data.xml | Format-Xml
    #.Example
    #   Format-Xml C:\PS\Data.xml -indent 1 -char `t
    #   Shows how to convert the indentation to tabs (which can save bytes dramatically, while preserving readability)
    #.Example
    #   ls *.xml | Format-Xml
    #
    [Alias('fxml')]
    [CmdletBinding()]
    param(
        #   The Xml Document
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Document")]
        [xml]$Xml,

        # The path to an xml document (on disc or any other content provider).
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "File")]
        [Alias("PsPath")]
        [string]$Path,

        # The indent level (defaults to 2 spaces)
        [Parameter(Mandatory = $false)]
        [int]$Indent = 2,

        # The indent character (defaults to a space)
        [char]$Character = ' '
    )
    begin {
        $ArgumentList += '--language', 'xml'
        $pipe = { Out-Bat @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        if ($Path) { [xml]$xml = Get-Content $Path }

        $StringWriter = New-Object System.IO.StringWriter
        $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter
        $xmlWriter.Formatting = "indented"
        $xmlWriter.Indentation = $Indent
        $xmlWriter.IndentChar = $Character
        $xml.WriteContentTo($XmlWriter)
        $XmlWriter.Flush()
        $StringWriter.Flush()
        $pipe.Process($StringWriter.ToString())
    }
    end {
        $pipe.End()
    }
}

function Format-HtmlPretty {
    [Alias('fhtml')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        $ArgumentList += '--language', 'html'
        # Xml Module has a Format-Html function, so need to fully qualify it here.
        $pipe = { PSParseHTML\Format-HTML | Out-Bat @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}

function Format-JavaScriptPretty {
    [Alias('fjs')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([string])]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList,

        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject
    )
    begin {
        $ArgumentList += '--language', 'js'
        $pipe = { PSParseHTML\Format-JavaScript | Out-Bat @ArgumentList }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}
