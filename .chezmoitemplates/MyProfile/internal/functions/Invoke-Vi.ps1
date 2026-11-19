<#
.SYNOPSIS
    Invokes a vi like editor with input strings
#>
filter Invoke-Vi
{
    [CmdletBinding()]
    param(
        # Text to edit. Supporting empty string in the odd case where there
        # is a LF or CRLF in a file and commands like `Get-Content` return
        # empty string for those entries. `'' -join [Environment]::NewLine`
        # still returns a single empty string
        [Parameter(ValueFromPipeline, Mandatory)]
        [AllowEmptyString()]
        [string]
        $InputObject,

        # Programming Language extension
        [Parameter()]
        [string]
        $LanguageExtension,

        # The editor command name to run
        [Parameter(Mandatory)]
        [System.Management.Automation.ApplicationInfo]
        $EditorCommand
    )

    try {
        $temporaryFile = New-TemporaryFile -ErrorAction 'Stop'
        if ($LanguageExtension) {
            $extension = $LanguageExtension.TrimStart('.')
            $newName = "$($temporaryFile.BaseName).$extension"

            $temporaryFile = Rename-Item -LiteralPath $temporaryFile.FullName -NewName $newName -PassThru -ErrorAction 'Stop'
        }

        Set-Content -LiteralPath $temporaryFile.FullName -Value $InputObject -ErrorAction 'Stop'

        $viProcess = Start-Process -FilePath $EditorCommand.Path -ArgumentList "`"$($temporaryFile.FullName)`"" -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
        if ($viProcess.ExitCode -ne 0) {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [InvalidOperationException]::new(
                    "$EditorCommand exited with code $($viProcess.ExitCode)."
                ),
                'Profile.psm1.OutVi.EditorFailed',
                [System.Management.Automation.ErrorCategory]::OperationStopped,
                $temporaryFile
            )

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
        Get-Content -LiteralPath $temporaryFile.FullName -Raw
    }
    finally {
        Remove-Item -LiteralPath $temporaryFile.FullName -Force -ErrorAction Ignore
    }
}

