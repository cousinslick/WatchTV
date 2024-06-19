function Get-WBTSStreamUrl
{
  return Get-CabletownStreamUrl -Url "https://www.nbcboston.com/watch/"
}

New-Alias -Name Get-NBCBostonStreamUrl -Value Get-WBTSStreamUrl
