# Copyright: (c) 2020, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

function Get-SmbShareRemote {
    <#
    .SYNOPSIS
    Enumerate shares on a remote host.
    .DESCRIPTION
    Enumerate shares on a remote host and returns the name, type, and special remark for those shares.
    .PARAMETER ComputerName
    [String] The host to enumerate the shares for. Can be accepted as pipeline input by value.
    .OUTPUTS
    [PSCustomObject]@{
        ComputerName = [String]'The computer the share relates to'
        Name = [String]'The name of the share'
        Path = [string]'\\ComputerName\Name\'
        Type = [Win32Share.ShareType] An flag enum of the share properties, can be
            Disk = Disk drive share
            PrintQueue = Print queue share
            CommunicationDevice = Communication device share
            Ipc = Interprocess communication share
            Temporary = A temporary share
            Special = Typically a special/admin share like IPC$, C$, ADMIN$
        Remark = [String]'More info on the share'
        TotalBytes = [System.Nullable[int]]
        TotalFreeBytes = [System.Nullable[int]]
        FreeBytesAvailableToUser = [System.Nullable[int]]
    }
    .LINK
    https://gist.github.com/jborean93/017d3d890ae8d33276a08d3f5cc7eb45
    .EXAMPLE
    Get-SmbShareInfo -ComputerName some-host
    #>
    [Alias('gsmbr')]
    [CmdletBinding(DefaultParameterSetName='ComputerName')]
    param (
        [Parameter(Mandatory, ParameterSetName='ComputerName', Position=0)]
        [Alias('cn')]
        [string[]]
        $ComputerName,
        # Computer Name Input Object
        [Parameter(ValueFromPipeline, ParameterSetName='Pipeline')]
        [string]
        $InputObject,
        # Name Of Share
        [Parameter(ParameterSetName ='ComputerName', Position=1)]
        [Parameter(ParameterSetName='Pipeline')]
        [SupportsWildcards()]
        [Alias('nm')]
        [string[]]
        $Name
    )

    begin {
        <#Check if loaded to make dot-source testing easier#>
        if(-not ('Win32Share.NativeMethods' -as [type])){
            Add-Type -ErrorAction 'Stop' -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace Win32Share
{
    public class NativeHelpers
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct SHARE_INFO_1
        {
            [MarshalAs(UnmanagedType.LPWStr)] public string shi1_netname;
            public ShareType shi1_type;
            [MarshalAs(UnmanagedType.LPWStr)] public string shi1_remark;
        }
    }
    public class NativeMethods
    {
        [DllImport("Netapi32.dll")]
        public static extern UInt32 NetApiBufferFree(
            IntPtr Buffer);
        [DllImport("Netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern Int32 NetShareEnum(
            string servername,
            UInt32 level,
            ref IntPtr bufptr,
            UInt32 prefmaxlen,
            ref UInt32 entriesread,
            ref UInt32 totalentries,
            ref UInt32 resume_handle);
        [DllImport("Kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool GetDiskFreeSpaceEx(
            string lpDirectoryName,
            ref UInt64 lpFreeBytesAvailableToCaller,
            ref UInt64 lptotalNumberOfBytes,
            ref UInt64 lpTotalNumberOfFreeBytes
        );
    }
    [Flags]
    public enum ShareType : uint
    {
        Disk = 0,
        PrintQueue = 1,
        CommunicationDevice = 2,
        Ipc = 3,
        Temporary = 0x40000000,
        Special = 0x80000000,
    }
}
'@
        }
        $PSBoundParameters['PSC'] = $PSCmdlet
        function GetSmbInf ($ComputerName, $Name, [System.Management.Automation.PSCmdlet]$PSC) {
            $buffer = [IntPtr]::Zero
            $read = 0
            $total = 0
            $resume = 0
            
            $res = [Win32Share.NativeMethods]::NetShareEnum(
                $ComputerName,
                1,  # SHARE_INFO_1
                [ref]$buffer,
                ([UInt32]"0xFFFFFFFF"),  # MAX_PREFERRED_LENGTH
                [ref]$read,
                [ref]$total,
                [ref]$resume
            )
    
            if ($res -ne 0) {
                $exp = [System.ComponentModel.Win32Exception]$res
                $er = [System.Management.Automation.ErrorRecord]::new(
                    $exp,
                    'Win32Share.NativeMethods.GetSmbInf.RemoteException',
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $ComputerName
                )
                $er.ErrorDetails = "Failed to enumerate share for '$ComputerName': $($exp.Message)"
                $PSC.WriteError( $er )
                return
            }
    
            try {
                $entryPtr = $buffer
                for ($i = 0; $i -lt $total; $i++) {
                    $shareInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($entryPtr,
                        [Type]([Win32Share.NativeHelpers+SHARE_INFO_1]))
    
                    $netNm = $shareInfo.shi1_netname
                    if ($Name) {
                        $isLike = $false
                        foreach ($nm in $Name) {
                            if ($netNm -like $nm) {
                                $isLike = $true
                                continue
                            }
                        }
                        if (-not $isLike) {
                            $entryPtr = [IntPtr]::Add($entryPtr, [System.Runtime.InteropServices.Marshal]::SizeOf($shareInfo))
                            continue
                        }
                    }
                    $shTyp = $shareInfo.shi1_type
                    # API below requires an ending backslash
                    $shrPath = "\\$ComputerName\$netNm\"
                    $freeBytesAvailableToCaller = 0
                    [System.Nullable[UInt64]]$freeBytesAvailableToCallerNull = $null
                    $totalNumberOfBytes = 0
                    [System.Nullable[UInt64]]$totalNumberOfBytesNull = $null
                    $totalNumberOfFreeBytes = 0
                    [System.Nullable[UInt64]]$totalNumberOfFreeBytesNull = $null
                    $lastWin32Error = 0
                    
    
                    if (($shTyp -bor [Win32Share.ShareType]::Disk) -eq [Win32Share.ShareType]::Disk) {
                        $dskRes = [Win32Share.NativeMethods]::GetDiskFreeSpaceEx(
                            $shrPath,
                            [ref]$freeBytesAvailableToCaller,
                            [ref]$totalNumberOfBytes,
                            [ref]$totalNumberOfFreeBytes
                        )
                        if ($dskRes) {
                            $freeBytesAvailableToCallerNull = $freeBytesAvailableToCaller
                            $totalNumberOfBytesNull = $totalNumberOfBytes
                            $totalNumberOfFreeBytesNull = $totalNumberOfFreeBytes
                        }
                        else {
                            # https://stackoverflow.com/questions/17918266/winapi-getlasterror-vs-marshal-getlastwin32error
                            $lastWin32Error = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                            $exp = [System.ComponentModel.Win32Exception]$lastWin32Error
                            $er = [System.Management.Automation.ErrorRecord]::new(
                                $exp,
                                'Win32Share.NativeMethods.GetSmbInf.ShareException',
                                [System.Management.Automation.ErrorCategory]::NotSpecified,
                                $shrPath
                            )
                            $er.ErrorDetails = "Failed to get disk space on '$shrPath' for '$ComputerName': $($exp.Message)"
                            $PSC.WriteError( $er )
                        }
                    }
    
                    [PSCustomObject]@{
                        PSTypeName = 'Win32Share.NativeMethods' # Used in Formatter
                        ComputerName = $ComputerName
                        Path = $shrPath
                        Name = $netNm
                        Type = $shTyp
                        Remark = $shareInfo.shi1_remark
                        TotalBytes = $totalNumberOfBytesNull
                        TotalFreeBytes = $totalNumberOfFreeBytesNull
                        FreeBytesAvailableToUser = $freeBytesAvailableToCallerNull
                    }
    
                    $entryPtr = [IntPtr]::Add($entryPtr, [System.Runtime.InteropServices.Marshal]::SizeOf($shareInfo))
                }
            } finally {
                $null = [Win32Share.NativeMethods]::NetApiBufferFree($buffer)
            }
        }
        if (-not $InputObject) {
            foreach ($compNm in $ComputerName) {
                $PSBoundParameters['ComputerName'] = $compNm
                GetSmbInf @PSBoundParameters
            }
        }
    }

    process {
        if ($InputObject) {
            $PSBoundParameters['ComputerName'] = $InputObject
            $null = $PSBoundParameters.Remove( 'InputObject')
            GetSmbInf @PSBoundParameters
        }
    }
}