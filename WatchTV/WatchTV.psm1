Push-Location -Path $PSScriptRoot

$ProgressPreference = "SilentlyContinue"

Get-ChildItem -Path "." -Filter "*.ps1" | ForEach-Object -Process {
  Write-Verbose ("Importing file {0}." -f $_.Name)
  . $_.FullName
}

Pop-Location
