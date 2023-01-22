@{
  RootModule = '.\WatchTV.psm1'
  ModuleVersion = '0.23.2'
  GUID = 'dbaa107f-646d-4ffd-9f6f-54b79131cf7a'
  Author = ''
  CompanyName = ''
  Copyright = ''
  Description = 'Extract live stream playlist URLs for various news stations.'
  FunctionsToExport = @(
      "Get-ABC7StreamUrl"
    , "Get-CBSLAStreamUrl"
    , "Get-Fox5ATLStreamUrl"
    , "Get-KENSStreamUrl"
    , "Get-KFMBStreamUrl"
    , "Get-KFORStreamUrl"
    , "Get-KGTVStreamUrl"
    , "Get-KJRHStreamUrl"
    , "Get-KNBCStreamUrl"
    , "Get-KNSDStreamUrl"
    , "Get-KNTVStreamUrl"
    , "Get-KOTVStreamUrl"
    , "Get-KPNXStreamUrl"
    , "Get-KSWBStreamUrl"
    , "Get-KTABStreamUrl"
    , "Get-KUSIStreamUrl"
    , "Get-KXANStreamUrl"
    , "Get-KXASStreamUrl"
    , "Get-OKC9StreamUrl"
    , "Get-WALAStreamUrl"
    , "Get-WBIRStreamUrl"
    , "Get-WBTSStreamUrl"
    , "Get-WCAUStreamUrl"
    , "Get-WESHStreamUrl"
    , "Get-WFLA38StreamUrl"
    , "Get-WFLAStreamUrl"
    , "Get-WFMJStreamUrl"
    , "Get-WFSBStreamUrl"
    , "Get-WJZStreamUrl"
    , "Get-WMAQStreamUrl"
    , "Get-WNBCStreamUrl"
    , "Get-WPMTStreamUrl"
    , "Get-WPRIStreamUrl"
    , "Get-WRCStreamUrl"
    , "Get-WTAEStreamUrl"
    , "Get-WTVFStreamUrl"
    , "Get-WTVJStreamUrl"
    , "Get-WVITStreamUrl"
    , "Get-WYFFStreamUrl"
    , "Get-XEWTStreamUrl"

    , "Get-TegnaDVR"
    , "Get-KFMBDVR"
    , "Get-KIIIDVR"
    , "Get-WXIADVR"

    , "Get-UA"
    , "Get-CabletownStreamUrl"
    , "Get-GenericStreamUrl"
    , "Get-GrayStramUrl"
    , "Get-HearstStreamUrl"
    , "Get-NexstarStreamUrl"
  )
  CmdletsToExport = @()
  VariablesToExport = '*'
  AliasesToExport = '*'
  PrivateData = @{
    PSData = @{
      LicenseUri = 'http://unlicense.org'
    }
  }
}
