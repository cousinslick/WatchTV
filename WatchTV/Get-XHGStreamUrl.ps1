function Get-XHGStreamUrl
{
  $videoId = Get-YouTubeLiveIds -Handle "@televisaguadalajara" -Newest -IdOnly

  if ($null -notlike $videoId)
  {
    return "https://www.youtube.com/watch?v=$($videoId)"
  }
}
