function Get-WBZStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Boston"
}

New-Alias -Name Get-CBSBostonStreamUrl -Value Get-WBZStreamUrl
