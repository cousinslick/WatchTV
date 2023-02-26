function Get-GrayStreamUrl
{
  param (
    [string] $Domain,
    [string] $CallSign
  )

  $endpoint = "https://$($Domain.ToLowerInvariant())/pf/api/v3/content/fetch/site-service?query=%7B%22section%22:%22%2Fvideo%22,%22websiteOverride%22:%22$($CallSign.ToLowerInvariant())%22%7D&_website=$($CallSign.ToLowerInvariant())"
  $response = Invoke-RestMethod -Uri $endpoint -Method Get -UserAgent (Get-UA)
    
  $uri = $response.site.syncbak_livestream_tokens.livestream1
  if ($uri -like "//*") { $uri = "https:$($uri)" }
  return $uri
}
