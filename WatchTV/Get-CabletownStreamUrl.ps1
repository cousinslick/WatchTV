<#
NBC owned and operated stations

KNBC::https://www.nbclosangeles.com/live/
KNSD::https://www.nbcsandiego.com/watch/
KNTV::https://www.nbcbayarea.com/live/
KXAS::https://www.nbcdfw.com/live/
WBTS::https://www.nbcboston.com/live/
WCAU::https://www.nbcphiladelphia.com/live/
WMAQ::https://www.nbcchicago.com/live/
WNBC::https://www.nbcnewyork.com/live/
WRC ::https://www.nbcwashington.com/live/
WTVJ::https://www.nbcmiami.com/live/
WVIT::https://www.nbcconnecticut.com/live/
#>

function Get-CabletownStreamUrl
{
  param(
    [string] $Url
  )

  $page = Invoke-WebRequest -Uri $Url -UseBasicParsing -UserAgent (Get-UA)

  if ($page.Content -match 'data-videos="(.+?)"')
  {
    $dataVideos = [System.Web.HttpUtility]::HtmlDecode($Matches[1]) | ConvertFrom-Json
    Write-Verbose -Message "Got $($dataVideos.Count) data-videos"

    if ($dataVideos.Count -eq 0)
    {
      Write-Warning -Message "Failed to retrieve videos."
      return
    }

    $liveVideo = $dataVideos | Where-Object -FilterScript { $_.video.meta.mpx_is_livestream -eq 1 }
    Write-Verbose -Message "Found $($liveVideo.Count) video with date_string=Live: $($liveVideo.canonical_url)"

    if ($liveVideo.Count -gt 1)
    {
      Write-Warning -Message "Found multiple livestream videos. Picking the first one."
      $liveVideo = $liveVideo | Select-Object -First 1
    }

    if ($liveVideo.Count -eq 0)
    {
      Write-Warning -Message "Livestream is not currently active."
      return
    }
  }
  else
  {
    Write-Error -Message "Failed to extract data-videos attribute."
    return
  }

  Write-Verbose -Message "Returning $($liveVideo.video.meta.m3u8_url)"
  $liveVideo.video.meta.m3u8_url
}
