# Copyright: (c) 2024, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Split-ExeArgument {
    [OutputType([string])]
    [Alias('slexe')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $InputObject
    )
    
    begin {
        $s32 = New-CtypesLib Shell32.dll

        $s32.CharSet('Unicode').SetLastError().Returns([IntPtr]).CommandLineToArgvW = [Ordered]@{
            lpCmdLine = [string]
            pNumArgs = [ref][int]
        }
    }
    
    process {
        foreach ($cmdArg in $InputObject) {
            $numArgs = 0
            $res = $s32.CommandLineToArgvW($cmdArg, [ref]$numArgs)
            if ($res -eq [IntPtr]::Zero) {
                $exc = [System.ComponentModel.Win32Exception]::new($s32.LastError)
                $err = [System.Management.Automation.ErrorRecord]::new(
                    $exc,
                    "FailedToConvert",
                    "NotSpecified",
                    $cmdArg)
                $err.ErrorDetails = ""
                $PSCmdlet.WriteError($err)
                continue
            }

            try {
                $argPtrs = [IntPtr[]]::new($numArgs)
                [System.Runtime.InteropServices.Marshal]::Copy($res, $argPtrs, 0, $numArgs)
                foreach ($ptr in $argPtrs) {
                    [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
                }
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($res)
            }
        }
    }
}
