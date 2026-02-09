function Get-WNEPDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "WNEP" -Id "523" -Key "c0b17bc39f1e42c8b65a2dcdeddece7e" -Qty $Qty -TimeZone "Eastern"
}
