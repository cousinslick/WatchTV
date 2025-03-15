function Get-ZeamDVRInfo
{
  param (
    [Parameter(Mandatory = $true)][int] $PublisherId,
    [string] $TimeZone = "Eastern"
  )

  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'

  $atTimeZone = switch ($TimeZone)
  {
    "Eastern" { "Eastern Standard Time" }
    "Central" { "Central Standard Time" }
    "Mountain" { "Mountain Standard Time" }
    "Arizona" { "US Mountain Standard Time" }
    "Pacific" { "Pacific Standard Time" }
    "Alaska" { "Alaskan Standard Time" }
    "Hawaii" { "Hawaiian Standard Time" }
    Default
    {
      $parsedTz = $null
      if ([System.TimeZoneInfo]::TryFindSystemTimeZoneById($TimeZone, [ref]$parsedTz))
      {
        $parsedTz.Id
      }
      else
      {
        Write-Warning "Unknown time zone '$($TimeZone)'. Defaulting to Eastern Standard Time."
        $atTimeZone = "Eastern Standard Time"
      }
    }
  }

  $zeamPublisherUrl = "https://zeam.com/publishers/$($PublisherId)/"
  $publisherPage = Invoke-WebRequest -Uri $zeamPublisherUrl -UserAgent (Get-UA)

  if (!($publisherPage.Content -match "json=(.*?\});"))
  {
    Write-Warning "Failed to extract JSON from $($zeamPublisherUrl)"
    return
  }

  $info = $Matches[1] | ConvertFrom-Json
  $allVods = $info.publisher.publisherGroups.vods | Select-Object -Property mediaId, channelId, name, airDate, dateString, published, desktopUrl
  $allVods | ForEach-Object -Process {
    $airDateTime = [System.DateTimeOffset]::FromUnixTimeSeconds($_.airDate)
    $airDateStationTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($airDateTime, $atTimeZone)
    $_.dateString = $airDateStationTime.ToString("yyyy-MM-dd HHmm")
    $_.published = $airDateStationTime
    $_.desktopUrl = "https://zeam.com/publishers/$($PublisherId)/#vod:$($_.mediaId)"
  }

  return $allVods | Select-Object -ExcludeProperty airDate | Sort-Object published -Descending
}

function Get-ZeamStreamUrl
{
  param (
    [Parameter(Mandatory = $true)][int] $ChannelId,
    [Parameter(Mandatory = $true)][int] $MediaId,
    [switch] $PassThru
  )

  $streamInfoUrl = "https://zeam.com/api/services/StreamInfo?stationId=$($ChannelId)&mediaId=$($MediaId)"
  $streamInfo = Invoke-RestMethod -Uri $streamInfoUrl -UserAgent (Get-UA)

  if ($PassThru)
  {
    return $streamInfo
  }

  return $streamInfo.streamUrl
}
