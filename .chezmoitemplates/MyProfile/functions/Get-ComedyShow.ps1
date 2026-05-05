function Get-ComedyShow {
    [CmdletBinding()]
    [Alias('gcmdy')]
    param (
        
    )
    
    begin {
        
    }
    
    process {
        Invoke-RestMethod laughlife.standuptix.com |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/head/script[@type="application/ld+json"]' |
            ForEach-Object innerhtml |
            ConvertFrom-Json |
            Where-Object '@type' -ma ComedyEvent |
            Where-Object name -notma 'stoned vs drunk|stoned vs stoned|roast battle league|comedy teabag|work the crowd' |
            Select-Object @{n='Name'; e={$_.name}},
                @{n='StartDate'; e={$_.startdate}},
                @{n='Location'; e={$_.location.name}}
        Invoke-RestMethod lafayettecomedy.com |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/head/script[@type="application/ld+json"]' |
            ForEach-Object innerhtml |
            ConvertFrom-Json |
            Where-Object '@type' -ma ComedyEvent |
            Where-Object name -notma 'stoned vs drunk|stoned vs stoned|roast battle league|glitz & giggles' |
            Select-Object @{n='Name'; e={$_.name}},
                @{n='StartDate'; e={$_.startdate}},
                @{n='Location'; e={$_.location.name}}
        Invoke-RestMethod https://app.opendate.io/v/sports-drink-1939 |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//a[@target="_parent"]' |
            Select-Object @{n='Name';e={ $_.innertext.trim()}},
                @{
                    Name = 'StartDate'
                    Expression = {
                        $selectedDate = [datetime]::Parse($_.ParentNode.NextSibling.NextSibling.InnerText.Trim())
                        $selectedShowTimeText = ($_.ParentNode.NextSibling.NextSibling.NextSibling.NextSibling.InnerText.Trim() -split '- Show: ')[1] 
                        $selectedTimeOfDay = [datetime]::Parse($selectedShowTimeText).TimeOfDay
                        $selectedDate.Add($selectedTimeOfDay)
                    }
                } |
            Where-Object Name -notmatch 'open gym|film_pod|moral panic|community night|spoonful of sugar|tropical trivia|new orleans spelling bee|Ted &amp|Karaoke Night' |
            Select-Object Name,StartDate,@{n='Location'; e={'Sports Drink'}}

    }
    
    end {
        
    }
}