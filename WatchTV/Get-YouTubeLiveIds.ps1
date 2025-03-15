function Get-YouTubeLiveIds
{
  [CmdletBinding(DefaultParameterSetName = "ChanID")]
  param (
    [Parameter(ParameterSetName = "ChanID", Mandatory = $true)][string] $ChannelId,
    [Parameter(ParameterSetName = "Handle", Mandatory = $true)][string] $Handle,
    [switch] $Newest,
    [switch] $IdOnly,
    [switch] $PassThru
  )

  #! You must register an application in the Google Developers Console, obtain a YouTube API key
  #! and enter it in $ytApiKey below before calling this function.
  # https://developers.google.com/youtube/v3/getting-started

  $ytApiKey = ""
  if ($null -like $ytApiKey) { throw "Configure your YouTube API key in Get-YouTubeLiveIds before calling this function." }

  if ($PSCmdlet.ParameterSetName -eq "Handle")
  {
    $idLookupUri = [uri]::new("https://www.googleapis.com/youtube/v3/channels?part=id&forHandle=$($Handle)&maxResults=1&key=$($ytApiKey)")
    try
    {
      $idResult = Invoke-RestMethod -Method Get -Uri $idLookupUri
      $ChannelId = $idResult.items.id
    }
    catch { return $null }
    Write-Verbose "Channel ID for Handle '$($Handle)' is '$($ChannelId)'"
  }

  $uri = [uri]::new("https://youtube.googleapis.com/youtube/v3/search?part=snippet&channelId=$($ChannelId)&order=date&type=video&eventType=live&key=$($ytApiKey)")
  try { $result = Invoke-RestMethod -Method Get -Uri $uri }
  catch { return $null }

  $liveIds = [System.Collections.Generic.List[pscustomobject]]::new()

  $lives = $result.items | Where-Object -FilterScript { $_.snippet.liveBroadcastContent -eq "live" }

  foreach ($live in $lives)
  {
    $liveIds.Add([pscustomobject]@{
        videoId = $live.id.videoId
        title = $live.snippet.title
        publishedAt = $live.snippet.publishedAt
      })
  }

  if ($PassThru)
  {
    if ($PSCmdlet.ParameterSetName -eq "Handle") { $result | Add-Member -MemberType NoteProperty -Name "channelId" -Value $ChannelId }
    return $result
  }

  if ($Newest)
  {
    $liveIds = $liveIds | Sort-Object -Property publishedAt -Descending | Select-Object -First 1
  }

  if ($IdOnly)
  {
    return $liveIds.videoId
  }

  return $liveIds
}
