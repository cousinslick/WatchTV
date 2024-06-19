function Get-WCAUStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcphiladelphia.com/watch/"
}

New-Alias -Name Get-NBCPhillyStreamUrl -Value Get-WCAUStreamUrl
