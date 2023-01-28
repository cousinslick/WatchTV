function Get-WWJStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Detroit"
}

New-Alias -Name Get-CBSDetroitStreamUrl -Value Get-WWJStreamUrl
