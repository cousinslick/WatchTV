function Get-WMAQStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcchicago.com/watch/"
}

New-Alias -Name Get-NBCChicagoStreamUrl -Value Get-WMAQStreamUrl
