function Get-WRCStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcwashington.com/live/"
}

New-Alias -Name Get-NBCWaDCStreamUrl -Value Get-WRCStreamUrl