function Get-WBTSStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcboston.com/live/"
}

New-Alias -Name Get-NBCBostonStreamUrl -Value Get-WBTSStreamUrl