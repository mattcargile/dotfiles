function Get-ComedyShow {
    [CmdletBinding()]
    [Alias('gcmdy')]
    param (
    )

    process {
        $nameReplace = '(\s?\(.*\)\s?.*)|(\s[aA]t\s.*$)|(\sLive\s[iI]n\s.*$)|(:.*$)|(\s?-\s?.*)|(\sLive[!\s]?.*$)'
        Invoke-RestMethod laughlife.standuptix.com |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/head/script[@type="application/ld+json"]' |
            ForEach-Object innerhtml |
            ConvertFrom-Json |
            Where-Object '@type' -ma ComedyEvent |
            Where-Object name -notma 'stoned vs drunk|stoned vs stoned|roast battle league|comedy teabag|work the crowd|anger management: comedy meets|certified killers comedy showcase' |
            Select-Object @{n='Name'; e={$_.name -replace $nameReplace}},
                @{n='StartDate'; e={$_.startdate}},
                @{n='Location'; e={$_.location.name}}
        Invoke-RestMethod lafayettecomedy.com |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/head/script[@type="application/ld+json"]' |
            ForEach-Object innerhtml |
            ConvertFrom-Json |
            Where-Object '@type' -ma ComedyEvent |
            Where-Object name -notma 'stoned vs drunk|stoned vs stoned|roast battle league|glitz & giggles|bun intended \- a standup comedy show|hair of the dog comedy night' |
            Select-Object @{n='Name'; e={$_.name -replace $nameReplace}},
                @{n='StartDate'; e={$_.startdate}},
                @{n='Location'; e={$_.location.name}}
        Invoke-RestMethod https://app.opendate.io/v/sports-drink-1939 |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//a[@target="_parent"]' |
            Select-Object @{n='Name';e={ [HtmlAgilityPack.HtmlEntity]::DeEntitize($_.innertext.trim()) -replace $nameReplace}},
                @{
                    Name = 'StartDate'
                    Expression = {
                        $selectedDate = [datetime]::Parse($_.ParentNode.NextSibling.NextSibling.InnerText.Trim())
                        $selectedShowTimeText = ($_.ParentNode.NextSibling.NextSibling.NextSibling.NextSibling.InnerText.Trim() -split '- Show: ')[1] 
                        $selectedTimeOfDay = [datetime]::Parse($selectedShowTimeText).TimeOfDay
                        $selectedDate.Add($selectedTimeOfDay)
                    }
                } |
            Where-Object Name -notmatch 'open gym|film_pod|moral panic|community night|spoonful of sugar|tropical trivia|new orleans spelling bee|Ted & Kev|Karaoke Night|no br lft' |
            Select-Object Name,StartDate,@{n='Location'; e={'Sports Drink'}}
        Invoke-RestMethod us.atgtickets.com/venues/saenger-theatre/whats-on/ |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//div[@class="MuiCardContent-root mui-15seape"]' |
            Where-Object { $_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-sq0p4m"]/text()').text -eq 'Comedy'} |
            Select-Object @{n='Name'; e={[HtmlAgilityPack.HtmlEntity]::DeEntitize($_.selectnodes('.//h2[@class="MuiBox-root mui-10n19ke"]/text()').text) -replace $nameReplace}},
                @{
                    Name = 'StartDate'
                    Expression = {
                        $currentEventDateTimeHtmlObj = Invoke-RestMethod "https://us.atgtickets.com/$($_.SelectNodes( './/a[@data-type="composed" and @type="button"]' ).getattributevalue('href', '<EMPTY>'))" |
                            PSParseHTML\ConvertFrom-HTML |
                            ForEach-Object -MemberName SelectNodes -ArgumentList '/html/body/main//div[@class="MuiBox-root mui-1kknxc2"]'
                        $currentEventDateAndTime = $currentEventDateTimeHtmlObj.SelectNodes( './p[@class="MuiTypography-root MuiTypography-bodySmall mui-1lkazsm"]/text()').Text
                        $currentEventDate = [datetime]::Parse($currentEventDateAndTime[0])
                        if ($currentEventDateAndTime[1] -match '[0-9]{1,2}:[0-9]{2} [aApP][mM]') {
                            $currentEventTimeOfDay = [datetime]::Parse($Matches[0]).TimeOfDay
                        }
                        $currentEventDate.Add($currentEventTimeOfDay)
                    }
                },
                @{n='Location'; e={$_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-lnhdee"]/text()').text}}
        Invoke-RestMethod us.atgtickets.com/venues/mahalia-jackson-theater/whats-on/ |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//div[@class="MuiCardContent-root mui-15seape"]' |
            Where-Object { $_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-sq0p4m"]/text()').text -eq 'Comedy'} |
            Select-Object @{n='Name'; e={[HtmlAgilityPack.HtmlEntity]::DeEntitize($_.selectnodes('.//h2[@class="MuiBox-root mui-10n19ke"]/text()').text) -replace $nameReplace}},
                @{
                    Name = 'StartDate'
                    Expression = {
                        $currentEventDateTimeHtmlObj = Invoke-RestMethod "https://us.atgtickets.com/$($_.SelectNodes( './/a[@data-type="composed" and @type="button"]' ).getattributevalue('href', '<EMPTY>'))" |
                            PSParseHTML\ConvertFrom-HTML |
                            ForEach-Object -MemberName SelectNodes -ArgumentList '/html/body/main//div[@class="MuiBox-root mui-1kknxc2"]'
                        $currentEventDateAndTime = $currentEventDateTimeHtmlObj.SelectNodes( './p[@class="MuiTypography-root MuiTypography-bodySmall mui-1lkazsm"]/text()').Text
                        $currentEventDate = [datetime]::Parse($currentEventDateAndTime[0])
                        if ($currentEventDateAndTime[1] -match '[0-9]{1,2}:[0-9]{2} [aApP][mM]') {
                            $currentEventTimeOfDay = [datetime]::Parse($Matches[0]).TimeOfDay
                        }
                        $currentEventDate.Add($currentEventTimeOfDay)
                    }
                },
                @{n='Location'; e={$_.selectnodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-lnhdee"]/text()').text}}
        Invoke-RestMethod https://thejoytheater.com/shows/ |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//div[@class="seven columns"]' |
            Select-Object @{n='Name'; e={[HtmlAgilityPack.HtmlEntity]::DeEntitize($_.selectnodes('.//a/text()').text) -replace $nameReplace}},
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
        $civicCurrentEventUri = 'https://civicnola.com/tm-venue/'
        try {
            # For some reason the intial attempt to access the site throws an access denied and a robots page.
            # Tried various headers with user agents, etc which don't matter
            $civicHtml = Invoke-RestMethod $civicCurrentEventUri
        }
        catch {
            $civicHtml = Invoke-RestMethod $civicCurrentEventUri
        }
        $civicComedyArchiveNameList = Invoke-RestMethod 'https://civicnola.com/tm_genre/comedy' |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//div[@class="tw-name event-title"]/text()' |
            ForEach-Object Text |
            ForEach-Object Trim
        # Google /recaptcha/enterprise/anchor for TicketMaster prevents access to the ComedyEvent `eventSchema` object in the `html
        $civicHtml |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//div[@class="seven columns"]' |
            Select-Object @{n='Name'; e={[HtmlAgilityPack.HtmlEntity]::DeEntitize($_.selectnodes('.//a/text()').text) -replace $nameReplace}},
                @{
                    Name = 'StartDate'
                    Expression = {
                        $currentEvtDate = [datetime]::Parse($_.SelectNodes('.//span[@class="tw-event-date"]/text()').text)
                        $currentEvtTimeOfDay = [datetime]::Parse($_.SelectNodes('.//span[@class="tw-event-time"]/text()').text).TimeOfDay
                        $currentEvtDate.Add($currentEvtTimeOfDay)
                    }
                },
                @{n='Location'; e={'Civic Theatre'}} |
            Where-Object Name -in $civicComedyArchiveNameList
        Invoke-RestMethod https://orpheumnola.com/em-ajax/get_listings/ -Method Post -Body @{ 'search_categories[]' = 'live-comedy'; per_page = 15; orderby = 'event_start_date'; order = 'ASC'; page = 1} |
            ForEach-Object -MemberName html |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/div//div[@class="wpem-event-details"]' |
            Select-Object @{n='Name'; e={$_.selectnodes('.//h3[@class="wpem-heading-text"]/text()').Text -replace $nameReplace}},
                @{
                    Name = 'StartDate'
                    Expression = {
                        $currentEvtDateAndTimeString = $_.SelectNodes('.//span[@class="wpem-event-date-time-text"]/text()').Text.Trim() -replace '\s{2,}', ' '
                        [datetime]::ParseExact( $currentEvtDateAndTimeString, 'dddd, MMMM d, yyyy @ hh:mm tt', $null)
                    }
                },
                @{n='Location'; e={'Orpheum Theater'}}
    }
}
