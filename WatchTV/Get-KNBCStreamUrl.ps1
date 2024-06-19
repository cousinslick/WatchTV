function Get-KNBCStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbclosangeles.com/watch/"
}

New-Alias -Name Get-NBCLosAngelesStreamUrl -Value Get-KNBCStreamUrl
