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
            Select-Object @{n='Name'; e={$_.name}},
                @{n='StartDate'; e={$_.startdate}},
                @{n='Location'; e={$_.location.name}}
        Invoke-RestMethod lafayettecomedy.com |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/head/script[@type="application/ld+json"]' |
            ForEach-Object innerhtml |
            ConvertFrom-Json |
            Where-Object '@type' -ma ComedyEvent |
            Select-Object @{n='Name'; e={$_.name}},
                @{n='StartDate'; e={$_.startdate}},
                @{n='Location'; e={$_.location.name}}
        Invoke-RestMethod https://app.opendate.io/v/sports-drink-1939 |
            PSParseHTML\ConvertFrom-HTML |
            ForEach-Object SelectNodes '/html/body//a[@target="_parent"]' |
            Select-Object @{n='Name';e={ $_.innertext.trim()}},@{n='StartDate';e={[datetime]::Parse($_.ParentNode.NextSibling.NextSibling.InnerText.trim())}} |
            Where-Object { $_.name -notmatch 'open gym|film_pod|moral panic|community night|spoonful of sugar|tropical trivia|new orleans spelling bee|Ted &amp'} |
            Select-Object Name,StartDate,@{n='Location'; e={'Sports Drink'}}

    }
    
    end {
        
    }
}