function Get-WHIOStreamUrl
{
  function MakeDID
  {
    $hexPool = '0123456789abcdef'
    $hashString = foreach ($_ in 1..40) { $hexPool[(Get-Random -Minimum 0 -Maximum $hexPool.Length)] }
    return ($hashString -join '')
  }

  $url = 'https://www.whio.com/video/'
  $did = MakeDID

  # This magic URL was pulled from https://www.whio.com/pf/dist/engine/react.js for cmg-tv-10040. DID is a unique device ID that smells like a SHA1
  "https://cdn-uw2-prod.tsv2.amagi.tv/linear/amg00327-coxmediagroup-whionow-ono/playlist.m3u8?app_bundle=&app_name=&app_store_url=&url=$($url)&genre=N&ic=IAB12-3&us_privacy=&gdpr=0&gdpr_consent=&did=$($did)&dnt=0&coppa=0&rdid=$($did)&is_roku_lat="
}
