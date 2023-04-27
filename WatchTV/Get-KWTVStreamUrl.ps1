function Get-KWTVStreamUrl
{
  # Griffin
  return "https://live.field59.com/kwtv/kwtv1/playlist.m3u8"
}

New-Alias -Name "Get-OKC9StreamUrl" -Value "Get-KWTVStreamUrl"
