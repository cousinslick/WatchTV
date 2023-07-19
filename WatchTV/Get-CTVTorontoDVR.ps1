function Get-CTVTorontoDVR
{
  # Note: Qty is per-newscast
  param (
    [ValidateRange(1, 15)][int] $Qty = 1
  )

  $ErrorActionPreference = "Stop"
  $ProgressPreference = "SilentlyContinue"

  function UnBOM
  {
    param(
      [Parameter(ValueFromPipeline)][string] $String
    )

    $String -replace "\uFEFF"
  }

  $dvrVideos = [System.Collections.Generic.List[pscustomobject]]::new()

  $bellApiUA = "Ktor client"
  $bellApiBaseUrl = "https://prod2.newsapps.bellmedia.ca"
  $bellGetVideosEndpoint = "/NewsMasterService.svc/iOS/CTVNews/Toronto/GetVideos"
  $bellSectors = @(
    @{Name = "CTV+News+at+Noon"; BinId = "1.3378525"; }
    , @{Name = "CTV+News+at+Six"; BinId = "1.3378531"; }
    , @{Name = "CTV+News+at+11%3A30"; BinId = "1.3378514"; }
  )

  $mediaApiUA = "CTVNews/1230259 CFNetwork/1408.0.4 Darwin/22.5.0"
  $mediaApiBaseUrl = "https://capi.9c9media.com"
  $mediaContentPackageBasePath = "/destinations/ctvnews_ios/platforms/iPhone/contents"
  $mediaContentPackageQuery = "?%24lang=en&%24include=%5BDesc%2CType%2CMedia%2CImages%2CContentPackages%2CAuthentication%2CSeason%2CChannelAffiliate%2COwner%2CRevShare%2CAdTarget%2COmniture%2CKeywords%2CAdRights%5D"
  $mediaManifestBasePath = "/destinations/ctvnews_ios/platforms/iPhone/bond/contents"
  $mediaManifestQuery = "?action=reference&ssl=true&filter=13"

  foreach ($newsShow in $bellSectors)
  {
    $bellVideoEndpoint = "$($bellApiBaseUrl)$($bellGetVideosEndpoint)?sector=$($newsShow.Name)"
    try
    {
      Write-Verbose -Message "Polling $($bellVideoEndpoint)"
      $sectorVideos = Invoke-WebRequest -Uri $bellVideoEndpoint -UserAgent $bellApiUA
    }
    catch
    {
      Write-Warning -Message "Failed to retrieve videos for $($newsShow.Name)"
      continue
    }
    $videoItems = ($sectorVideos.Content | UnBOM | ConvertFrom-Json).ResponseData.Items | Select-Object -First $Qty

    foreach ($videoItem in $videoItems)
    {
      # PowerShell automatically converts the UTC BroadcastDateandTime in the response to a local DateTime when deserializing, but we actually want it as the local time in Toronto.
      $easternTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($videoItem.BroadcastDateandTime, 'Eastern Standard Time')

      $video = [pscustomobject]@{
        Title = $videoItem.Desc
        Published = $easternTime
        DateString = $easternTime.ToString("yyyy-MM-dd HHmm")
        StreamUrl = $null
        DesktopUrl = $null
      }

      $contentPackageEndpoint = "$($mediaApiBaseUrl)$($mediaContentPackageBasePath)/$($videoItem.AxisMediaID)$($mediaContentPackageQuery)"
      try
      {
        Write-Verbose -Message "Polling $($contentPackageEndpoint)"
        $contentPackages = Invoke-WebRequest -Uri $contentPackageEndpoint -UserAgent $mediaApiUA
      }
      catch
      {
        Write-Warning -Message "Failed to retrieve content package for video $($videoItem.AxisMediaID)"
        continue
      }
      $contentPackage = ($contentPackages.Content | UnBOM | ConvertFrom-Json).ContentPackages
      $getManifestEndpoint = "$($mediaApiBaseUrl)$($mediaManifestBasePath)/$($videoItem.AxisMediaID)/contentPackages/$($contentPackage.Id)/manifest.am3u8$($mediaManifestQuery)"
      try
      {
        Write-Verbose -Message "Polling $($getManifestEndpoint)"
        $manifest = Invoke-WebRequest -Uri $getManifestEndpoint -UserAgent $mediaApiUA
      }
      catch
      {
        Write-Warning -Message "Failed to retrieve manifest for video $($videoItem.AxisMediaID))"
        continue
      }

      $video.StreamUrl = $manifest.Content
      $video.DesktopUrl = "https://toronto.ctvnews.ca/video?binId=$($newsShow.BinId)#$($videoItem.AxisMediaID)"
      $dvrVideos.Add($video)
    }
  }

  $dvrVideos
}
