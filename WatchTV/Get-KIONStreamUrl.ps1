function Get-KIONStreamUrl
{
  Get-GenericStreamUrl -Url 'https://kion546.com/livestream-newscasts/' -RegexPattern 'file:"(https://.+?)"'
}
