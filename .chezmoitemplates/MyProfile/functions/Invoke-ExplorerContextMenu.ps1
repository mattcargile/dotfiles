function Invoke-ExplorerContextMenu {
    [Alias('iecon')]
    [CmdletBinding()]
    param (
        # Folder or File path
        [Parameter(Mandatory,Position = 0)]
        [string]
        $Path,
        # Verb From Explorer Context Menu
        [Parameter(Mandatory, Position = 1)]
        [string]
        [ValidateSet('Share','VersionHistory','ManageAccess','KeepOnDevice','FreeSpace','RestoreVersion','ViewOnline','CopyLink')]
        $Verb
    )

    try {
        Write-Verbose 'Creating Shell.Application Namespace.'
        $resPath = ( Resolve-Path $Path -ErrorAction Stop ).ProviderPath
        $parentPath = Split-Path $resPath
        $child = Split-Path $resPath -Leaf
        $shell = New-Object -ComObject 'Shell.Application'
        $dir = $shell.Namespace($parentPath)
    
        $vb = 
        switch ($Verb) {
            'Share' { '&Share' }
            'VersionHistory' { '&Version History' }
            'ManageAccess' { 'Manage access' }
            'KeepOnDevice' { '&Always keep on this device' }
            'FreeSpace' { 'Free up space' } # Windows 11 removed beginning ampersand
            'RestoreVersion' { 'Restore previous &versions' }
            'ViewOnline' { '&View online' }
            'CopyLink' { 'Copy Link'}
            Default {'Unknown'}
        }
        
        $dirParsed = $dir.ParseName($child)
        $dirParsedVerbs = $dirParsed.Verbs()
        for ($i = 0; $i -lt $dirParsedVerbs.Count; $i++) {
           $iVerb = $dirParsedVerbs.Item($i) 
           Write-Verbose "Checking Verb $($iVerb.Name)."
           if ($iVerb.Name -eq $vb) { 
                break
           }
           else {
                $null = [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($iVerb)
                Remove-Variable iVerb
           }
        }
        if (-not $iVerb) {
            Write-Error "$resPath does not have the associated verb, $Verb, inside the Explorer Context Menu."
            return
        }
        else {
            $iVerb.DoIt()
        }
    }
    catch {
        Write-Error -ErrorRecord $_
    }
    finally {
        if ($iVerb) {
            $null = [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($iVerb)
            Remove-Variable iVerb
        }
        if ($dirParsedVerbs) {
            $null = [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($dirParsedVerbs)
            Remove-Variable dirParsedVerbs
        }
        if ($dirParsed) {
            $null = [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($dirParsed)
            Remove-Variable dirParsed
        }
        if ($dir) {
            $null = [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($dir)
            Remove-Variable dir
        }
        if($shell){
            $null = [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($shell)
            Remove-Variable shell
        }
    }
    
}
