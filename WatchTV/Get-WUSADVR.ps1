function Get-WUSADVR
{
  param (
    [string] $Qty = "10"
  )

  Get-TegnaDVR -Name "WUSA9" -Id 65 -Key "24c837cef4654536975b733e257c9d79" -Qty $Qty -TimeZone "Eastern"
}
