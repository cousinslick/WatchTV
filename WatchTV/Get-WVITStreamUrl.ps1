function Get-WVITStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcconnecticut.com/watch/"
}

New-Alias -Name Get-NBCConnStreamUrl -Value Get-WVITStreamUrl
