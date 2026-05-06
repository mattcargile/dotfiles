function Get-ComedyShow {
    [CmdletBinding()]
    [Alias('gcmdy')]
    param (
    )

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
        Invoke-RestMethod us.atgtickets.com/venues/saenger-theatre/whats-on/ |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//div[@class="MuiCardContent-root mui-15seape"]' |
            Where-Object { $_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-sq0p4m"]/text()').text -eq 'Comedy'} |
            Select-Object @{n='Name'; e={[HtmlAgilityPack.HtmlEntity]::DeEntitize($_.selectnodes('.//h2[@class="MuiBox-root mui-10n19ke"]/text()').text)}},
                @{n='StartDate'; e={[datetime]::Parse($_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-b806a2"]/text()').text)}},
                @{n='Location'; e={$_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-lnhdee"]/text()').text}}
        Invoke-RestMethod us.atgtickets.com/venues/mahalia-jackson-theater/whats-on/ |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//div[@class="MuiCardContent-root mui-15seape"]' |
            Where-Object { $_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-sq0p4m"]/text()').text -eq 'Comedy'} |
            Select-Object @{n='Name'; e={[HtmlAgilityPack.HtmlEntity]::DeEntitize($_.selectnodes('.//h2[@class="MuiBox-root mui-10n19ke"]/text()').text)}},
                @{n='StartDate'; e={[datetime]::Parse($_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-b806a2"]/text()').text)}},
                @{n='Location'; e={$_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-lnhdee"]/text()').text}}
        Invoke-RestMethod https://thejoytheater.com/shows/ |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//div[@class="seven columns"]' |
            Select-Object @{n='Name'; e={[HtmlAgilityPack.HtmlEntity]::DeEntitize($_.selectnodes('.//a/text()').text)}},
                @{
                    Name = 'EventHtmlObject'
                    Expression = { Invoke-RestMethod $_.selectnodes('.//a').getattributeValue('href', '<EMPTY>') | PSParseHTML\ConvertFrom-HTML }
                } |
            Where-Object { $_.EventHtmlObject.SelectNodes('/html/body//p[@class="tw-description-info"]/text()').Text -match 'comedy|comic|comedian|comedienne' } |
            Select-Object Name, 
                @{
                    Name = 'StartDate'
                    Expression = {
                        $currentEvtDate = [datetime]::Parse($_.EventHtmlObject.SelectNodes('/html/body//span[@class="tw-event-date"]/text()').text)
                        $currentEvtTimeString = $_.EventHtmlObject.SelectNodes('/html/body//span[@class="tw-event-time"]/text()').text
                        if ($currentEvtTimeString -match '[0-9]{1,2}:[0-9]{2}\s?([pP]|[aA])[mM]') {
                            $currentEvtStartTimeOfDay = [datetime]::Parse($Matches[0]).TimeOfDay
                        }
                        $currentEvtDate.Add($currentEvtStartTimeOfDay)
                    }
                },
                @{n='Location'; e={'The Joy Theater'}}
    }
}
