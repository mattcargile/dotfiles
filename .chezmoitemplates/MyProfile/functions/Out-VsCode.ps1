function Out-VsCode {
    <#
    .SYNOPSIS
        Pipe STDIN to vscode, quit to pipe the editor to STDOUT
    .DESCRIPTION
        You do have to hit save. Edit and close 
    .EXAMPLE
        Get-Clipboard | Out-VsCode
        Default is stdout
    .EXAMPLE
        gci . | % Name | Out-VsCode -LanguageExtension Ps1
        Set an extension for optional syntax highlighting
    .EXAMPLE
        ... | Out-VsCode Ps1 | Set-ClipBoard
        Set clipboard
    .EXAMPLE
        ... | Out-VsCode -OutVariable OutVar
        Save results to the variable $OutVar And Output to Standard In
    .EXAMPLE
        ... | Out-VsCode -OutVariable OutVar | Out-Null
        Save results to the variable $OutVar and silence the output
    .EXAMPLE
        ... | ovsc ps1 | onl
        Shorthand example
    #>
    [Alias('ovsc')]
    [CmdletBinding()]
    param(
        # Optionally choose a file extension for colors
        [Alias('ext')]
        [ArgumentCompletions('sql','ps1', 'md', 'js', 'ts', 'json', 'csv', 'ini', 'yml', 'cs', 'xml', 'html', 'css')]
        [string]$LanguageExtension,
        # String Data to pipe into VS Code
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]
        $InputObject
    )
    begin{
        if (-not (Get-Command -Name 'code.cmd' -CommandType Application -ErrorAction Ignore)) {
            $err = [System.Management.Automation.ErrorRecord]::(
                [System.Exception]::new('Cannot find code.cmd. Install VS Code or fix Path environment variable.'),
                'Profile.psm1.OutVsCode.MissingDependency',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'code.cmd')
            $PSCmdlet.ThrowTerminatingError($err)
        }
    }
    process{
        $randFile = New-TemporaryFile
        if( $PSBoundParameters.ContainsKey( 'LanguageExtension') ) {
            $newRandFileName = "$($randFile.BaseName).$LanguageExtension"
            $newRandFilePath = Join-Path $randFile.Directory $newRandFileName
            Rename-Item -Path $randFile -NewName $newRandFileName
            $randFile = Get-Item $newRandFilePath 
        }

        $InputObject | Set-Content -Path $randFile

        & code.cmd @(
            '--wait'
            '--goto'
            $randFile )

        Get-Content -Path $randFile -Raw

        if(Test-Path $randFile -ErrorAction Ignore){
            Remove-Item $randFile -ErrorAction Ignore
        }
    }
}
