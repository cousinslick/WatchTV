function Get-TegnaDVR
{
  param (
    [Parameter(Mandatory = $true)][string] $Name,
    [Parameter(Mandatory = $true)][string] $Id,
    [Parameter(Mandatory = $true)][string] $Key
  )

  $ua = "$([uri]::EscapeDataString($Name))/1 CFNetwork/1399 Darwin/22.1.0"
  $magicUrl = "https://api.tegnadigital.com/mobile/content-ro/getContentListV2ForNativeUx/$($Id)/video/10/news/dvr?subscription-key=$($Key)"
  $streams = Invoke-RestMethod -Method Get -Uri $magicUrl -UserAgent $ua

  $result = [System.Collections.ArrayList]::new()
  foreach($stream in $streams)
  {
    $pubDate = (Get-Date -Date $stream.datePublished -AsUTC).ToLocalTime();
    $null = $result.Add([pscustomobject]@{
      Title = $stream.title;
      Published = $pubDate;
      DateString = $pubDate.ToString("yyyy-MM-dd HHmm");
      StreamUrl = $stream.renditions[0].url;
      DesktopUrl = $stream.url.canonicalUrl;
    })
  }

  return $result
}
