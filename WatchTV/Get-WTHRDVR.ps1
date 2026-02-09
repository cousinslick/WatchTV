function Get-WTHRDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "WTHR" -Id "531" -Key "b25e585f9dcd4246a3807d10fc117f06" -Qty $Qty -TimeZone "Eastern"
}
