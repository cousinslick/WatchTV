function Get-KNTVStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcbayarea.com/watch/"
}

New-Alias -Name Get-NBCSFOStreamUrl -Value Get-KNTVStreamUrl
