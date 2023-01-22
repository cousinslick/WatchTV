function Get-KNBCStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbclosangeles.com/live/"
}

New-Alias -Name Get-NBCLosAngelesStreamUrl -Value Get-KNBCStreamUrl