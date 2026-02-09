function Get-TegnaDVR
{
  param (
    [Parameter(Mandatory = $true)][string] $Name,
    [Parameter(Mandatory = $true)][string] $Id,
    [Parameter(Mandatory = $true)][string] $Key,
    [string] $Qty = "10",
    [string] $TimeZone = "Local"
  )

  $ua = "$([uri]::EscapeDataString($Name))/1 CFNetwork/1406.0.4 Darwin/22.4.0"
  $magicUrl = "https://api.tegnadigital.com/mobile/content-ro/getContentListV2ForNativeUx/$($Id)/video/$($Qty)/news/dvr?subscription-key=$($Key)"
  $streams = Invoke-RestMethod -Method Get -Uri $magicUrl -UserAgent $ua

  $atTimeZone = switch ($TimeZone)
  {
    "Eastern" { "Eastern Standard Time" }
    "Central" { "Central Standard Time" }
    "Mountain" { "Mountain Standard Time" }
    "Arizona" { "US Mountain Standard Time" }
    "Pacific" { "Pacific Standard Time" }
    "Alaska" { "Alaskan Standard Time" }
    "Hawaii" { "Hawaiian Standard Time" }
    "Local" { [System.TimeZoneInfo]::Local.Id }
    Default
    {
      $parsedTz = $null
      if ([System.TimeZoneInfo]::TryFindSystemTimeZoneById($TimeZone, [ref]$parsedTz))
      {
        $parsedTz.Id
      }
      else
      {
        Write-Warning "Unknown time zone '$($TimeZone)'. Defaulting to local time zone."
        [System.TimeZoneInfo]::Local.Id
      }
    }
  }

  $result = [System.Collections.ArrayList]::new()
  foreach ($stream in $streams)
  {
    $pubDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($stream.datePublished, "UTC", $atTimeZone)
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
