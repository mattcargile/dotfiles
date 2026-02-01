function Add-TfsItem {
    [Alias('atfi')]
    [CmdletBinding()]
    param (
        
    )
    
    end {
        if (-not ((Get-Command -Name 'tf*' ).Definition -like '*tf.exe' )) {
            $writeErrorSplat = @{
                Category = 'ResourceUnavailable'
                Message = 'Can''t find tf.exe. Add to $env:Path or create an Alias. Sample path for VS 2019 is ''C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\''.'
            }
            Write-Error @writeErrorSplat
            return
        }
        $sts = tf status . /recursive
        $addLn = $sts | Select-String 'Detected Changes:' | Select-Object -ExpandProperty LineNumber
        tf add /noprompt (
            $sts[$addLn..($sts.Length - 1)] |
                Select-String 'add([ ]+)(.*)' | 
                Select-Object -ExpandProperty Matches | 
                Select-Object -ExpandProperty Groups | 
                Where-Object Name -eq '2' | 
                Select-Object -ExpandProperty Value)
    }
}
