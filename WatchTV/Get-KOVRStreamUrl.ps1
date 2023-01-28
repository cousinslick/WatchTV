function Get-KOVRStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Sacramento"
}

New-Alias -Name Get-CBSSacramentoStreamUrl -Value Get-KOVRStreamUrl
