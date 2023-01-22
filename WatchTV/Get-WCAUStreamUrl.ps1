function Get-WCAUStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcphiladelphia.com/live/"
}

New-Alias -Name Get-NBCPhillyStreamUrl -Value Get-WCAUStreamUrl