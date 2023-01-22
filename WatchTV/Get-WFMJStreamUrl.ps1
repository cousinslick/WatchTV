function Get-WFMJStreamUrl
{
  $page = Invoke-WebRequest -Uri 'https://www.wfmj.com/live-stream' -UseBasicParsing -UserAgent (Get-UA)
  if ($page.Content -match "_franklyInitialData =(.*})")
  {
    # json contains "addthisOptions" and "addThisOptions" keys which causes PowerShell to throw a fit, so normalize before deserializing
    $routes = ($Matches[1] -creplace 'addThisOptions', 'addthisOptions' | ConvertFrom-Json).Ctx.config.routes
    $lsRoute = $routes | Where-Object -Property paths -EQ '/live-stream'
    $lsProps = ($lsRoute.body.cols.components | Where-Object -Property id -EQ 'components/media/Video').props

    # The station wraps the playlist URL in a call to a checker service that returns HTTP 200 if the station's
    # lives stream is active or HTTP 404 if it is not, so make a HEAD request to check status before returning
    # e.g., liveStreamURL=https://m3u8checker.univtec.com/?url=https://WMJF.akamaized.net/hls/live/2031688/WMJF_OUT/master.m3u8
    $isLive = $null
    try { $isLive = Invoke-WebRequest -Uri $lsProps.liveStreamURL -UserAgent (Get-UA) -Method Head } catch { Write-Verbose -Message $PSItem.Exception.Message }
    if ($null -notlike $isLive.StatusCode -and $isLive.StatusCode -eq 200)
    {
      $lsProps.liveStreamURL
    }
  }
}
