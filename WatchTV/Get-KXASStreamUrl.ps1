function Get-KXASStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcdfw.com/live/"
}

New-Alias -Name Get-NBCDallasStreamUrl -Value Get-KXASStreamUrl