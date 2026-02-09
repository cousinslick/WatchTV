function Get-GrayStreamUrl
{
  param (
    [string] $Domain,
    [string] $CallSign
  )

  Get-GrayStreamInfo -Domain $Domain -CallSign $CallSign -LiveStream
}

function Get-GrayStreamInfo
{
  [CmdletBinding(DefaultParameterSetName = "GetAvailable")]
  param (
    [Parameter(ParameterSetName = "GetAvailable", Mandatory = $true)]
    [Parameter(ParameterSetName = "LiveStream", Mandatory = $true)]
    [Parameter(ParameterSetName = "StreamTitle", Mandatory = $true)]
    [Parameter(ParameterSetName = "StreamId", Mandatory = $true)]
    [string] $Domain,

    [Parameter(ParameterSetName = "GetAvailable", Mandatory = $true)]
    [Parameter(ParameterSetName = "LiveStream", Mandatory = $true)]
    [Parameter(ParameterSetName = "StreamTitle", Mandatory = $true)]
    [Parameter(ParameterSetName = "StreamId", Mandatory = $true)]
    [string] $CallSign,

    [Parameter(ParameterSetName = "LiveStream", Mandatory = $true)]
    [switch] $LiveStream,

    [Parameter(ParameterSetName = "StreamTitle", Mandatory = $true)]
    [string] $StreamTitle,

    [Parameter(ParameterSetName = "StreamId", Mandatory = $true)]
    [string] $StreamId,

    [int] $Count = 12,

    [string] $TimeZone = "Local"
  )

  function GetTokenInfo
  {
    param (
      [string] $DeviceId,
      [string] $Query
    )

    $getTokenEndpoint = "https://$($Domain.ToLowerInvariant())/pf/api/v3/content/fetch/syncbak-get-tokens"
    $queryString = "query=$([uri]::EscapeDataString($Query))&_website=$($CallSign.ToLowerInvariant())"
    $getTokenUrl = "$($getTokenEndpoint)?$($queryString)"

    Invoke-RestMethod -Method Get -Uri $getTokenUrl -UserAgent (Get-UA)
  }

  function DoGraphQuery
  {
    param (
      $TokenInfo
    )

    $graphqlEndpoint = "https://graphql-api.aws.syncbak.com/graphql"
    $headers = @{
      Origin = "https://$($Domain.ToLowerInvariant())"
      Referer = "https://$($Domain.ToLowerInvariant())/"
      'api-token' = $TokenInfo.apiToken
      'api-device-data' = $TokenInfo.apiDeviceData
    }

    $irmArgs = @{
      Method = "Post"
      Uri = $graphqlEndpoint
      Headers = $headers
      Body = $TokenInfo.query
      UserAgent = Get-UA
      ContentType = "application/json"
    }

    Invoke-RestMethod @irmArgs
  }

  $reactJsUrl = 'https://www.wbrc.com/pf/dist/engine/react.js'
  $page = Invoke-WebRequest -Uri $reactJsUrl -UserAgent (Get-UA)

  $tokensPattern = '[\{,](\w+?TOKEN):"(eyJhbGci.+?)"'
  $tokensMatches = $page.Content | Select-String -Pattern $tokensPattern -AllMatches
  $tokens = [System.Collections.Generic.List[object]]::new()
  foreach ($token in $tokensMatches.Matches)
  {
    $tokens.Add(@{
        $token.Groups[1].Value.Trim() = $token.Groups[2].Value.Trim()
      })
  }

  $apiToken = $tokens | Where-Object -FilterScript { $_.Keys -like "$($CallSign)_ZEAM*" } | Select-Object -First 1 -ExpandProperty Values
  if ($null -eq $apiToken)
  {
    Write-Warning -Message "Could not find API token for $($CallSign)."
    return
  }

  $jsonParsePattern = "JSON\.parse\('(\{.+?\})'\)"
  $jsonParseMatches = $page.Content | Select-String -Pattern $jsonParsePattern -AllMatches
  $stationInfos = [System.Collections.Generic.List[object]]::new()
  foreach ($jsonBody in $jsonParseMatches.Matches)
  {
    if ($jsonBody.Groups[1].Value -notlike "*appName*") { continue }
    # admiralScriptTagContents in the JSON body is double-quoted JavaScript, so we need to replace \" with ' to make parsable JSON
    $stationInfos.Add(($jsonBody.Groups[1].Value -replace '\\"', "'" | ConvertFrom-Json))
  }

  $stationInfo = $stationInfos | Where-Object -Property siteName -eq $CallSign
  if ($null -eq $stationInfo)
  {
    Write-Warning -Message "Could not find station info for $($CallSign)."
  }

  $deviceId = Get-Nonce -MaxLength 50 -UrlSafe
  $apiDeviceData = [ordered]@{
    appName = $stationInfo.syncbak.appName
    appPlatform = "web"
    bundleId = "dev"
    deviceId = $deviceId
    deviceType = 8
  }
  if ($null -eq $apiDeviceData.appName) { $apiDeviceData.Remove("appName") }
  $encodedApiDeviceData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($apiDeviceData | ConvertTo-Json -Compress)))

  $getVideoQuery = '{"query":" query GrayWebAppsDefaultData($expirationSeconds: Int, $vodCount: Int){ liveChannels { id title description callsign listImages { type url size } posterImages { type url size } isNew type status onNow { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate } onNext { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate } isNielsenEnabled isClosedCaptionEnabled location networkAffiliation taxonomy { facet terms } } firstLiveChannel: liveChannels(first: 1) { id title description callsign listImages { type url size } posterImages { type url size } isNew type status onNow { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate } onNext { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate } isNielsenEnabled isClosedCaptionEnabled location networkAffiliation taxonomy { facet terms } streamUrl(expiresIn: $expirationSeconds) } videoOnDemand(first: $vodCount){ id title description duration airDate listImages { type url size } posterImages { type url size } } } ","variables":{"expirationSeconds":300,"vodCount":PLACEHOLDER-VODCOUNT}}' -replace 'PLACEHOLDER-VODCOUNT', $Count

  $tokenInfo = [pscustomobject]@{
    apiToken = $apiToken;
    apiDeviceData = $encodedApiDeviceData
    query = $getVideoQuery
  }
  $videoStreams = DoGraphQuery -TokenInfo $tokenInfo

  if ($LiveStream)
  {
    return $videoStreams.data.firstLiveChannel.streamUrl
  }

  $atTimeZone = switch ($TimeZone)
  {
    "Eastern" { "Eastern Standard Time" }
    "Central" { "Central Standard Time" }
    "Mountain" { "Mountain Standard Time" }
    "Arizona" { "US Mountain Standard Time" }
    "Pacific" { "Pacific Standard Time" }
    "Alaska" { "Alaskan Standard Time" }
    "Hawaii" { "Hawaiian Standard Time" }
    "Local" { [System.TimeZoneInfo]::Local.Id }
    Default
    {
      $parsedTz = $null
      if ([System.TimeZoneInfo]::TryFindSystemTimeZoneById($TimeZone, [ref]$parsedTz))
      {
        $parsedTz.Id
      }
      else
      {
        Write-Warning "Unknown time zone '$($TimeZone)'. Defaulting to local time zone."
        [System.TimeZoneInfo]::Local.Id
      }
    }
  }

  $availableStreams = foreach ($stream in $videoStreams.data.videoOnDemand)
  {
    $publishedStationLocalTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($stream.airDate, $atTimeZone)
    [pscustomobject]@{
      Title = $stream.title
      Id = $stream.id
      Published = $publishedStationLocalTime
      DateString = $publishedStationLocalTime.ToString('yyyy-MM-dd HHmm')
    }
  }

  if ($PSCmdlet.ParameterSetName -eq "GetAvailable")
  {
    return $availableStreams
  }

  if ($PSCmdlet.ParameterSetName -eq "StreamId")
  {
    $theStream = $availableStreams | Where-Object -Property Id -eq $StreamId

    if ($null -eq $theStream)
    {
      Write-Warning -Message "Did not find StreamId $($StreamId) in list of available streams."
      return
    }
  }

  if ($PSCmdlet.ParameterSetName -eq "StreamTitle")
  {
    $theStream = $availableStreams | Where-Object -Property Title -like $StreamTitle

    if ($null -eq $theStream)
    {
      Write-Warning -Message "Did not find StreamTitle '$($StreamTitle)' in list of available streams."
      return
    }

    if ($theStream.Count -gt 1)
    {
      Write-Warning -Message "Found $($theStream.Count) available streams with title '$($StreamTitle)'. Picking the most recent one."
      $theStream = $theStream | Sort-Object -Property Published -Descending | Select-Object -First 1
    }
  }

  $getVODQuery = '{"query":"query GrayWebAppsVodItemData($vodId: ID!, $vodCount: Int){ videoOnDemandItem (id: $vodId){ id title description duration airDate listImages { type url size } posterImages { type url size } streamUrl } liveChannels { id title description callsign listImages { type url size } posterImages { type url size } isNew type status onNow { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate} onNext { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate} isNielsenEnabled isClosedCaptionEnabled location networkAffiliation taxonomy { facet terms } } videoOnDemand (first: $vodCount){ id title description duration airDate listImages { type url size } posterImages { type url size } } }","variables":{"vodCount":PLACEHOLDER-VODCOUNT,"vodId":"PLACEHOLDER-VODID"}}' -replace 'PLACEHOLDER-VODID', $theStream.Id -replace 'PLACEHOLDER-VODCOUNT', $Count

  $vodTokenInfo = [pscustomobject]@{
    apiToken = $apiToken;
    apiDeviceData = $encodedApiDeviceData
    query = $getVODQuery
  }
  $vodStream = DoGraphQuery -TokenInfo $vodTokenInfo

  return [pscustomobject]@{
    Title = $theStream.Title
    Published = $theStream.Published
    DateString = $theStream.DateString
    StreamUrl = $vodStream.data.videoOnDemandItem.streamUrl
  }
}
