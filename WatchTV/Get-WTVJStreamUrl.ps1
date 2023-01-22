function Get-WTVJStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcmiami.com/live/"
}

New-Alias -Name Get-NBCMiamiStreamUrl -Value Get-WTVJStreamUrl