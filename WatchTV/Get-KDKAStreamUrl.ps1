function Get-KDKAStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Pittsburgh"
}

New-Alias -Name Get-CBSPittsburghStreamUrl -Value Get-KDKAStreamUrl
