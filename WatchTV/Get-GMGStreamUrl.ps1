function Get-GMGStreamUrl
{
  param (
    $CallSign
  )

  $gmgFeedsUrl = 'https://dist.grahamdigital.com/GMG/video/live/all.json'
  $gmgFeeds = Invoke-RestMethod -Uri $gmgFeedsUrl -UserAgent (Get-UA)
  $streamInfo = $gmgFeeds.assets | Where-Object -FilterScript {
    $_.stream_class -eq "primary" -and
    $_.stream_source -eq "epg" -and
    $_.canonical_website -eq $CallSign
  } | Select-Object -First 1

  $streamInfo.url
}
