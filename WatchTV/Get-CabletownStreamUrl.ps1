<#
NBC owned and operated stations

KNBC::https://www.nbclosangeles.com/live/
KNSD::https://www.nbcsandiego.com/live/
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

  $live = "Live"
  if ($Url -like "*telemundo*") { $live = "En Vivo" }

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

    $liveVideo = $dataVideos | Where-Object -FilterScript { $_.date_string.StartsWith($live) }
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

    Write-Verbose -Message "mpx_m3upid=$($liveVideo.video.meta.mpx_m3upid)"
  }
  else
  {
    Write-Error -Message "Failed to extract data-videos attribute."
    return
  }

  if ($page.Content -match '<script>var nbc = (.*?);</script>')
  {
    # json contains "pagename" and "pageName" keys which causes PowerShell to throw a fit, so normalize before deserializing
    $nbc = $Matches[1] -creplace "pagename", "pageName"
    $nbc = $nbc | ConvertFrom-Json

    Write-Verbose -Message "pdkAcct=$($nbc.pdkAcct); fwSSID=$($nbc.video.fwSSID); fwNetworkID=$($nbc.video.fwNetworkID)"
  }
  else
  {
    Write-Error -Message "Failed to extract var nbc script block."
    return
  }

  @($nbc.pdkAcct, $nbc.video.fwSSID, $nbc.video.fwNetworkID, $liveVideo.video.meta.mpx_m3upid) | ForEach-Object -Process {
    if ([string]::IsNullOrEmpty($_))
    {
      Write-Error -Message "Failed to extract one or more required values. This can happen if the livestream is not currently active."
      break
    }
  }

  $rnd = Get-Random -Minimum 1000000 -Maximum 9999999
  $thePlatformUrl = "https://link.theplatform.com/s/$($nbc.pdkAcct)/$($liveVideo.video.meta.mpx_m3upid)?mbr=true&assetTypes=LegacyRelease&fwsitesection=$($nbc.video.fwSSID)&fwNetworkID=$($nbc.video.fwNetworkID)&pprofile=ots_desktop_html&sensitive=false&usPrivacy=1YYN&w=873&h=491.0625&rnd=$($rnd)&mode=LIVE&format=SMIL&tracking=true&formats=M3U+none,MPEG-DASH+none,MPEG4,MP3&vpaid=script&schema=2.0&sdk=PDK+6.1.3"
  Write-Verbose -Message "thePlatformUrl=$($thePlatformUrl)"

  $smilResponse = Invoke-WebRequest -Uri $thePlatformUrl -UseBasicParsing -UserAgent (Get-UA)
  $smil = [xml][System.Text.Encoding]::UTF8.GetString($smilResponse.Content)

  Write-Verbose -Message "Returning $($smil.smil.body.seq.switch.video.src)"
  $smil.smil.body.seq.switch.video.src
}
