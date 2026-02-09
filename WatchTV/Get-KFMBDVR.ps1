function Get-KFMBDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "CBS 8 SD" -Id "509" -Key "ab91d26fd9f44ac8953946e10a0158f9" -Qty $Qty -TimeZone "Pacific"
}
