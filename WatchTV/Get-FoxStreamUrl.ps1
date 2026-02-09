function Get-FoxStreamUrl
{
  param (
    [string] $Url
  )

  $page = Invoke-WebRequest -Uri $url -UseBasicParsing -UserAgent (Get-UA)

  # The FOX O&O livestream page includes a script block with a dynamically generated function that takes approximately 90 positional arguments,
  # and the meaning of each argument changes with every page load. The script block also includes the positional values, but since we can't assume
  # that, for example, the auth token is always position 23 and the video ID is always position 33 (since the function is dynamically randomized),
  # we need to parse out the meaningful parameter index and values on every request. Fun.

  # Start by extracting the script block from the page
  if ($page.Content -match "<script>window\.__NUXT__=\((.*?)\);</script>")
  {
    $htmlScriptBlock = $Matches[1]

    # Then get the list of parameters the function accepts. We will use this as the index once we figure out which params we care about
    if ($Matches[1] -match "\((.+?)\)") { $params = $Matches[1] -split "," }

    # One of the parameters the function accepts is an object that is populated with values of other parameters. We can search for the
    # object properties we care about and see how they're mapped. E.g., if ad.webKey=s;ad.stationStreamId=B, then we care about values at
    # params.indexof(s) and params.indexof(B). stationStreamId==VIDEO_ID, webKey==ANVACK
    if ($htmlScriptBlock -cmatch "\w+?\.stationStreamId=(\w+?)") { $videoIdParam = $Matches[1] }
    if ($htmlScriptBlock -cmatch "\w+?\.webKey=(\w+?)") { $anvackParam = $Matches[1] }

    # Next, get the parameter values
    if ($htmlScriptBlock -match "\}\((.+)\)$") { $paramValues = $Matches[1] -split "," }

    <#
    $parameters = [System.Collections.ArrayList]::new()
    for ($i = 0; $i -lt $params.Length; $i++)
    {
      $null = $parameters.Add(@{$params[$i] = $paramValues[$i] })
    }
    #>

    # Pull out and dequote the relevant values
    $videoId = $paramValues[$params.IndexOf($videoIdParam)] -replace '"'
    $anvack = $paramValues[$params.IndexOf($anvackParam)] -replace '"'

    # And then build our request URL. This magic URL was obtained from dev tools in the response to https://access.mp.lura.live/anvacks/...
    # {"api":{"video":"https://tkx.mp.lura.live/rest/v2/mcp/video/{{VIDEO_ID}}?anvack={{ANVACK}}"}}
    $videoApiUrl = "https://tkx.mp.lura.live/rest/v2/mcp/video/$($videoId)?anvack=$($anvack)"
    try
    {
      $result = Invoke-WebRequest -Uri $videoApiUrl -UseBasicParsing -UserAgent (Get-UA) -ErrorAction SilentlyContinue

      # The call to the video API returns a JSON payload wrapped in a anvatoVideoJSONLoaded callback.
      # Strip off the callback and parse the JSON result to get the m3u8 URL
      $embed_url = (($result.Content -replace "^.+?\(" -replace "\)$" | ConvertFrom-Json).published_urls | Where-Object -Property format -like "m3u8*").embed_url
      return $embed_url
    }
    catch {}

    # In Dec. 2025, we observed a change in Fox O&O live streaming. Instead of a call to a magic lura.live URL,
    # call a new watchlive API endpoint with $videoId in a POST body to fetch the stream url
    if ($null -eq $result)
    {
      $watchLiveEndpoint = "https://prod.api.digitalvideoplatform.com/fts/v3.0/watchlive"
      $wlBody = @{
        asset = @{
          id = $videoId
        }
        stream = @{
          type = "live"
        }
        device = @{
          capabilities = @()
          width = (Get-Random -Minimum 863 -Maximum 1920)
          height = (Get-Random -Minimum 647 -Maximum 1260)
          os = "Windows"
          osv = "10"
        }
        ad = @{
          did = $null
        }
        debug = @{
          traceId = $null
        }
        privacy = @{
          us = "1YYN"
          lat = $true
        }
      } | ConvertTo-Json -Compress
      $result = Invoke-WebRequest -Uri $watchLiveEndpoint -UserAgent (Get-UA) -Method Post -Body $wlBody -ContentType "application/json"
      $response = $result.Content | ConvertFrom-Json
      return $response.stream.playbackUrl
    }
  }
}
