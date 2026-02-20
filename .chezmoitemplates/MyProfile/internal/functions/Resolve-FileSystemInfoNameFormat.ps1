function Resolve-FileSystemInfoNameFormat {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]
        $FileSystemInfo,
        [Parameter()]
        [System.Collections.Hashtable]
        $IconData = $script:formatFileSystemInfoIcon,
        [Parameter()]
        [System.Collections.Hashtable]
        $ColorData = $script:formatFileSystemInfoColor
    )

    begin {
        $fileSystemInfoType = 'System.IO.FileSystemInfo'
        $fileSystemInfoDeserType = "Deserialized.$fileSystemInfoType"
        $hasCorrectType = $false
        if ($FileSystemInfo -is $fileSystemInfoType) {
            $hasCorrectType = $true
        }
        if ($FileSystemInfo.pstypenames -contains $fileSystemInfoDeserType) {
            $hasCorrectType = $true
        }
        if (-not $hasCorrectType) {
            throw [System.NotSupportedException]'Only System.IO.FileSystemInfo and Deserialized variant is supported.'
        }
        $colorReset = "$([char]27)[0m"
    }

    process {
        $displayInfo = @{
            Icon     = $null
            Color    = $null
            Target   = ''
        }

        if ($FileSystemInfo.PSIsContainer) {
            $type = 'Directories'
        } else {
            $type = 'Files'
        }

        switch ($FileSystemInfo.LinkType) {
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
                $displayInfo['Target'] = ' ' + '󰁕' + ' ' + $FileSystemInfo.Target
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
                $displayInfo['Target'] = ' ' + '󰁕' + ' ' + $FileSystemInfo.Target
                break
            } default {
                if ($IconData) {
                    # Determine normal directory icon and color
                    $icon = $IconData.Types.$type.WellKnown[$FileSystemInfo.Name]
                    if (-not $icon) {
                        if ($FileSystemInfo.PSIsContainer) {
                            $icon = $IconData.Types.$type[$FileSystemInfo.Name]
                        } elseif ($IconData.Types.$type.ContainsKey($FileSystemInfo.Extension)) {
                            $icon = $IconData.Types.$type[$FileSystemInfo.Extension]
                        } else {
                            # File probably has multiple extensions
                            # Fallback to computing the full extension
                            $firstDot = $FileSystemInfo.Name.IndexOf('.')
                            if ($firstDot -ne -1) {
                                $fullExtension = $FileSystemInfo.Name.Substring($firstDot)
                                $icon = $IconData.Types.$type[$fullExtension]
                            }
                        }
                        if (-not $icon) {
                            $icon = $IconData.Types.$type['']
                        }

                        # Fallback if everything has gone horribly wrong
                        if (-not $icon) {
                            if ($FileSystemInfo.PSIsContainer) {
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
                    $colorSeq = $ColorData.Types.$type.WellKnown[$FileSystemInfo.Name]
                    if (-not $colorSeq) {
                        if ($FileSystemInfo.PSIsContainer) {
                            $colorSeq = $ColorData.Types.$type[$FileSystemInfo.Name]
                        } elseif ($ColorData.Types.$type.ContainsKey($FileSystemInfo.Extension)) {
                            $colorSeq = $ColorData.Types.$type[$FileSystemInfo.Extension]
                        } else {
                            # File probably has multiple extensions
                            # Fallback to computing the full extension
                            $firstDot = $FileSystemInfo.Name.IndexOf('.')
                            if ($firstDot -ne -1) {
                                $fullExtension = $FileSystemInfo.Name.Substring($firstDot)
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
