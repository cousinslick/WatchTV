function Get-WWLDVR
{
  param (
    [string] $Qty = "10"
  )
  Get-TegnaDVR -Name "WWL TV" -Id "289" -Key "c092b0d785144512940c5da247e843ef" -Qty $Qty
}
