function Get-WTVJStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcmiami.com/watch/"
}

New-Alias -Name Get-NBCMiamiStreamUrl -Value Get-WTVJStreamUrl
