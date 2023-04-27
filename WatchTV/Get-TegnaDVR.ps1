function Get-TegnaDVR
{
  param (
    [Parameter(Mandatory = $true)][string] $Name,
    [Parameter(Mandatory = $true)][string] $Id,
    [Parameter(Mandatory = $true)][string] $Key,
    [string] $Qty = "10"
  )

  $ua = "$([uri]::EscapeDataString($Name))/1 CFNetwork/1406.0.4 Darwin/22.4.0"
  $magicUrl = "https://api.tegnadigital.com/mobile/content-ro/getContentListV2ForNativeUx/$($Id)/video/$($Qty)/news/dvr?subscription-key=$($Key)"
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
