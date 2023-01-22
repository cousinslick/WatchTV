function Get-KUSIStreamUrl
{
  # Local :: Google

  try
  {
    $site = "https://www.kusi.com/only-on-kusi/livestream/"
    $page = Invoke-WebRequest -Uri $site -UseBasicParsing -UserAgent (Get-UA)

    # There's an iframe for embed-akamai.php?params=<base64 str>. We're interested in that params= value
    if ($page.Content -match "params=(.+?=)`"")
    {
      # $Matches[1] is a base64 encoded string that, when decoded, yields a querystring
      #   dXJsPVlRcnFFelMtUWtlSTRVRUN2WW9XREEmdWE9VUEtMTc3Nzc2Mi...0ZWdvcnk9VmlkZW8=
      #   url=YQrqEzS-QkeI4UECvYoWDA&ua=UA-177776...d&category=Video
      # and from that, we are interested in the url= value

      $streamId = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Matches[1])) -split "&" | Where-Object -FilterScript { $_ -like "url=*" }) -replace "url="

      # Now, POST a request to Google's DAI platform to get the livestream URL
      return (Invoke-RestMethod -Method Post -UseBasicParsing -Uri "https://pubads.g.doubleclick.net/ssai/event/$($streamId)/streams" -UserAgent (Get-UA)).stream_manifest
    }
  }
  catch
  {
    return $null
  }
}
