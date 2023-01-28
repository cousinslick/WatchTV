function Get-WBBMStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Chicago"
}

New-Alias -Name Get-CBSChicagoStreamUrl -Value Get-WBBMStreamUrl
