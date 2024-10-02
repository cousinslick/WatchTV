function Get-NewsONDVR
{
  param (
    [int] $StationId,
    [string] $TimeZone
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

  $atTz = ($null -like $TimeZone) ? 'Eastern Standard Time' : $TimeZone
  $iosAppUA = "NewsON/200407 CFNetwork/1498.700.2 Darwin/23.6.0"

  $url = "https://newson-api.triple-it.nl/v4api/program/bychannel?streamtype=ios&id=$($StationId)"
  $program = Invoke-RestMethod -Uri $url -UserAgent $iosAppUA

  $vodItems = [System.Collections.Generic.List[object]]::new()
  foreach ($vodItem in $program.programs)
  {
    $startTime = $null = ConvertFromUnixTimestamp -TimeStamp $vodItem.startTime -AtTimeZone $atTz
    $vodItems.Add([pscustomobject]@{
        Title = $vodItem.name
        Published = $startTime
        DateString = $startTime.ToString('yyyy-MM-dd HHmm')
        StreamUrl = $vodItem.streamUrl
        DesktopUrl = "https://www.newson.us/stationDetails/$($StationId)?id=$($vodItem.id)&videoType=program"
      })
  }

  $vodItems
}

function Get-NewsONStations
{
  $geoLat = [math]::Round((Get-Random -Minimum -117.079061 -Maximum -81.653267), 6)
  $geoLon = [math]::Round((Get-Random -Minimum 32.834827 -Maximum 41.421435), 6)
  $url = "https://newson.us/api/getStates/$($geoLon)/$($geoLat)"
  $url = "https://newson-api.triple-it.nl/v5api/search?query=&platformType=website"

  $rawStations = Invoke-RestMethod -Uri $url -UserAgent (Get-UA)
  $stations = $rawStations.results | Where-Object -Property title -eq "Stations" | Select-Object -ExpandProperty items
  $allStations = [System.Collections.Generic.List[pscustomobject]]::new()
  foreach ($channel in $stations)
  {
    $thisStation = [pscustomobject]@{
      Id = $channel.id
      Name = $channel.name -split ' - ' | Select-Object -First 1
      City = $channel.city
      State = $channel.state
      StationGroup = $channel.stationgroup
      Affiliation = $channel.networkAffiliation
    }
    $allStations.Add($thisStation)
  }

  $allStations
}
