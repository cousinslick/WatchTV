function Get-WPMTDVR
{
  param (
    [int] $Qty = 10
  )

  Get-TegnaDVR -Name "FOX43" -Id "521" -Key "ce75d6127d8f4366b15756970c9965cd" -Qty $Qty -TimeZone "Eastern"
}
