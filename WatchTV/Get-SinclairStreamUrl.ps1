function Get-SinclairStreamUrl
{
  param(
    [Parameter(Mandatory = $true)][string] $Callsign,
    [Parameter(Mandatory = $true)][string] $Domain
  )

  $live = Invoke-RestMethod -Uri "https://livevideostatus.sinclairstoryline.com/status/$($Callsign)" -UserAgent (Get-UA) -Headers @{"Referer" = "https://$($Domain)/" }

  if ($live.isLive -eq $false)
  {
    Write-Verbose -Message "$($Callsign) is not live."
    return
  }

  if (($null -like $live.assetId) -or ($null -like $live.assetSignature))
  {
    Write-Verbose -Message "Failed to obtain assetId or assetSignature from API."
    Write-Verbose -Message ($live | ConvertTo-Json -Compress)
    return
  }

  # For whatever reason, ytdl doesn't properly parse the master playlist to pick the right stream
  # playlist, so do that manually here. Sort by BANDWIDTH after doing a dumb string sort hack and
  # take the largest one

  $masterPlaylistUrl = "https://content.uplynk.com/$($live.assetId).m3u8?$($live.assetSignature)"
  $masterPlaylistBytes = Invoke-WebRequest -Uri $masterPlaylistUrl -UserAgent (Get-UA)
  $masterPlaylist = [System.Text.Encoding]::UTF8.GetString($masterPlaylistBytes.Content)
  $masterPlaylistStreams = Select-String -Pattern '#EXT-X-STREAM-INF.+?BANDWIDTH=(\d+).+?\n(http.+)\n' -InputObject $masterPlaylist -AllMatches
  $streams = foreach ($stream in $masterPlaylistStreams.Matches) { @{$stream.Groups[1].Value.PadLeft(8, '0') = $stream.Groups[2].Value } }

  ($streams | Sort-Object -Property Keys | Select-Object -Last 1).Values
}
