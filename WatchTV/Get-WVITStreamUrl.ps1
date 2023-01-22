function Get-WVITStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcconnecticut.com/live/"
}

New-Alias -Name Get-NBCConnStreamUrl -Value Get-WVITStreamUrl