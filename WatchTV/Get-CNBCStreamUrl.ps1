function Get-CNBCStreamUrl
{
  $url = 'https://tvpass.org/channel/cnbc-usa'
  $page = Invoke-WebRequest -Uri $url -UserAgent (Get-UA)
  $getStreamUrl = 'https://tvpass.org/token/CNBC?quality=hd'
  $headers = @{
    Cookie = $page.Headers.'Set-Cookie' -join '; '
    Referer = $url
    Accept = "*/*"
    'User-Agent' = (Get-UA)
  }
  $streamUrl = Invoke-RestMethod -Uri $getStreamUrl -Headers $headers | Select-Object -ExpandProperty url
  return $streamUrl
}
