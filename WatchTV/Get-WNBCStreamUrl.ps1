function Get-WNBCStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcnewyork.com/watch/"
}

New-Alias -Name Get-NBCNewYorkStreamUrl -Value Get-WNBCStreamUrl
