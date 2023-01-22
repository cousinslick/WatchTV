function Get-XEWTStreamUrl
{
  $videoId = Get-YouTubeLiveIds -ChannelId "UCjwXjnO3BGePtB7gSKEpoqA" -Newest -IdOnly

  if ($null -notlike $videoId)
  {
    return "https://www.youtube.com/watch?v=$($videoId)"
  }
}