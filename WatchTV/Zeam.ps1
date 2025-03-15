# Zeam works a bit differently than the rest of this module.
# Call Get-ZeamDVRInfo to get a list of available VODs for a station then find the one(s) you want, and call
# Get-ZeamStreamUrl to get the URL to the stream. The stream URL is only good for 90 seconds, so you need to 
# be ready to download.
#
# For example: https://zeam.com/publishers/123/zyxw-2#channel:95135
# $vods = Get-ZeamDVRInfo -PublisherId 123 -TimeZone "Central"
# $noonTodayVod = $vods | ? { $_.name -like "*Noon" -and $_.published -ge (Get-Date -Hour 0 -Minute 0 -Second 0) }
#     mediaId    : 12348765
#     channelId  : 95135
#     name       : News at Noon
#     dateString : 2025-01-04 1200
#     published  : 1/4/2025 12:00:00 PM -06:00
#     desktopUrl : https://zeam.com/publishers/123/#vod:12348765
# $streamUrl = Get-ZeamStreamUrl -ChannelId $noonTodayVod.channelId -MediaId $noonTodayVod.mediaId
#     https://vod-playlistserver.aws.syncbak.com/vod/f1234567890b123b8a95e0df1cdcaa69/master.m3u8?access_token=eyJhbGciOi...

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
