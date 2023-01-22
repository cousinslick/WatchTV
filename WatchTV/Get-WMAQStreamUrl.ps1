function Get-WMAQStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcchicago.com/live/"
}

New-Alias -Name Get-NBCChicagoStreamUrl -Value Get-WMAQStreamUrl