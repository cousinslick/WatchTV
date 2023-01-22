function Get-CBSLAStreamUrl
{
  $site = "https://www.cbsnews.com/losangeles/live/"
  $page = Invoke-WebRequest -Uri $site -UseBasicParsing -UserAgent (Get-UA)

  if ($page.Content -match "CBSNEWS.defaultPayload =(.*})")
  {
    $items = ($Matches[1] | ConvertFrom-JSON).items
    
    return $items.video
  }  
}