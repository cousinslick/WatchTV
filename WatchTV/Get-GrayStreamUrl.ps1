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

    [int] $Count = 12
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
      'query-signature-token' = $TokenInfo.querySignatureToken
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

  $deviceId = Get-Nonce -MaxLength 50 -UrlSafe

  $getVideoGql = [ordered]@{
    deviceId = $deviceId;
    queryString = '{"query":" query GrayWebAppsDefaultData($expirationSeconds: Int, $vodCount: Int){ liveChannels { id title description callsign listImages { type url size } posterImages { type url size } isNew type status onNow { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate } onNext { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate } isNielsenEnabled isClosedCaptionEnabled location networkAffiliation taxonomy { facet terms } } firstLiveChannel: liveChannels(first: 1) { id title description callsign listImages { type url size } posterImages { type url size } isNew type status onNow { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate } onNext { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate } isNielsenEnabled isClosedCaptionEnabled location networkAffiliation taxonomy { facet terms } streamUrl(expiresIn: $expirationSeconds) } videoOnDemand(first: $vodCount){ id title description duration airDate listImages { type url size } posterImages { type url size } } } ","variables":{"expirationSeconds":300,"vodCount":PLACEHOLDER-VODCOUNT}}' -replace 'PLACEHOLDER-VODCOUNT', $Count
  } | ConvertTo-Json -Compress
  $getVideoToken = GetTokenInfo -DeviceId $deviceId -Query $getVideoGql
  $videoStreams = DoGraphQuery -TokenInfo $getVideoToken

  if ($LiveStream)
  {
    return $videoStreams.data.firstLiveChannel.streamUrl
  }

  $availableStreams = foreach ($stream in $videoStreams.data.videoOnDemand)
  {
    [pscustomobject]@{
      Title = $stream.title
      Id = $stream.id
      Published = $stream.airDate
      DateString = $stream.airDate.ToString('yyyy-MM-dd HHmm')
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

  $getVodGql = [ordered]@{
    deviceId = $deviceId
    queryString = '{"query":"query GrayWebAppsVodItemData($vodId: ID!, $vodCount: Int){ videoOnDemandItem (id: $vodId){ id title description duration airDate listImages { type url size } posterImages { type url size } streamUrl } liveChannels { id title description callsign listImages { type url size } posterImages { type url size } isNew type status onNow { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate} onNext { id title description episodeTitle tvRating startTime endTime duration isLooped isOffAir airDate} isNielsenEnabled isClosedCaptionEnabled location networkAffiliation taxonomy { facet terms } } videoOnDemand (first: $vodCount){ id title description duration airDate listImages { type url size } posterImages { type url size } } }","variables":{"vodCount":PLACEHOLDER-VODCOUNT,"vodId":"PLACEHOLDER-VODID"}}' -replace 'PLACEHOLDER-VODID', $theStream.Id -replace 'PLACEHOLDER-VODCOUNT', $Count
  } | ConvertTo-Json -Compress
  $getVodToken = GetTokenInfo -DeviceId $deviceId -Query $getVodGql
  $vodStream = DoGraphQuery -TokenInfo $getVodToken

  return [pscustomobject]@{
    Title = $theStream.Title
    Published = $theStream.Published
    DateString = $theStream.DateString
    StreamUrl = $vodStream.data.videoOnDemandItem.streamUrl
  }
}
