function Search-Giphy {
    <#
.SYNOPSIS
    Fetches Gif Information and direct Gif Links from Giphy, a meme delivery service
.DESCRIPTION
    This is a frontend to the Giphy API to find and request gifs from Giphy. It implements the API described here: https://developers.giphy.com/docs/api/
.EXAMPLE
    PS> Search-Giphy
    Returns a random gif information object
    title          bitly_url              username source
    -----          ---------              -------- ------
    nick jonas GIF https://gph.is/1SR6uiv          https://ddlovatosrps.tumblr.com/post/120447116655/positive-nick-jonas-gif-hunt-under-the-cut-you
.EXAMPLE
    PS> Search-Giphy -ImageType Sticker
    Returns a random sticker information object
    title                                                             bitly_url              username source
    -----                                                             ---------              -------- ------
    festival woodstock Sticker by Wielka Orkiestra Świątecznej Pomocy https://gph.is/2mZ7V2k WOSP
.EXAMPLE
    PS> Search-Giphy -DirectURL
    Returns only the direct link to a random gif
    https://media3.giphy.com/media/q9WSYOP1KUlgc/giphy.gif?cid=f499c4a35d19a6596653673632f7ddec&rid=giphy.gif
.EXAMPLE
    PS> Search-Giphy -Filter "Excited"
    Returns GIFs that match 'Excited'
.EXAMPLE
    PS> Search-Giphy -Filter Excited -Channel reactions -tag cat -first 3
    Returns 3 GIFs that match 'Excited' in the reactions channel with tag of Cat
.EXAMPLE
    PS> Search-Giphy -Trending -First 3
    Get the top 3 trending gifs
.EXAMPLE
    PS> Search-Giphy -Translate -Phrase "cute flying bat" -Weirdness 5
    Translates the phrase "cute flying bat" to a Gif with a weirdness factor of 5 using Giphy's special sauce
.EXAMPLE
    PS> Search-Giphy -Translate -Phrase "cute flying bat" -Weirdness 5 -DirectUrl
    Translate the phrase "cute flying bat" to a gif with a Weirdness rating of 5.
.NOTES
    Created 2019 by Justin Grote
    The giphy public beta API key is embedded in this script and is subject to very frequent rate limiting. You can sign up for your own free Giphy API key,
    just be aware no special means in this script are used to "protect" the key.

    QUICKSTART:
    * Run this in your Powershell Windows Terminal: Install-Module msterminalsettings -scope currentuser -allowprerelease
    * Get-Help Search-Giphy -Examples
    * Get-Help Invoke-TerminalGif -Examples
    * Search-Giphy | Format-List -prop *
    * Invoke-TerminalGif https://media.giphy.com/media/g9582DNuQppxC/giphy.gif
#>
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = 'random')]
    [Alias('srgif')]
    param (
        #If performing a search, this is a query string of a word or phrase to find. If using -Translate, this is the phrase you want to convert to a gif
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'search')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'translate')]
        [Alias('f', 'q')]
        [String]$Filter,

        #If performing a search, limit to a verified channel. This is the same as specifying "@channelname" in the Filter parameter
        [Parameter(Position = 2, ParameterSetName = 'search')]
        [Alias('c')]
        [String]$Channel,

        #Specify a weirdness factor from 0 to 10. The translations will get weirder the higher number you specify
        [Parameter(ParameterSetName = 'translate')]
        [ValidateRange(0, 10)]
        [Alias('w')]
        [int]$Weirdness,

        [Parameter(Position = 1, ParameterSetName = 'search')]
        [Parameter( ParameterSetName = 'random')]
        [Alias('tg')]
        [String]$Tag,

        #Search Trending Gifs
        [Parameter( Mandatory, ParameterSetName = 'trending')]
        [Alias('tr')]
        [Switch]$Trending,

        #Perform a gif translate, which will use the giphy "secret sauce" to make your phrase into a gif
        [Parameter( Mandatory, ParameterSetName = 'translate')]
        [Alias('tl')]
        [Switch]$Translate,

        #Specifying this switch will only return the original URI of a gif or gifs, which is easier to integrate into tools
        [Alias('du')]
        [Switch]$DirectURL,

        #Type of image (Gif or Sticker). Defaults to Gif.
        [ValidateSet('Gif', 'Sticker')]
        [Alias('it')]
        [string]$ImageType = 'Gif',

        #Content rating of the gif. Specify G, PG, PG-13, or R. Searches PG gifs by default.
        [ValidateSet('G', 'PG', 'PG-13', 'R')]
        [Alias('ra')]
        [string]$Rating = 'PG',

        #API Key. Previously defaulted to the Giphy Public Beta Key ( e.g. dc6zaTOxFJmzC ) which is banned.
        #It is necessary to register your own apikey at Giphy Developers: https://developers.giphy.com/dashboard/
        #Recommendation so you don't have to specify it each time: $PSDefaultParameterValues['Search-Giphy:ApiKey'] = { (Import-CliXml 'path\to\cred.xml').Password }
        [Parameter(Mandatory)]
        [Alias('a', 'k', 'key', 'api')]
        [securestring]$APIKey
    )

    function Join-Uri ([string]$uri, [string]$relativePath) {
        [uri]::new([uri]"$uri/", $relativePath)
    }

    $ErrorActionPreference = 'Stop'
    $baseuri = "https://api.giphy.com/v1"
    $requestUri = Join-Uri -uri $baseuri -relativepath "${ImageType}s".toLower()
    $requestUri = Join-Uri $requestUri $PSCmdlet.ParameterSetName.toLower()

    $irmParams = @{
        UseBasicParsing = $true
        Method          = 'Get'
        Uri             = $requestUri
        Body            = [ordered]@{
            api_key = [pscredential]::new( 'Dummy', $APIKey ).GetNetworkCredential().Password
            rating  = $Rating
        }
    }

    $queryParams = $irmparams.Body

    switch ($PSCmdlet.ParameterSetName) {
        'search' {
            $queryParams.q = $Filter
            if ($tag) { [string]$queryParams.q = "#$tag " + $queryParams.q }
            if ($channel) { [string]$queryParams.q = "@$channel " + $queryParams.q }
        }
        'translate' {
            $queryParams.s = $Filter
            if ($Weirdness) { $queryParams.weirdness = $Weirdness }
        }
        'random' {
            if ($tag) { $queryParams.tag = $Tag }
        }
    }

    if ($PSCmdlet.PagingParameters.First -and $PSCmdlet.PagingParameters.First -ne 18446744073709551615) { $queryParams.limit = $PSCmdlet.PagingParameters.First }
    if ($PSCmdlet.PagingParameters.Skip) { $queryParams.body.offset = $PSCmdlet.PagingParameters.Skip }

    $GiphyResult = Invoke-RestMethod @irmParams -ErrorAction Stop
    $GiphyResultData = $GiphyResult.data

    if (-not $DirectUrl) {
        if (-not (Get-TypeData giphy.image)) { Update-TypeData -TypeName Giphy.Image -DefaultDisplayPropertySet title, bitly_url, username, source }
        $GiphyResultData | ForEach-Object {
            $PSItem.PSObject.TypeNames.Insert(0, 'Giphy.Image')
            $PSItem
        }
    }
    else {
        $GiphyResultData.images.original.url
    }
}
