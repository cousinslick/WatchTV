function Get-WTKRStreamUrl
{
  # Scripps
  return Get-GenericStreamUrl -Url "https://www.wtkr.com/live"
}

Set-Alias -Name "Get-WGNTStreamUrl" -Value "Get-WTKRStreamUrl"
