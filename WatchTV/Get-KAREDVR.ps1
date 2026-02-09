function Get-KAREDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "KARE 11" -Id "89" -Key "3ba696cf7cdd4d87af75178ece84521b" -Qty $Qty -TimeZone "Central"
}
