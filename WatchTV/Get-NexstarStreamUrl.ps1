function Get-NexstarStreamUrl
{
  param(
    [string] $Url
  )

  $ProgressPreference = "SilentlyContinue"

  try
  {
    $page = Invoke-WebRequest -Uri $Url -UseBasicParsing -UserAgent (Get-UA)

    # There's an article tag with a data-video_params attribute containing a HTML encoded JSON payload. We're interested in that JSON payload
    $pattern = 'data-video_params\s?=\s?"(.+?)"'
    if ($page.Content -match $pattern)
    {
      $anvato = [System.Net.WebUtility]::HtmlDecode($Matches[1]) -replace "'/", "'" | ConvertFrom-Json
    }

    # !! The old pattern stopped working in Feb. 2024, but just in case some sites haven't been updated
    # There's a script tag on the page that contains a window.loadAnvato() call with a JSON payload. We're interested in that JSON payload
    if ($null -eq $anvato)
    {
      $pattern = "<script>window\.loadAnvato\((.*?)\);</script>"
      if ($page.Content -match $pattern)
      {
        $anvato = $Matches[1] | ConvertFrom-Json
      }
    }

    if ($null -eq $anvato) { return }

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
  catch
  {
    return $null
  }

}
