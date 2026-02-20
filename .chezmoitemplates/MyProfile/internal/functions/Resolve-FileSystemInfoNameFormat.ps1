function Resolve-FileSystemInfoNameFormat {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.IO.FileSystemInfo]
        $FileInfo,
        [Parameter()]
        [System.Collections.Hashtable]
        $IconData = $script:formatFileSystemInfoIcon,
        [Parameter()]
        [System.Collections.Hashtable]
        $ColorData = $script:formatFileSystemInfoColor
    )

    begin {
        $colorReset = "$([char]27)[0m"
    }

    process {
        $displayInfo = @{
            Icon     = $null
            Color    = $null
            Target   = ''
        }

        if ($FileInfo.PSIsContainer) {
            $type = 'Directories'
        } else {
            $type = 'Files'
        }

        switch ($FileInfo.LinkType) {
            # Determine symlink or junction icon and color
            'Junction' {
                if ($IconData) {
                    $icon = $IconData.Types.($type)['junction']
                } else {
                    $icon = $null
                }
                if ($ColorData) {
                    $colorSeq = $ColorData.Types.($type)['junction']
                } else {
                    $colorSeq = $colorReset
                }
                $displayInfo['Target'] = ' ' + '󰁕' + ' ' + $FileInfo.Target
                break
            }
            'SymbolicLink' {
                if ($IconData) {
                    $icon = $IconData.Types.($type)['symlink']
                } else {
                    $icon = $null
                }
                if ($ColorData) {
                    $colorSeq = $ColorData.Types.($type)['symlink']
                } else {
                    $colorSeq = $colorReset
                }
                $displayInfo['Target'] = ' ' + '󰁕' + ' ' + $FileInfo.Target
                break
            } default {
                if ($IconData) {
                    # Determine normal directory icon and color
                    $icon = $IconData.Types.$type.WellKnown[$FileInfo.Name]
                    if (-not $icon) {
                        if ($FileInfo.PSIsContainer) {
                            $icon = $IconData.Types.$type[$FileInfo.Name]
                        } elseif ($IconData.Types.$type.ContainsKey($FileInfo.Extension)) {
                            $icon = $IconData.Types.$type[$FileInfo.Extension]
                        } else {
                            # File probably has multiple extensions
                            # Fallback to computing the full extension
                            $firstDot = $FileInfo.Name.IndexOf('.')
                            if ($firstDot -ne -1) {
                                $fullExtension = $FileInfo.Name.Substring($firstDot)
                                $icon = $IconData.Types.$type[$fullExtension]
                            }
                        }
                        if (-not $icon) {
                            $icon = $IconData.Types.$type['']
                        }

                        # Fallback if everything has gone horribly wrong
                        if (-not $icon) {
                            if ($FileInfo.PSIsContainer) {
                                $icon = ''
                            } else {
                                $icon = ''
                            }
                        }
                    }
                } else {
                    $icon = $null
                }
                if ($ColorData) {
                    $colorSeq = $ColorData.Types.$type.WellKnown[$FileInfo.Name]
                    if (-not $colorSeq) {
                        if ($FileInfo.PSIsContainer) {
                            $colorSeq = $ColorData.Types.$type[$FileInfo.Name]
                        } elseif ($ColorData.Types.$type.ContainsKey($FileInfo.Extension)) {
                            $colorSeq = $ColorData.Types.$type[$FileInfo.Extension]
                        } else {
                            # File probably has multiple extensions
                            # Fallback to computing the full extension
                            $firstDot = $FileInfo.Name.IndexOf('.')
                            if ($firstDot -ne -1) {
                                $fullExtension = $FileInfo.Name.Substring($firstDot)
                                $colorSeq = $ColorData.Types.$type[$fullExtension]
                            }
                        }
                        if (-not $colorSeq) {
                            $colorSeq = $ColorData.Types.$type['']
                        }

                        # Fallback if everything has gone horribly wrong
                        if (-not $colorSeq) {
                            $colorSeq = $colorReset
                        }
                    }
                } else {
                    $colorSeq = $colorReset
                }
            }
        }
        if ($icon) {
            $displayInfo['Icon'] = $icon
        }
        else {
            $displayInfo['Icon'] = $null
        }
        $displayInfo['Color'] = $colorSeq
        $displayInfo
    }
}
