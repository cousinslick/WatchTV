function Get-KCNCStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Colorado"
}

New-Alias -Name Get-CBSColoradoStreamUrl -Value Get-KCNCStreamUrl
New-Alias -Name Get-CBSDenverStreamUrl -Value Get-KCNCStreamUrl
