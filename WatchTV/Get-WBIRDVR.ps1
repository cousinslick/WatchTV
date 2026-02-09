function Get-WBIRDVR
{
  param (
    [string] $Qty = "10"
  )

  Get-TegnaDVR -Name "10News" -Id "51" -Key "1e6682f50df443d787724c91a7523b47" -Qty $Qty -TimeZone "Eastern"
}

