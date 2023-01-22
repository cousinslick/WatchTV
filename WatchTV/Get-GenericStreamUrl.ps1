function Get-GenericStreamUrl
{
  param (
    [string] $Url,
    [string] $RegexPattern = "`"(.+m3u8)"
  )

  $page = Invoke-WebRequest -Uri $url -UseBasicParsing -UserAgent (Get-UA)

  if ($page.Content -Match $RegexPattern)
  {
    return $Matches[1]
  }

  return $null
}
