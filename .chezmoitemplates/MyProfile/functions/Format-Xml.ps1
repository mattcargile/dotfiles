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
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = "Document")]
        [xml]$Xml,

        # The path to an xml document (on disc or any other content provider).
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "File")]
        [Alias("PsPath")]
        [string]$Path,

        # The indent level (defaults to 2 spaces)
        [int]$Indent = 2,

        # The indent character (defaults to a space)
        [char]$Character = ' '
    )
    begin {
        $batArgs = '--language', 'xml'
        $pipe = { Out-Bat @batArgs }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($PSCmdlet)
    }
    process {

        try {
            if ($Path) {
                $Xml = Get-Content $Path -Raw
            }
            $stringWriter = New-Object System.IO.StringWriter
            $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter
            $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
            $xmlWriter.Indentation = $Indent
            $xmlWriter.IndentChar = $Character
            $Xml.WriteContentTo($XmlWriter)
            $pipe.Process($stringWriter.ToString())
        }
        catch {
            throw
        }
        finally {
            if ($xmlWriter) {
                $xmlWriter.Dispose()
            }
            if ($stringWriter) {
                $stringWriter.Dispose()
            }
        }
    }
    end {
        $pipe.End()
    }
}
