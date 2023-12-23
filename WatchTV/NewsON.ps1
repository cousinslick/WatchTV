function Get-NewsONDVR
{
  param (
    [int] $StationId
  )
  function ConvertFromUnixTimestamp
  {
    param (
      [Parameter(ValueFromPipeline)][Int64] $TimeStamp,
      [string] $AtTimeZone
    )

    $dateTime = [System.DateTimeOffset]::FromUnixTimeSeconds($Timestamp)

    if ($null -notlike $AtTimeZone)
    {
      return [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($dateTime.UtcDateTime, $AtTimeZone)
    }

    $dateTime.LocalDateTime
  }

  $url = "https://newson.us/stationDetails/$($StationId)"
  $page = Invoke-WebRequest -Uri $url -UserAgent (Get-UA) -UseBasicParsing
  $vodItems = @()
  if ($page -match "__NEXT_DATA__.*?>(.+?)<")
  {
    $stationContent = $Matches[1] | ConvertFrom-Json
    foreach ($vodItem in $stationContent.props.pageProps.data.stationItemsContent.programs)
    {
      $startTime = $null = ConvertFromUnixTimestamp -TimeStamp $vodItem.startTime -AtTimeZone 'Eastern Standard Time'

      $vodItems += [pscustomobject]@{
        Title = $vodItem.name
        Published = $startTime
        DateString = $startTime.ToString('yyyy-MM-dd HHmm')
        StreamUrl = $vodItem.streamUrl
        DesktopUrl = "https://newson.us/clips/$($StationId)/$($vodItem.id)"
      }
    }
  }

  $vodItems
}

function Get-NewsONStations
{
  $geoLat = [math]::Round((Get-Random -Minimum -117.079061 -Maximum -81.653267), 6)
  $geoLon = [math]::Round((Get-Random -Minimum 32.834827 -Maximum 41.421435), 6)
  $url = "https://newson.us/api/getStates/$($geoLon)/$($geoLat)"

  $states = Invoke-RestMethod -Uri $url -UserAgent (Get-UA)
  $allStations = [System.Collections.Generic.List[pscustomobject]]::new()
  foreach ($state in $states.states)
  {
    foreach ($city in $state.cities)
    {
      foreach ($channel in $city.channels)
      {
        $thisStation = [pscustomobject]@{
          Id = $channel.id
          CallSign = $channel.configValue.callsign
          City = ($channel.configValue.locations | Select-Object -First 1).city
          State = ($channel.configValue.locations | Select-Object -First 1).state
          TimeZone = $channel.configValue.timezone
          FollowDST = $channel.configValue.followdst
          StationGroup = $channel.configValue.stationgroup
          Affiliation = $channel.configValue.affiliation
        }
        $allStations.Add($thisStation)
      }
    }
  }

  $allStations
}
