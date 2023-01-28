function Get-WJZStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Baltimore"
}

New-Alias -Name Get-CBSBaltimoreStreamUrl -Value Get-WJZStreamUrl
