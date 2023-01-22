function Get-KNTVStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcbayarea.com/live/"
}

New-Alias -Name Get-NBCSFOStreamUrl -Value Get-KNTVStreamUrl