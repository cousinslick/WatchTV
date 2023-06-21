function Get-WAGAStreamUrl
{
  return Get-FoxStreamUrl -Url "https://www.fox5atlanta.com/live"
}

New-Alias -Name Get-Fox5ATLStreamUrl -Value Get-WAGAStreamUrl
