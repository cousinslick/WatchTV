function Get-KPIXStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "SanFrancisco"
}

New-Alias -Name Get-CBSSanFranciscoStreamUrl -Value Get-KPIXStreamUrl
New-Alias -Name Get-CBSBayAreaStreamUrl -Value Get-KPIXStreamUrl
