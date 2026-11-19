<#
.SYNOPSIS
    Edit pipeline input in Neovim or Vim like a filter and return the edited text.
.DESCRIPTION
    Collects pipeline input into a temporary file and opens it in Neovim.
    Need to save and query to return output to the parent standard out.
.EXAMPLE
    Get-Clipboard | Out-Neovim
.EXAMPLE
    Get-ChildItem | ForEach-Object Name | Out-Neovim -LanguageExtension ps1
.EXAMPLE
    ... | onvim ps1 | Set-Clipboard
.EXAMPLE
    ... | onvim -OutVariable edited | Out-Null
#>
function Out-Vi {
    [Alias('Out-Vim', 'ovim', 'onvim', 'Out-Nvim', 'Out-Neovim', 'ovi')]
    [CmdletBinding()]
    param(
        # Optional extension used by Neovim for filetype detection.
        [Parameter(Position = 0)]
        [Alias('ext')]
        [ArgumentCompletions(
            'sql', 'ps1', 'md', 'js', 'ts', 'json', 'csv', 'ini',
            'yml', 'cs', 'xml', 'html', 'css', 'tmpl', 'go', 'rs',
            'cpp', 'hpp', 'c', 'h'
        )]
        [string]
        $LanguageExtension,

        # Text to edit.
        [Parameter(ValueFromPipeline, Mandatory, Position = 1)]
        [AllowEmptyString()]
        [string]
        $InputObject,

        # Whether to collect all the input strings into a single buffer
        [Parameter(ParameterSetName = 'Raw')]
        [Alias('SingleBuffer', 'r', 'ra')]
        [switch]
        $Raw,

        # String to Join list of strings with in Raw Mode
        [Parameter(ParameterSetName = 'Raw')]
        [Alias('rjw')]
        $RawJoinWith = [System.Environment]::NewLine
    )

    begin {
        foreach ($currentCommand in 'nvim', 'vim', 'vi' ) {
            # Using `-CommandType Application` returns all results and _neovim_ adds its own path to `$env:Path`
            $viCommand = Get-Command -Name $currentCommand -CommandType 'Application' -TotalCount 1 -ErrorAction 'Ignore'
            if($viCommand) {
                Write-Debug "Found vi-like command: $viCommand at $($viCommand.Path)"
                break
            }
        }

        if (-not $viCommand) {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Management.Automation.CommandNotFoundException]::new(
                    'Cannot find vi-like binary. Install vi-like editor or fix the PATH environment variable.'
                ),
                'Profile.psm1.OutVi.MissingDependency',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                '*vi*.exe'
            )

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        $inputLines = $null
        if ($Raw) {
            $inputLines = [System.Collections.Generic.List[string]]::new()
        }
    }

    process {
        if ($Raw) {
            $inputLines.Add($InputObject)
        }
        elseif ($InputObject) {
            Invoke-Vi -InputObject $InputObject -LanguageExtension $LanguageExtension -EditorCommand $viCommand
        }
    }

    end {
        # Somewhat duplicating check in `$Raw` to pass strict mode requirements on `$null` property calls
        if ($Raw -and $inputLines.Count -gt 0) {
            $endInputString = $inputLines -join $RawJoinWith
            Invoke-Vi -InputObject $endInputString -LanguageExtension $LanguageExtension -EditorCommand $viCommand
        }
    }
}

