function Get-WCBSStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "NewYork"
}

New-Alias -Name Get-CBSNewYorkStreamUrl -Value Get-WCBSStreamUrl
New-Alias -Name Get-CBSNYStreamUrl -Value Get-WCBSStreamUrl
