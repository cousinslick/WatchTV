function Get-NexstarStreamUrl
{
  param(
    [string] $Url
  )

  $ProgressPreference = "SilentlyContinue"

  $curlExe = "curl"

  # Modern versions of Windows include a cURL binary in the Windows directory so let's
  # specify the absolute path to avoid conflicts wihth Windows Powershell 5.1 that effected
  # a 'curl' alias for Invoke-WebRequest, back before Windows shipped curl.exe
  if ($PSVersionTable.Platform -eq "Win32NT")
  {
    $curlExe = [IO.Path]::Combine($env:SystemRoot, "system32", "curl.exe")

    if (!(Test-Path -Path $curlExe))
    {
      Write-Warning -Message "cURL not found at $($curlExe)"
      return $false
    }
  }


  try
  {
    # It seems that Nexstar have implemented some automation blocking that causes Invoke-WebRequest (and Chrome via Puppeteer)
    # to fail to retrieve the live streaming webpage that contains information we need to extract. cURL (and Firefox via Puppeteer)
    # works fine, so we'll go that route.
    $page = &$curlExe -s -i -A (Get-UA) $Url

    # There's an element with a data-video_params attribute containing a HTML encoded JSON payload. We're interested in that JSON payload
    $pattern = 'data-video_params\s?=\s?"(.+?)"'
    $patternMatch = $page -match $pattern
    # When matching against the string Content attribute on the result from Invoke-WebRequest, the result was a bool and a $Matches array
    # with the regex result. But when matching against the string output from cURL, we just get the raw match. So let's accomodate this.
    if ($patternMatch -is [bool] -and $patternMatch -eq $true -and $Matches -is [array])
    {
      $patternMatch = $Matches[1]
    }
    if ($null -like $patternMatch) { return $null }
    # Strip off the stuff we don't want in case we got the cURL -match behavior instead of the IWR -match behavior.
    $patternMatch = $patternMatch -replace 'data-video_params="' -replace '"$'
    $anvato = [System.Net.WebUtility]::HtmlDecode($patternMatch) -replace "'/", "'" | ConvertFrom-Json

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
