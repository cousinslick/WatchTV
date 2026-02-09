function Get-KINGDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "KING 5" -Id "281" -Key "c6e84662fd0044be9e00218d75918fb6" -Qty $Qty -TimeZone "Pacific"
}
