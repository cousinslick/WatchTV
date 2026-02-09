function Get-WTSPDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "10 Tampa Bay" -Id "67" -Key "a74bccec3f144465a57fbe17678c5dec" -Qty $Qty -TimeZone "Eastern"
}
