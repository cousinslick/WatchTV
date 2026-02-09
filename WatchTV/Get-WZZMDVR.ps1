function Get-WZZMDVR
{
  param (
    [string] $Qty = "10"
  )
  Get-TegnaDVR -Name "13OYS" -Id "69" -Key "92e5a6ae4165444b9392dee5c4a04726" -Qty $Qty -TimeZone "Eastern"
}
