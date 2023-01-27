function Get-WZTVStreamUrl
{
  $live = Invoke-RestMethod -Uri "https://livevideostatus.sinclairstoryline.com/status/WZTV" -UserAgent (Get-UA) -Headers @{"Referer" = "https://fox17.com/" }

  if ($live.isLive -eq $false)
  {
    Write-Verbose -Message "WZTV is not live."
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

<#
https://fox17.com/watch

https://livevideostatus.sinclairstoryline.com/status/WZTV
{ "isLive":false, "assetId":null, "channelId":null, "assetSignature":null, "ssPreSignature":null, "ssPreMidSignature":null, "ssChannelPreSignature":null, "ssChannelPreMidSignature":null, "ssAssetPreSignature":null, "ssAssetPreMidSignature":null, "thumbURL":null, "isOverride":false }

GET /status/WZTV_EVENT HTTP/2
Host: livevideostatus.sinclairstoryline.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0
Accept: application/json, text/plain, */*
Accept-Language: en-US, en; q=0.5
Accept-Encoding: gzip, deflate, br
Origin: https://fox17.com
DNT: 1
Connection: keep-alive
Referer: https://fox17.com/
Sec-Fetch-Dest: empty
Sec-Fetch-Mode: cors
Sec-Fetch-Site: cross-site
TE: trailers

https://livevideostatus.sinclairstoryline.com/status/WZTV_EVENT
{ "isLive":true, "assetId":"0177e71083124b29a51056bb2c02a2a7", "channelId":"eff4acc3035845d7aa67aaf011d37cd3", "assetSignature":"tc=1&exp=1674750156&rn=232592&ct=a&cid=0177e71083124b29a51056bb2c02a2a7&sig=ae0ed805bda3bf4e137369ec2146ef89eda6b4a6d734cbcbe3d6d4c49586ef94", "ssPreSignature":"tc=1&exp=1674750156&rn=232592&ct=c&cid=eff4acc3035845d7aa67aaf011d37cd3&ad=sinclair_dfp&ad.preroll=1&ad.pre.adUnit=/wztv_event/Web/StreamTest_a&sig=eac6332ded91b3b8c6bb8980ff122d4aae3d0de310ca4ebfac4a19dd5ae12f13", "ssPreMidSignature":"tc=1&exp=1674750156&rn=232592&ct=c&cid=eff4acc3035845d7aa67aaf011d37cd3&ad=sinclair_dfp&ad.preroll=1&ad.pre.adUnit=/wztv_event/Web/StreamTest_a&ad.adUnit=/wztv_event/Web/StreamTest_b&sig=e533ec8c6e7104011bcc0ea654377a6a248c32afc9b1ecfb0c376f55f6f63e73", "ssChannelPreSignature":"tc=1&exp=1674750156&rn=232592&ct=c&cid=eff4acc3035845d7aa67aaf011d37cd3&ad=sinclair_dfp&ad.preroll=1&ad.pre.adUnit=/wztv_event/Web/StreamTest_a&sig=eac6332ded91b3b8c6bb8980ff122d4aae3d0de310ca4ebfac4a19dd5ae12f13", "ssChannelPreMidSignature":"tc=1&exp=1674750156&rn=232592&ct=c&cid=eff4acc3035845d7aa67aaf011d37cd3&ad=sinclair_dfp&ad.preroll=1&ad.pre.adUnit=/wztv_event/Web/StreamTest_a&ad.adUnit=/wztv_event/Web/StreamTest_b&sig=e533ec8c6e7104011bcc0ea654377a6a248c32afc9b1ecfb0c376f55f6f63e73", "ssAssetPreSignature":"tc=1&exp=1674750156&rn=232592&ct=a&cid=0177e71083124b29a51056bb2c02a2a7&ad=sinclair_dfp&ad.preroll=1&ad.pre.adUnit=/wztv_event/Web/StreamTest_a&sig=5bb5361f35a0c27b56744d64b06f18617ec20cfae0379cb5bc6561ef591283dd", "ssAssetPreMidSignature":"tc=1&exp=1674750156&rn=232592&ct=a&cid=0177e71083124b29a51056bb2c02a2a7&ad=sinclair_dfp&ad.preroll=1&ad.pre.adUnit=/wztv_event/Web/StreamTest_a&ad.adUnit=/wztv_event/Web/StreamTest_b&sig=aedf01629c229f9ebc01662f8cf9961ba2f0fe65c34bc9942595ac0c7a581258", "thumbURL":"https://x-default-stgec.uplynk.com/ausw/slices/017/34d28c6069b34f1d96307c80809697d7/0177e71083124b29a51056bb2c02a2a7/00000000.jpg", "isOverride":true }

https://content.uplynk.com/player/assetinfo/0177e71083124b29a51056bb2c02a2a7.json
{ "error": 0, "asset": "0177e71083124b29a51056bb2c02a2a7", "external_id": "", "audio_only": 0, "owner": "34d28c6069b34f1d96307c80809697d7", "duration": 1155.0720000000008, "max_slice": 280, "desc": "WZTV_EVENT", "slice_dur": 4.096, "is_ad": 0, "tv_rating": -1, "movie_rating": -1, "rating_flags": 0, "rates": [89, 113, 226, 406, 694, 1206, 2519], "meta": { "mode": "override" }, "ad_data": {}, "aspect_ratio": 1.7777777777777777, "thumbs": [ { "prefix": "", "bw": 128, "bh": 128, "width": 128, "height": 72 }, { "prefix": "upl256", "bw": 256, "bh": 256, "width": 256, "height": 144 }], "thumb_prefix": "https://x-default-stgec.uplynk.com/ausw/slices/017/34d28c6069b34f1d96307c80809697d7/0177e71083124b29a51056bb2c02a2a7/", "storage_partitions": [ { "start": 0, "end": 9223372036854775807, "url": "https://x-default-stgec.uplynk.com/ausw/slices/017/34d28c6069b34f1d96307c80809697d7/0177e71083124b29a51056bb2c02a2a7" }], "poster_url": "https://x-default-stgec.uplynk.com/ausw/slices/017/34d28c6069b34f1d96307c80809697d7/0177e71083124b29a51056bb2c02a2a7/00000014.jpg", "default_poster_url": "https://x-default-stgec.uplynk.com/ausw/slices/017/34d28c6069b34f1d96307c80809697d7/0177e71083124b29a51056bb2c02a2a7/00000014.jpg" }

https://content.uplynk.com/0177e71083124b29a51056bb2c02a2a7.m3u8?tc=1&exp=1674750156&rn=232592&ct=a&cid=0177e71083124b29a51056bb2c02a2a7&sig=ae0ed805bda3bf4e137369ec2146ef89eda6b4a6d734cbcbe3d6d4c49586ef94

https://content.uplynk.com/f0c2ccdb097845188d07a1c2c650b129.m3u8?tc=1&exp=1674775700&rn=232595&ct=a&cid=f0c2ccdb097845188d07a1c2c650b129&sig=c75ab2c37b7ad300959e7724adfd5c21d17eb25ca72c148c8ea9a47e5375ddfa
#EXTM3U
#EXT-X-VERSION:5
#EXT-X-INDEPENDENT-SEGMENTS
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",NAME="unspecified",LANGUAGE="en",AUTOSELECT=YES,DEFAULT=YES
#UPLYNK-MEDIA0:416x234x30,baseline-13,2x48000
#EXT-X-STREAM-INF:PROGRAM-ID=1,RESOLUTION=416x234,BANDWIDTH=441726,CODECS="mp4a.40.5,avc1.42000d",FRAME-RATE=30.000,AUDIO="aac",AVERAGE-BANDWIDTH=418275
https://content-ause1-up-1.uplynk.com/f0c2ccdb097845188d07a1c2c650b129/d.m3u8?tc=1&exp=1674775700&rn=232595&ct=a&cid=f0c2ccdb097845188d07a1c2c650b129&sig=c75ab2c37b7ad300959e7724adfd5c21d17eb25ca72c148c8ea9a47e5375ddfa&pbs=322bf37294914eec868c5236fad79a80
#UPLYNK-MEDIA0:704x396x30,main-30,2x48000
#EXT-X-STREAM-INF:PROGRAM-ID=1,RESOLUTION=704x396,BANDWIDTH=747226,CODECS="mp4a.40.5,avc1.4d001e",FRAME-RATE=30.000,AUDIO="aac",AVERAGE-BANDWIDTH=711250
https://content-ause1-up-1.uplynk.com/f0c2ccdb097845188d07a1c2c650b129/e.m3u8?tc=1&exp=1674775700&rn=232595&ct=a&cid=f0c2ccdb097845188d07a1c2c650b129&sig=c75ab2c37b7ad300959e7724adfd5c21d17eb25ca72c148c8ea9a47e5375ddfa&pbs=322bf37294914eec868c5236fad79a80
#UPLYNK-MEDIA0:896x504x30,main-31,2x48000
#EXT-X-STREAM-INF:PROGRAM-ID=1,RESOLUTION=896x504,BANDWIDTH=1299476,CODECS="mp4a.40.5,avc1.4d001f",FRAME-RATE=30.000,AUDIO="aac",AVERAGE-BANDWIDTH=1238524
https://content-ause1-up-1.uplynk.com/f0c2ccdb097845188d07a1c2c650b129/f.m3u8?tc=1&exp=1674775700&rn=232595&ct=a&cid=f0c2ccdb097845188d07a1c2c650b129&sig=c75ab2c37b7ad300959e7724adfd5c21d17eb25ca72c148c8ea9a47e5375ddfa&pbs=322bf37294914eec868c5236fad79a80
#UPLYNK-MEDIA0:1280x720x30,main-31,2x48000
#EXT-X-STREAM-INF:PROGRAM-ID=1,RESOLUTION=1280x720,BANDWIDTH=2744726,CODECS="mp4a.40.5,avc1.4d001f",FRAME-RATE=30.000,AUDIO="aac",AVERAGE-BANDWIDTH=2575972
https://content-ause1-up-1.uplynk.com/f0c2ccdb097845188d07a1c2c650b129/g.m3u8?tc=1&exp=1674775700&rn=232595&ct=a&cid=f0c2ccdb097845188d07a1c2c650b129&sig=c75ab2c37b7ad300959e7724adfd5c21d17eb25ca72c148c8ea9a47e5375ddfa&pbs=322bf37294914eec868c5236fad79a80
#UPLYNK-MEDIA0:192x108x15,baseline-11,2x48000
#EXT-X-STREAM-INF:PROGRAM-ID=1,RESOLUTION=192x108,BANDWIDTH=130351,CODECS="mp4a.40.5,avc1.42000b",FRAME-RATE=15.000,AUDIO="aac",AVERAGE-BANDWIDTH=119830
https://content-ause1-up-1.uplynk.com/f0c2ccdb097845188d07a1c2c650b129/b.m3u8?tc=1&exp=1674775700&rn=232595&ct=a&cid=f0c2ccdb097845188d07a1c2c650b129&sig=c75ab2c37b7ad300959e7724adfd5c21d17eb25ca72c148c8ea9a47e5375ddfa&pbs=322bf37294914eec868c5236fad79a80
#UPLYNK-MEDIA0:256x144x30,baseline-12,2x48000
#EXT-X-STREAM-INF:PROGRAM-ID=1,RESOLUTION=256x144,BANDWIDTH=247851,CODECS="mp4a.40.5,avc1.42000c",FRAME-RATE=30.000,AUDIO="aac",AVERAGE-BANDWIDTH=231776
https://content-ause1-up-1.uplynk.com/f0c2ccdb097845188d07a1c2c650b129/c.m3u8?tc=1&exp=1674775700&rn=232595&ct=a&cid=f0c2ccdb097845188d07a1c2c650b129&sig=c75ab2c37b7ad300959e7724adfd5c21d17eb25ca72c148c8ea9a47e5375ddfa&pbs=322bf37294914eec868c5236fad79a80
#>
