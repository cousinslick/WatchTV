function Get-KRGVStreamUrl
{
  return Get-GenericStreamUrl -Url "https://www.krgv.com/pages/live-stream" -RegexPattern "(http.+m3u8)"
}
