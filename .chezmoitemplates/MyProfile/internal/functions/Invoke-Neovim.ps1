<#
.SYNOPSIS
    Invokes a vi like editor with input strings
#>
filter Invoke-Neovim
{
    [CmdletBinding()]
    param(
        # Text to edit.
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]
        $InputObject,

        # Programming Language extension
        [Parameter()]
        [string]
        $LanguageExtension,

        # The editor command name to run
        [Parameter(Mandatory)]
        [string]
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

        $viProcess = Start-Process -FilePath $EditorCommand -ArgumentList "`"$($temporaryFile.FullName)`"" -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
        if ($viProcess.ExitCode -ne 0) {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [InvalidOperationException]::new(
                    "Neovim exited with code $($viProcess.ExitCode)."
                ),
                'Profile.psm1.OutNeovim.EditorFailed',
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

