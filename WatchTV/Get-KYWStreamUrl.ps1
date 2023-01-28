function Get-KYWStreamUrl
{
  return Get-EyemarkStreamUrl -Slug "Philadelphia"
}

New-Alias -Name Get-CBSPhiladelphiaStreamUrl -Value Get-KYWStreamUrl
New-Alias -Name Get-CBSPhillyStreamUrl -Value Get-KYWStreamUrl
