function Get-KCBSStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "LosAngeles"
}

New-Alias -Name Get-CBSLosAngelesStreamUrl -Value Get-KCBSStreamUrl
New-Alias -Name Get-CBSLAStreamUrl -Value Get-KCBSStreamUrl
