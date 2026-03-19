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
        $txtMatSplat = @{
            Language = 'powershell'
            Page = $true
        } 
        $sb = { TextMate\Format-TextMate @txtMatSplat }
        $batArgs = [string[]]@('--language', 'powershell')
        if (-not (Get-Module -Name TextMate)) {
            try {
                Import-Module -Name TextMate -ErrorAction Stop
            }
            catch [System.IO.FileLoadException] {
                Write-Warning 'Failed to import TextMate module due to file load and most likely dll incompatibilities. Falling back to use less pager.'
                $ArgumentList += $batArgs 
                $sb = { Out-Bat @ArgumentList }
            }
            catch {
                Write-Warning "Failed to import TextMate module. $_"
                $ArgumentList += $batArgs 
                $sb = { Out-Bat @ArgumentList }
            }
        }
        $pipe = $sb.GetSteppablePipeline($MyInvocation.CommandOrigin) 
        $pipe.Begin($PSCmdlet)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}
