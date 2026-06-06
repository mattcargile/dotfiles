function Get-ComedyShow {
    [CmdletBinding()]
    [Alias('gcmdy')]
    param (
    )
    begin {
        filter Select-OpenDate {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [object]
                $HtmlNode
            )
            $selectSplat = @{
                Property = @(
                    @{
                        Name = 'NameInnerText'
                        Expression = { $_ | Select-HtmlInnerText -DeEntitize }
                    }
                    @{
                        Name = 'StartDate'
                        Expression = {
                            $selectedDate = [datetime]::Parse($_.ParentNode.NextSibling.NextSibling.InnerText.Trim())
                            $selectedShowTimeText = ($_.ParentNode.NextSibling.NextSibling.NextSibling.NextSibling.InnerText.Trim() -split '- Show: ')[1] 
                            $selectedTimeOfDay = [datetime]::Parse($selectedShowTimeText).TimeOfDay
                            $selectedDate.Add($selectedTimeOfDay)
                        }
                    }
                )
            }
            $HtmlNode | Select-HtmlNode -Tag a -AttributeName target -AttributeValue _parent | Select-Object @selectSplat
        }
        filter Select-SportsDrink {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [object]
                $OpenDateObject,
                [Parameter(Mandatory)]
                [string]
                $NameReplaceRegex
            )
            $regexNotMatch = 'open gym|film_pod|moral panic|community night|spoonful of sugar|tropical trivia|new orleans spelling bee|Ted & Kev|Karaoke Night|no br lft|thank you for your purchase|bing-oh'
            $selectSplat  = @{
                Property = @(
                    @{
                        Name = 'Name'
                        Expression = { $_.NameInnerText -replace $NameReplaceRegex }

                    }
                    'StartDate'
                    @{
                        Name = 'Location'
                        Expression = {'Sports Drink'}
                    }
                )
            }
            $OpenDateObject | Where-Object NameInnerText -notmatch $regexNotMatch | Select-Object @selectSplat 
        }
    }

    process {
        $nameReplace = '(\s?\(.*\)\s?.*)|(\s[aA]t\s.*$)|(\sLive\s[iI]n\s.*$)|(:.*$)|(\s?-\s?.*)|(\sLive[!\s]?.*$)'

        Invoke-RestMethod laughlife.standuptix.com |
            PSParseHTML\ConvertFrom-HTML |
            Select-HtmlNode -Tag script -AttributeName type -AttributeValue 'application/ld+json' |
            Select-HtmlInnerText -NoTrim |
            ConvertFrom-Json |
            Where-Object '@type' -ma ComedyEvent |
            Where-Object name -notma 'stoned vs\.? drunk|stoned vs\.? stoned|roast battle league|comedy teabag|work the crowd|anger management: comedy meets|certified killers comedy showcase|gun control: comedy show' |
            Select-Object @{n='Name'; e={$_.name -replace $nameReplace}},
                @{n='StartDate'; e={$_.startdate}},
                @{n='Location'; e={$_.location.name}}

        Invoke-RestMethod lafayettecomedy.com |
            PSParseHTML\ConvertFrom-HTML |
            Select-HtmlNode -Tag script -AttributeName type -AttributeValue 'application/ld+json' |
            Select-HtmlInnerText -NoTrim |
            ConvertFrom-Json |
            Where-Object '@type' -ma ComedyEvent |
            Where-Object name -notma 'stoned vs\.? drunk|stoned vs\.? stoned|roast battle league|glitz & giggles|bun intended \- a standup comedy show|hair of the dog comedy night' |
            Select-Object @{n='Name'; e={$_.name -replace $nameReplace}},
                @{n='StartDate'; e={$_.startdate}},
                @{n='Location'; e={$_.location.name}}

        $sportsDrinkBaseUri = 'https://app.opendate.io/v/sports-drink-1939'
        $sportsDrinkPageQueryParamFormat = 'page={0}'
        $sportsDrinkFirstPage = Invoke-RestMethod $sportsDrinkBaseUri |
            PSParseHTML\ConvertFrom-HTML
        $sportsDrinkLastPageNumber = $sportsDrinkFirstPage | Select-HtmlNode -Tag a -AttributeName 'class' -AttributeValue 'page-link' |
            Select-HtmlInnerText -DeEntitize |
            Select-Object -Last 2 |
            Select-Object -First 1
        $sportsDrinkFirstPage | Select-OpenDate | Select-SportsDrink -NameReplaceRegex $nameReplace
        foreach ($currentSportsDrinkPage in 2..$sportsDrinkLastPageNumber) {
            $currentSportsDrinkUri = "${sportsDrinkBaseUri}?$($sportsDrinkPageQueryParamFormat -f $currentSportsDrinkPage)"
            Invoke-RestMethod $currentSportsDrinkUri | PSParseHTML\ConvertFrom-HTML | Select-OpenDate | Select-SportsDrink -NameReplaceRegex $nameReplace
        }

        Invoke-RestMethod us.atgtickets.com/venues/saenger-theatre/whats-on/ |
            PSParseHTML\ConvertFrom-HTML |
            Select-HtmlNode -Tag div -AttributeName 'class' -AttributeValue 'MuiCardContent-root mui-15seape' |
            Where-Object { $_.SelectNodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-sq0p4m"]/text()').text -eq 'Comedy'} |
            Select-Object @{n='Name'; e={[Net.WebUtility]::HtmlDecode($_.SelectNodes('.//h2[@class="MuiBox-root mui-10n19ke"]/text()').text) -replace $nameReplace}},
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
                @{n='Location'; e={$_.SelectNodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-lnhdee"]/text()').text}}

        Invoke-RestMethod us.atgtickets.com/venues/mahalia-jackson-theater/whats-on/ |
            PSParseHTML\ConvertFrom-HTML |
            Select-HtmlNode -Tag div -AttributeName 'class' -AttributeValue 'MuiCardContent-root mui-15seape' |
            Where-Object { $_.SelectNodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-sq0p4m"]/text()').text -eq 'Comedy'} |
            Select-Object @{n='Name'; e={[Net.WebUtility]::HtmlDecode($_.SelectNodes('.//h2[@class="MuiBox-root mui-10n19ke"]/text()').text) -replace $nameReplace}},
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
                @{n='Location'; e={$_.SelectNodes('.//p[@class="MuiTypography-root MuiTypography-bodySmall mui-lnhdee"]/text()').text}}
        Invoke-RestMethod https://thejoytheater.com/shows/ |
            PSParseHTML\ConvertFrom-HTML |
            Select-HtmlNode -Tag div -AttributeName 'class' -AttributeValue 'seven columns' |
            Select-Object @{n='Name'; e={[Net.WebUtility]::HtmlDecode($_.SelectNodes('.//a/text()').text) -replace $nameReplace}},
                @{
                    Name = 'EventHtmlObject'
                    Expression = { Invoke-RestMethod $_.SelectNodes('.//a').getattributeValue('href', '<EMPTY>') | PSParseHTML\ConvertFrom-HTML }
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

        # civicnola.com has some of fingerprinting related to TLS state. Upping to HTTP/2 "fixes" the initial error.
        # curl doesn't appear to have this issue on http versions. User agent doesn't immediately fix the issue either. 
        # Using `$env:DOTNET_SYSTEM_NET_SECURITY_DISABLETLSRESUME` creates a scenario where connection never succeeds
        $civicComedyArchiveNameList = Invoke-RestMethod 'https://civicnola.com/tm_genre/comedy' -HttpVersion 2.0 |
            PSParseHTML\ConvertFrom-HTML |
            Select-HtmlNode -Tag div -AttributeName 'class' -AttributeValue 'tw-name event-title' |
            Select-HtmlInnerText -DeEntitize
        Invoke-RestMethod 'https://civicnola.com/tm-venue/' -HttpVersion 2.0 |
            PSParseHTML\ConvertFrom-HTML |
            Select-HtmlNode -Tag div -AttributeName 'class' -AttributeValue 'seven columns' |
            Select-Object @{n='Name'; e={[Net.WebUtility]::HtmlDecode($_.SelectNodes('.//a/text()').text) -replace $nameReplace}},
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
            Select-HtmlNode -Tag div -AttributeName 'class' -AttributeValue 'wpem-event-details' |
            Select-Object @{n='Name'; e={$_.SelectNodes('.//h3[@class="wpem-heading-text"]/text()').Text -replace $nameReplace}},
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
