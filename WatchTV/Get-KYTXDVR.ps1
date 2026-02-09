function Get-KYTXDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "CBS19" -Id "501" -Key "807354dd4f484eefb01fecec4910e92a" -Qty $Qty -TimeZone "Central"
}
