function Get-WRCStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcwashington.com/watch/"
}

New-Alias -Name Get-NBCWaDCStreamUrl -Value Get-WRCStreamUrl
