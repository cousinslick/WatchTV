<#
CBS owned and operated stations

KCBS::losangeles
KOVR::sacramento
KPIX::sanfrancisco
KCNC::colorado
WFOR::miami
WBBM::chicago
WJZ ::baltimore
WBZ ::boston
WWJ ::detroit
WCCO::minnesota
WCBS::newyork
KYW ::philadelphia
KDKA::pittsburgh
KTVT::dfw
#>

function Get-EyemarkStreamUrl
{
  param (
    [Parameter(Mandatory = $true)][string] $Slug
  )

  $url = 'https://www.cbsnews.com/video/xhr/collection/component/live-channels/'
  $live = Invoke-RestMethod -Uri $url

  Write-Verbose -Message "Slug='$($Slug)'; Slugs in response: $($live.items.slug -join ',')"

  if ($Slug -eq "all")
  {
    $streams = [System.Collections.Generic.List[pscustomobject]]::new()
    foreach($item in $live.items)
    {
      $streams.Add([pscustomobject]@{
        Slug = $item[0].slug;
        Title = $item[0].title;
        StreamUrl = $item[0].items.video2
        StreamUrlAlt = $item[0].items.video
      })
    }
    return $streams
  }

  $feed = $live.items | Where-Object -Property slug -eq $Slug
  if ($null -eq $feed) { Write-Verbose -Message "Feed not found for slug."; return }
  if ($null -like $feed.items[0].video2) { return $feed.items[0].video }
  $feed.items[0].video2
}
