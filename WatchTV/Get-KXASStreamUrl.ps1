function Get-KXASStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcdfw.com/watch/"
}

New-Alias -Name Get-NBCDallasStreamUrl -Value Get-KXASStreamUrl
