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
function Out-Neovim {
    [Alias('Out-Vim', 'ovim', 'onvim')]
    [CmdletBinding()]
    param(
        # Optional extension used by Neovim for filetype detection.
        [Parameter(Position = 0)]
        [Alias('ext')]
        [ArgumentCompletions(
            'sql', 'ps1', 'md', 'js', 'ts', 'json', 'csv', 'ini',
            'yml', 'cs', 'xml', 'html', 'css', 'tmpl'
        )]
        [string]
        $LanguageExtension,

        # Text to edit.
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]
        $InputObject,

        # Whether to collect all the input strings into a single buffer
        [Parameter()]
        [Alias('SingleBuffer', 'r')]
        [switch]
        $Raw
    )

    begin {
        if ( Get-Command -Name 'nvim' -CommandType 'Application' -ErrorAction 'Ignore' ) {
            $viCommand = 'nvim'
        }
        elseif ( Get-Command -Name 'vim' -CommandType 'Application' -ErrorAction 'Ignore' ) {
            $viCommand = 'vim'
        }
        elseif ( Get-Command -Name 'vim' -CommandType 'Application' -ErrorAction 'Ignore' ) { 
            $viCommand = 'vi'
        }

        if (-not $viCommand) {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new(
                    'Cannot find nvim.exe. Install Neovim or fix the PATH environment variable.'
                ),
                'Profile.psm1.OutNeovim.MissingDependency',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'nvim.exe'
            )

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        if ($Raw) {
            $inputLines = [System.Collections.Generic.List[string]]::new()
        }
    }

    process {
        if ($Raw) {
            $inputLines.Add($InputObject)
        }
        else {
            Invoke-Neovim -InputObject $InputObject  -LanguageExtension $LanguageExtension -EditorCommand $viCommand
        }
    }

    end {
        if ($Raw) {
            Invoke-Neovim -InputObject $inputLines -LanguageExtension $LanguageExtension -EditorCommand $viCommand
        }
    }
}

