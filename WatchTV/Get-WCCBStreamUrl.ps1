function Get-WCCBStreamUrl
{
  # Local :: Univtec/Google

  try
  {
    $site = "https://www.wccbcharlotte.com/watch-live/"
    $page = Invoke-WebRequest -Uri $site -UseBasicParsing -UserAgent (Get-UA)

    # There's an iframe with a src containing a data-insight attribute. We're interested in that attribute value
    # <iframe class="responsive-iframe" src="https://snippet.univtec.com/player.html?data-insight=eyJndWlkIjoiNjQzZjJhNjctNzU3NS00Yjc5LTg2OGItY2YyZjIyYWIxYTY5IiwidHlwZSI6ImNoYW5uZWxzIiwiYWNjb3VudElkIjoiNjJjMzM0ZjVmOGU1NmY0ZTU3NmY5ZTk3IiwiY2xpZW50Ijoid2NjYiIsImFwaSI6Imh0dHBzOi8vaW5zaWdodC1hcGktZnJhbmtseS51bml2dGVjLmNvbS8ifQ==" allow="autoplay" allowfullscreen="allowfullscreen" border:0px; margin:0; padding:0; overflow:hidden; z-index:999999;">
    if ($page.Content -match "data-insight=(.+?)`"")
    {
      # Matches[1] is a base64 encoded string that, when decoded, yields a JSON document
      #   eyJndWlkIjoiMjE3MTVkZjQtMjc0ZS00ZDAyLWI...NvbS8ifQ==
      #   {"guid":"21715df4-274e-4d02-b31b-81703d7e9530","type":"chan...","client":"wxyz","api":"https://insight-api-frankly.univtec.com/"}
      # and from that, we need the guid, client, and api values
      $dataInsight = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Matches[1])) | ConvertFrom-Json

      # Construct a call to univtec. Need to pass an x-tenant-id header else error Cannot read property 'databaseUrl' of undefined
      # e.g., https://insight-api-frankly.univtec.com/cms/interface/channels/play?relations=true&filter=guid||$eq||21715df4-274e-4d02-b31b-81703d7e9530
      [uri]$diUrl = "$($dataInsight.api)cms/interface/channels/play?relations=true&filter=guid||`$eq||$($dataInsight.guid)"
      $diResp = Invoke-RestMethod -Uri $diUrl -UserAgent (Get-UA) -Headers @{ "x-tenant-id" = $dataInsight.client }

      # From this, we need the vod.assetKey to POST a request to Google's DAI platform to get the actual livestream URL
      return (Invoke-RestMethod -Method Post -UseBasicParsing -Uri "https://pubads.g.doubleclick.net/ssai/event/$($diResp.vod.assetKey)/streams" -UserAgent (Get-UA)).stream_manifest
    }
  }
  catch
  {
    return $null
  }
}
