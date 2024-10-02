function Get-XHABStreamUrl
{
  $videoId = Get-YouTubeLiveIds -Handle "@televisamatamoros" -Newest -IdOnly
  #$videoId = Get-YouTubeLiveIds -ChannelId "" -Newest -IdOnly

  if ($null -notlike $videoId)
  {
    return "https://www.youtube.com/watch?v=$($videoId)"
  }
}
