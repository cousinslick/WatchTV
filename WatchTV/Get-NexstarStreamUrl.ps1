function Get-NexstarStreamUrl
{
  param(
    [string] $Url
  )

  $ProgressPreference = "SilentlyContinue"

  try
  {
    $page = Invoke-WebRequest -Uri $Url -UseBasicParsing -UserAgent (Get-UA)

    # There's a script tag on the page that contains a window.loadAnvato() call with a JSON payload. We're interested in that JSON payload
    if ($page.Content -match "<script>window\.loadAnvato\((.*?)\);</script>")
    {
      $anvato = $Matches[1] | ConvertFrom-Json

      # This magic videoApiUrl was obtained from
      # https://access.mp.lura.live/anvacks/{{accessKey}}?apikey={{apiKey}}
      # where {{accessKey}} is obtained from the JSON payload above and apiKey is assumed to be the static string '3hwbSuqqT690uxjNYBktSQpa5ZrpYYR0Iofx7NcJHyA'
      # so, e.g.: https://access.mp.lura.live/anvacks/YVdnkAXrPxP5oH9mZZizqHObKMdyLlJ9?apikey=3hwbSuqqT690uxjNYBktSQpa5ZrpYYR0Iofx7NcJHyA
      
      $videoApiUrl = "https://tkx.mp.lura.live/rest/v2/mcp/video/$($anvato.video)?anvack=$($anvato.accessKey)"
      $result = Invoke-WebRequest -Uri $videoApiUrl -UseBasicParsing -UserAgent (Get-UA)
      
      # The call to the video API returns a JSON payload wrapped in a anvatoVideoJSONLoaded callback.
      # Strip off the callback and parse the JSON result to get the m3u8 URL

      return ($result.Content -replace "^.+?\(" -replace "\)$" | ConvertFrom-Json).published_urls.embed_url
    }
  }
  catch
  {
    return $null
  }

}