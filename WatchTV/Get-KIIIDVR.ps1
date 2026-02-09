function Get-KIIIDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "KIII" -Id "503" -Key "7cf62126aa1b4a33a6d181383784ed03" -Qty $Qty -TimeZone "Central"
}
