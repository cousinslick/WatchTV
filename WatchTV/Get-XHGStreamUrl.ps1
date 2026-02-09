function Get-XHGStreamUrl
{
  $videoId = Get-YouTubeLiveIds -Handle "@televisaguadalajara" -Newest -IdOnly
  #$videoId = Get-YouTubeLiveIds -ChannelId "UCRujF_YxVVFmTRWURQH-Cww" -Newest -IdOnly

  if ($null -notlike $videoId)
  {
    return "https://www.youtube.com/watch?v=$($videoId)"
  }
}
