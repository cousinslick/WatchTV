function Get-WSVNStreamUrl
{
  $url = 'https://wsvn.com/on-air-live-stream/'
  $page = Invoke-WebRequest -Uri $url -UserAgent (Get-UA)
  if ($page.Content -Match 'data-account="(\d+?)" data-video-id="(\d+?)" data-player="(.+?)" data-embed="(.+?)"')
  {
    $jsUrl = "https://players.brightcove.net/$($Matches[1])/$($Matches[3])_$($Matches[4])/index.min.js"
    $apiUrl = "https://edge.api.brightcove.com/playback/v1/accounts/$($Matches[1])/videos/$($Matches[2])"
    $js = Invoke-WebRequest -Uri $jsUrl -UserAgent (Get-UA) -UseBasicParsing
    if ($js.Content -match 'policyKey:\s?"(.+?)"')
    {
      $res = Invoke-RestMethod -Uri $apiUrl -UserAgent (Get-UA) -Headers @{Accept = "application/json;pk=$($Matches[1])" }
      return $res.sources.src
    }
  }
}
