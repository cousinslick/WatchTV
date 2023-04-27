function Get-KUSIStreamUrl
{
  # Local :: Google

  try
  {
    $site = "https://www.kusi.com/only-on-kusi/livestream/"
    $page = Invoke-WebRequest -Uri $site -UseBasicParsing -UserAgent (Get-UA)

    # There's a script tag with a data-insight attribute. We're interested in that attribute value
    if ($page.Content -match "data-insight=`"(.+?=)`"")
    {
      # Matches[1] is a base64 encoded string that, when decoded, yields a JSON document
      #   eyJndWlkIjoiMjE3MTVkZjQtMjc0ZS00ZDAyLWI...NvbS8ifQ==
      #   {"guid":"21715df4-274e-4d02-b31b-81703d7e9530","type":"chan..."","api":"https://insight-api-frankly.univtec.com/"}
      # and from that, we need the guid and api values
      $dataInsight = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Matches[1])) | ConvertFrom-Json

      # Construct a call to univtec. Need to pass an x-tenant-id header else error Cannot read property 'databaseUrl' of undefined
      # e.g., https://insight-api-frankly.univtec.com/cms/interface/channels/play?relations=true&filter=guid||$eq||21715df4-274e-4d02-b31b-81703d7e9530
      [uri]$diUrl = "$($dataInsight.api)cms/interface/channels/play?relations=true&filter=guid||`$eq||$($dataInsight.guid)"
      $diResp = Invoke-RestMethod -Uri $diUrl -UserAgent (Get-UA) -Headers @{ "x-tenant-id" = "kusi" }

      # From this, we need the vod.assetKey to POST a request to Google's DAI platform to get the actual livestream URL
      return (Invoke-RestMethod -Method Post -UseBasicParsing -Uri "https://pubads.g.doubleclick.net/ssai/event/$($diResp.vod.assetKey)/streams" -UserAgent (Get-UA)).stream_manifest
    }
  }
  catch
  {
    return $null
  }
}
