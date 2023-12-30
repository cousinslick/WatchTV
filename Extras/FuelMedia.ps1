param (
  [Parameter(Mandatory = $true)][string] $Url,
  [Parameter(Mandatory = $true)][string] $Path,
  [Parameter(Mandatory = $true)][string] $FileName,
  [Parameter(Mandatory = $true)][int] $maxDurationMin
)

function ConvertTo-String
{
  param (
    [Parameter(Mandatory = $true)][byte[]] $Bytes
  )
  [System.Text.Encoding]::UTF8.GetString($Bytes)
}

function Get-UA { "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/116.0" }

# On the livestream page there's a fuel-video tag with a data-channel attribute. That attribute is a GUID representing
# this station on the fuel streaming platform.
$page = Invoke-WebRequest -Uri $url -UserAgent (Get-UA)
if ($page.Content -notmatch 'fuel-video.+?data-channel="(.+?)"')
{
  Write-Error -Message "Failed to retrieve channel ID from livestream URL"
  break
}
$channelGuid = $Matches[1]

# The fuel streaming platform uses a GUID for each distinct livestream viewer. The origin of this GUID is unimportant,
# but the session GUID itself is integral to the whole position/request nonsense we'll get into later.
$sessionGuid = [guid]::NewGuid().guid

# This magic master playlist URL was obtained from dev tools while observing the livestream
$masterUrl = "https://fuel-streaming-prod01.fuelmedia.io/v1/sem/$($channelGuid).m3u8?sessionId=$($sessionGuid)&floating=false&adMethod=1&a-ap=0&a-mute=0&a-dnt=1&a-adPlacement=1&a-adSkippability=0"

# Some tools have trouble parsing the correct video URL from the master playlist, so we do that manually here
$m3uPattern = '#EXT-X-STREAM-INF.+?BANDWIDTH=(\d+).+?\n(http.+)'

$masterResp = Invoke-WebRequest -Uri $masterUrl -UserAgent (Get-UA)
$masterPlaylist = ConvertTo-String -Bytes $masterResp.Content
$masterPlaylistStreams = Select-String -Pattern $m3uPattern -InputObject $masterPlaylist -AllMatches
$masterStreamUrls = foreach ($stream in $masterPlaylistStreams.Matches) { @{$stream.Groups[1].Value.PadLeft(8, '0') = $stream.Groups[2].Value } }

# Take the one with the biggest bandwidth
$streamUrl = [string]($masterStreamUrls | Sort-Object -Property Keys | Select-Object -Last 1).Values

# Now, this is where things start to get really dumb.
# The above streamUrl parcels out video segments a few seconds at a time. While the stream is being consumed, we
# need to poll a session-specific endpoint to update our playback position so that the server sends new video segments
# in the next streamUrl request, but we can't advance the cursor ahead of the maximum available duration, so we need
# to poll for that too.

$fullName = [IO.Path]::Combine($Path, $FileName)

# Start the download
Write-Output -InputObject "## Starting download"
Write-Output -InputObject "=> streamUrl=$($streamUrl)"
Write-Output -InputObject "=> outFile=$($fullName)"

$ytdlpArgs = @(
  "--embed-metadata"
  , "--hls-use-mpegts"
  , "--format bestvideo+bestaudio[ext=m4a]/bestvideo+bestaudio/best"
  , "--merge-output-format mp4"
  , "--compat-options filename"
  # Some streams have pre-roll or other non-content videos (EXT-X-DISCONTINUITY) that can lead to undesired results
  # so explicitly let yt-dlp try to manage these scenarios
  , "--hls-split-discontinuity"
  , "-o `"$($fullName)`""
  , $streamUrl
)

Write-Output -InputObject "!> yt-dlp $($ytdlpArgs -join ' ')"
$ytdlp = Start-Process -FilePath "yt-dlp" -ArgumentList $ytdlpArgs -PassThru
Write-Output -InputObject "=> PID=$($ytdlp.Id)"

# Start the stopwatch early to give it a few ticks before we check it, since the fuel video player's first report isn't neat zeros
$stopwatch = [System.Diagnostics.Stopwatch]::new()
$stopwatch.Start()

# No real reason for a 60 second init value here, just needed something != 0
[double]$endDurationSec = 60
# The fuel video player polls every ~10 seconds so that's what we'll do here
$pollIntervalMs = 10000

# Again, dev tools observation
$infoUrl = "https://fuel-streaming-prod01.fuelmedia.io/v1/session/$($sessionGuid)/sections"
$posBaseUrl = "https://fuel-streaming-prod01.fuelmedia.io/v1/session/$($sessionGuid)/pos?"

# And now we poll
Write-Host "Polling" -NoNewline
while (($stopwatch.Elapsed.TotalSeconds -lt $endDurationSec) -and ($stopwatch.Elapsed.TotalMinutes -lt $maxDurationMin))
{
  # We need to send a from (f) and to (t) value in high-ish precision seconds
  $from = [math]::Round($stopwatch.Elapsed.TotalSeconds, 5, [System.MidpointRounding]::ToZero)

  Start-Sleep -Milliseconds $pollIntervalMs

  # We don't want bad internet weather to derail us so try/catch (swallow)
  try
  {
    $latestInfo = Invoke-RestMethod -Method Get -Uri $infoUrl -UserAgent (Get-UA)
    $endDurationSec = $latestInfo.data.sections.endTime | Sort-Object | Select-Object -Last 1
  }
  catch
  {
    Write-Warning -Message "Failed to get end duration from sections endpoint."
  }

  $to = [math]::Round($stopwatch.Elapsed.TotalSeconds, 5, [System.MidpointRounding]::ToZero)

  if ($from -gt $endDurationSec) { $from = $endDurationSec }
  if ($to -gt $endDurationSec) { $to = $endDurationSec }

  Write-Verbose -Message "f=$($from); t=$($to); until=$($endDurationSec)"
  Write-Host "*" -NoNewline
  try
  {
    # Update the cursor on the server. The value is in the request, not the response (which is just "ok")
    $null = Invoke-WebRequest -Uri "$($posBaseUrl)f=$($from)&t=$($to)" -UserAgent (Get-UA)
  }
  catch
  {
    Write-Warning -Message "Failed to update position. f=$($from); t=$($to); until=$($endDurationSec); elapsed=$($stopwatch.Elapsed.TotalSeconds)"
  }

  if ([math]::round($stopWatch.Elapsed.TotalSeconds) % 10 -eq 0) { Write-Host "ElapsedMin=$($stopwatch.Elapsed.TotalMinutes); MaxDurationMin=$($maxDurationMin); EndDurationMin=$($endDurationSec/60)" -Context "Heartbeat $($instanceId)" -Quiet }
}

$stopwatch.Stop()

if (!$ytdlp.HasExited)
{
  Write-Output -InputObject "Closing yt-dlp"
  try { $ytdlp.CloseMainWindow() } catch {}
  while (!$ytdlp.HasExited) { Start-Sleep -Milliseconds 250 }
  Write-Output -InputObject "yt-dlp has exited"
}

$partName = "$($fullName).part"
if (!(Test-Path -Path $partName)) { break }

Write-Output -InputObject "Renaming '$($partName)' --> '$($fullName)'"
Rename-Item -Path $partName -NewName $fullName

if (!(Test-Path -Path $fullName)) { Write-Output -InputObject "Waiting for file rename..." }
$now = Get-Date
while (!(Test-Path -Path $fullName) -and (((Get-Date) - $now).TotalMinutes -lt 1)) { Start-Sleep -Milliseconds 250 }

<#
.SYNOPSIS
Record live stream video from supported websites

.DESCRIPTION
A sample implementation that combines stream recording and progress polling.

.PARAMETER Url
The URL to a live stream page on a supported website

.PARAMETER Path
The local path where the recorded video should be saved

.PARAMETER FileName
The local filename of the recorded video

.PARAMETER maxDurationMin
How long the recording should be allowed to run, in minutes

.EXAMPLE
.\FuelMedia.ps1 -Url "https://example.com/live-video/" -Path "C:\Videos" -FileName "Recording.mp4" -MaxDurationMin 30

.NOTES
yt-dlp (and probably ffmpeg) should be set up in the PATH or similar such that they are globally invokable

As-is, no guarantee, use at your own risk, etc. This sample implementation was derived from a working script, but platform changes could render it unusable at any time.
#>
