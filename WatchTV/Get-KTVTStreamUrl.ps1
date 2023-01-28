function Get-KTVTStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "DFW"
}

New-Alias -Name Get-CBSDFWStreamUrl -Value Get-KTVTStreamUrl
