function Get-WFORStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Miami"
}

New-Alias -Name Get-CBSMiamiStreamUrl -Value Get-WFORStreamUrl
