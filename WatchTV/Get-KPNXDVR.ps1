function Get-KPNXDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "12 News" -Id "75" -Key "7a12459ed7af41cbaa9acc764e64ea06" -Qty $Qty -TimeZone "Arizona"
}
