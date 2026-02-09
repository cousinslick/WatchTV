function Get-KCENDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "6 News" -Id "500" -Key "1ad227282f584c96b85daeb0f0bb13f5" -Qty $Qty -TimeZone "Central"
}
