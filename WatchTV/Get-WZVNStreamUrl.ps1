function Get-WZVNStreamUrl
{
  $videoId = Get-YouTubeLiveIds -Handle "@abc7swfl798" -Newest -IdOnly

  if ($null -notlike $videoId)
  {
    return "https://www.youtube.com/watch?v=$($videoId)"
  }
}
