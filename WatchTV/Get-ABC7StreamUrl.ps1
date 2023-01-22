function Get-ABC7StreamUrl
{
  # ABC O&O
  return Get-GenericStreamUrl -Url "https://abc7.com/watch/live" -RegexPattern "<meta.+content=`"(https.+\.m3u8).+?`"/>"
}