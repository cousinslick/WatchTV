# WatchTV

A PowerShell module to extract live stream playlist URLs from various news stations.

## FAQ
### What does this module do?

This module obtains data from publicly accessible web pages and API endpoints and parses out the playlist URL for a news station's active live stream.

### What doesn't this module do?

Capture, record, stream, or otherwise download any video content. It does not perform spacetime trickery and is therefore unable to obtain past or future live stream content, except where noted. Implementation of this module is left as an exercise for the reader.

### Wait, 'except where noted' on spacetime trickery???

Some news stations provide DVR-like functionality to rewatch recent live streams. Functions that support this capability are suffixed with `DVR`.

### What do I do with the URLs this module provides?

That's up to you. One option might be to feed them to yt-dlp.

## Examples
### A basic implementation

```powershell
Import-Module -Name WatchTV
$Url = Get-KXANStreamUrl
if ($null -notlike $Url) {
    & yt-dlp --downloader ffmpeg --hls-use-mpegts -o "KXAN.ts" "$($Url)"
}
```

### Using DVR
```powershell
Import-Module -Name WatchTV
$Urls = Get-KIIIDVR
$Latest6PM = $Urls | Where-Object -Property Title -EQ "3News at 6 p.m." | Sort-Object -Property Published -Descending | Select-Object -First 1
if ($null -notlike $Latest6PM.StreamUrl){
    & yt-dlp --downloader ffmpeg --hls-use-mpegts -o "$($Latest6PM.Title) $($Latest6PM.DateString).ts" "$($Latest6PM.StreamUrl)"
}
```

## Support policy

This PowerShell module (and any implementation of it) is not supported in any way. Over time, news stations may change how their live stream features work, which may break functions in this module. There is no guarantee that this module will be updated to accommodate such breaking changes.
