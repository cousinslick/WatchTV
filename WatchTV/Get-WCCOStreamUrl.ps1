function Get-WCCOStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Minnesota"
}

New-Alias -Name Get-CBSMinnesotaStreamUrl -Value Get-WCCOStreamUrl
