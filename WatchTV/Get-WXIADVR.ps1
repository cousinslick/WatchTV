function Get-WXIADVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "11Alive" -Id "85" -Key "175259e1edcf47b6909abf4c50e2b3d9" -Qty $Qty -TimeZone "Eastern"
}

Set-Alias -Name Get-11AliveDVR -Value Get-WXIADVR
