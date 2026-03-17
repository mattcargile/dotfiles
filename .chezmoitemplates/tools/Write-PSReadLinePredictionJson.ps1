[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# May run in context where module won't auto load
if (-not ( Get-Module -Name PSReadLine )) {
    Import-Module -Name PSReadLine
}
$corePsrlVersion = ( Get-Module -Name PSReadLine ).Version

$corePredictionSrc = $null
if ($corePsrlVersion -ge [version]'2.0.4') {
    if ($PSVersionTable.PSVersion -ge [version]'7.2') {
        $corePredictionSrc = 'HistoryAndPlugin'
    }
    else {
        $corePredictionSrc = 'History'
    }
}

$coreHasColorsInlinePrediction = $false 
if ($corePsrlVersion -ge [version]'2.1.0') {
    $coreHasColorsInlinePrediction = $true
}

$coreHasColorsListPrediction = $false 
if ($corePsrlVersion -ge [version]'2.2.2') {
    $coreHasColorsListPrediction = $true
}

$outPsObj = [PSCustomObject]@{
    CorePredictionSource = $corePredictionSrc
    CoreHasColorsInlinePrediction = $coreHasColorsInlinePrediction
    CoreHasColorsListPrediction = $coreHasColorsListPrediction
}

if ($IsWindows) {
    # Need to force `Import-Module` otherwise the shell won't load it.
    $desktopPsrlVersion = (powershell -NoLogo -NoProfile -Command { Import-Module -ErrorAction Stop -Name PSReadLine; Get-Module -Name PSReadLine -ErrorAction Stop }).Version
    if ($LASTEXITCODE -gt 0 -or $null -eq $desktopPsrlVersion -or $desktopPsrlVersion -eq '') {
        throw [InvalidOperationException]'Failed to import and/or get the Windows Powershell PSReadLine version.'
    }

    $desktopPredictionSrc = $null
    if ($desktopPsrlVersion -ge [version]'2.0.4') {
        $desktopPredictionSrc = 'History'
    }

    $desktopHasColorsInlinePrediction = $false 
    if ($desktopPsrlVersion -ge [version]'2.1.0') {
        $desktopHasColorsInlinePrediction = $true
    }

    $desktopHasColorsListPrediction = $false 
    if ($desktopPsrlVersion -ge [version]'2.2.2') {
        $desktopHasColorsListPrediction = $true
    }

    $outPsObj | Add-Member DesktopPredictionSource $desktopPredictionSrc
    $outPSObj | Add-Member DesktopHasColorsInlinePrediction $desktopHasColorsInlinePrediction
    $outPSObj | Add-Member DesktopHasColorsListPrediction $desktopHasColorsListPrediction
}

$outPsObj | ConvertTo-Json -Compress