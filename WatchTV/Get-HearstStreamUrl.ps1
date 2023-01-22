function Get-HearstStreamUrl
{
  param (
    [string] $Url
  )

  $u = Get-GenericStreamUrl -Url $Url
  return ($u -split '="' | Select-Object -Last 1)
}