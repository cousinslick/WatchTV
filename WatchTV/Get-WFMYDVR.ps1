function Get-WFMYDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "WFMY News 2" -Id "83" -Key "9d151e75a4354647a92ac67a98a0c623" -Qty $Qty -TimeZone "Eastern"
}
