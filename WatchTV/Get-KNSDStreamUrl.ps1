function Get-KNSDStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcsandiego.com/watch/"
}

New-Alias -Name Get-NBCSanDiegoStreamUrl -Value Get-KNSDStreamUrl
