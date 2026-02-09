function Get-WHASDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "WHAS11" -Id "417" -Key "040345d8d0154e159036c417bfc76834" -Qty $Qty -TimeZone "Eastern"
}
