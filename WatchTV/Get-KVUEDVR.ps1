function Get-KVUEDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "KVUE" -Id "269" -Key "188422c055cf4783b2232eab5513dc1a" -Qty $Qty -TimeZone "Central"
}
