function Get-KNSDStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcsandiego.com/live/"
}

New-Alias -Name Get-NBCSanDiegoStreamUrl -Value Get-KNSDStreamUrl