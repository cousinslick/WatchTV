param (
  [string] $Url,
  [int] $DurationSec,
  [string] $OutputDir,
  [string] $OutputBaseName,
  [ValidateSet("rec", "dl", "auto")][string] $Mode = "auto",
  [ValidatePattern("\b(all|low|mid|high|\d+[pPkK])\b")][string] $Resolution = "high",
  [switch] $ShowWindow,
  [switch] $Unmute,
  [string] $TempDir = ([IO.Path]::GetTempPath()),
  [switch] $ReContainer
)

#region helper functions
function Write-LogEvent
{
  param (
    [string] $Message,
    [Alias("Warning")][switch] $IsWarning,
    [Alias("Error")][switch] $IsError,
    [Alias("Verbose", "Quiet")][switch] $IsVerbose
  )

  $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
  $sev = "Inf"
  if ($IsWarning) { $sev = "Wrn" }
  if ($IsError) { $sev = "Err" }
  if ($IsVerbose) { $sev = "Trc" }
  $logLine = "$($now) [$($sev)] $($Message)"

  #TODO: Implement file-based logging, if desired
  #$logLine | Out-File -FilePath InvokeTubeDigger.log -Append -Encoding utf8

  switch ($sev)
  {
    "Wrn" { Write-Warning -Message $logLine }
    "Err" { Write-Error -Message $logLine }
    "Trc" { Write-Verbose -Message $logLine }
    Default { Write-Output -InputObject $logLine }
  }
}

function Get-RandomString
{
  param (
    [ValidateRange(1, 64)][int] $Length = 8
  )
  $local:bytes = [byte[]]::new(48)
  $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
  $rng.GetBytes($local:bytes)
  $rng.Dispose()
  ([convert]::ToBase64String($local:bytes) -replace "/", "_" -replace "\+", "-" -replace "=").Substring(0, $Length)
}

function Convert-VideoContainer
{
  param (
    [Parameter(Mandatory = $true)] $Path,
    [string] $Ext = '.mp4'
  )

  if (!(Test-Path -Path $Path))
  {
    Write-LogEvent -Message "Path '$($Path)' not found!" -Error
    return
  }

  if ($Path -is [string]) { $Path = Get-Item -Path $Path }
  if ($Ext[0] -ne ".") { $Ext = ".$($Ext)" }

  #ffmpeg -i $_.FullName -c:v copy -c:a copy "$($_.BaseName).mp4"
  $ffArgs = [System.Collections.Generic.List[string]]::new()
  $ffArgs.Add("-hide_banner -loglevel error -nostats")
  $ffArgs.Add("-i `"$($Path.FullName)`"")
  $ffArgs.Add("-c:v copy")
  $ffArgs.Add("-c:a copy")

  $baseName = $Path.BaseName
  if ($Ext -eq $Path.Extension) { $baseName = "$($baseName) $(Get-RandomString)" }
  $outFile = "$($baseName)$($Ext)"
  $outFullName = [IO.Path]::Combine($Path.DirectoryName, $outFile)

  if ((Test-Path -Path ($outFullName)))
  {
    $outFile = "$($baseName) $(Get-RandomString)$($Ext)"
    $outFullName = [IO.Path]::Combine($Path.DirectoryName, $outFile)
  }

  $ffArgs.Add("`"$($outFile)`"")

  Write-LogEvent -Message "Converting '$($Path.FullName)' --> '$($outFile)'"
  Write-LogEvent -Message ($ffArgs | ConvertTo-Json -Compress) -Quiet

  $startInfo = @{
    FilePath = "ffmpeg";
    ArgumentList = $ffArgs;
    WorkingDirectory = $Path.DirectoryName;
    PassThru = $true;
    Wait = $true;
    NoNewWindow = $true;
  }
  $result = Start-Process @startInfo

  if ($result.ExitCode -eq 0)
  {
    (Get-Item -Path $outFullName).LastWriteTime = $Path.LastWriteTime
  }
}

#endregion

#region preflight
# As of 7.7.2, TubeDigger is a 32-bit process that lives in Program Files (x86) on 64-bit systems
if ([System.Environment]::Is64BitProcess) { $pf32 = ${env:ProgramFiles(x86)} } else { $pf32 = $env:ProgramFiles }
$TUBEDIGGER_EXE = [IO.Path]::Combine($pf32, "TubeDigger", "TubeDigger.exe")

if (!(Test-Path -Path $TUBEDIGGER_EXE))
{
  Write-LogEvent -Message "TubeDigger must be installed on this computer to run this script." -Error
  throw [System.IO.FileNotFoundException]::new("TubeDigger not found at '$($TUBEDIGGER_EXE)' Cannot continue.")
}

if (($null -notlike $OutputBaseName) -and ($null -like $OutputDir))
{
  Write-LogEvent -Message "For boring implementaiton reasons, you must also specify -OutputDir to use -OutputBaseName." -Error
  throw [System.ArgumentException]::new("Must also specify -OutputDir with -OutputBaseName")
}

if ($ReEncode -and ($null -like $OutputDir))
{
  Write-Trace -Message "For boring implementaiton reasons, you must also specify -OutputDir to use -ReEncode." -Error -Context $runContext
  throw [System.ArgumentException]::new("Must also specify -OutputDir with -ReEncode")
}

if ($null -notlike $OutputDir)
{
  $newTempDir = [IO.Path]::Combine($TempDir, "itd-$(Get-RandomString)")
  Write-LogEvent -Message "Expanding TempDir '$($TempDir)' -> '$($newTempDir)' for this run."
  $TempDir = $newTempDir
  if (!(Test-Path -Path $TempDir)) { $null = New-Item -Path $TempDir -ItemType Directory }
}
#endregion

$tdArgs = [System.Collections.Generic.List[string]]::new()
$tdArgs.Add("`"$($Url)`"")
if ($Mode -ne "auto") { $tdArgs.Add("-$($Mode)") }
$tdArgs.Add("-res=$($Resolution)")
if ($DurationSec -ne 0) { $tdArgs.Add("-blank=$($DurationSec)") }
if ($null -notlike $OutputDir) { $tdArgs.Add("-outputdir=`"$($TempDir)`"") }
if (!$ShowWindow) { $tdArgs.Add("-hide") }
if (!$Unmute) { $tdArgs.Add("-mute") }
$tdArgs.Add("-exit")

Write-LogEvent -Message "Invoking: $($TUBEDIGGER_EXE) $($tdArgs -join ' ')"
$startTime = Get-Date
$tdProc = Start-Process -FilePath $TUBEDIGGER_EXE -ArgumentList $tdArgs -PassThru

Write-LogEvent -Message "Waiting for TubeDigger child processes to start. PID=$($tdProc.Id)"

$tdChildProc = $null
while ($tdChildProc.Count -eq 0)
{
  Start-Sleep -Milliseconds 500
  $tdChildProc = (Get-CimInstance -ClassName CIM_Process | Where-Object -Property ParentProcessId -eq $tdProc.Id)
}

Write-LogEvent -Message "Waiting $($DurationSec) seconds."
if ($DurationSec -eq 0)
{
  Write-LogEvent -Message "A zero second recording, eh? Consider a bigger number for -DurationSec." -Warning
}

$inWaitLoop = $true
while ($inWaitLoop)
{
  Start-Sleep -Seconds 1
  $waitSec = [int]((Get-Date) - $startTime).TotalSeconds
  $inWaitLoop = !($waitSec -ge $DurationSec)
}

Write-LogEvent -Message "Closing TubeDigger processes."

$tdChildProcName = (Get-Item -Path $tdChildProc.Path).BaseName
$tdChildProcs = Get-Process -Name $tdChildProcName
foreach ($proc in $tdChildProcs)
{
  Write-LogEvent -Message "Calling CloseMainWindow() on PID $($proc.Id)"
  $proc.CloseMainWindow()
}
Write-LogEvent -Message "Calling CloseMainWindow() on PID $($tdProc.Id)"
$tdProc.CloseMainWindow()

# Give the processes a few seconds to exit gracefully
Start-Sleep -Seconds 5

# Then, sledgehammer
foreach ($proc in $tdChildProcs)
{
  if (!$proc.HasExited)
  {
    Write-LogEvent -Message "Calling Kill() on PID $($proc.Id)"
    $proc.Kill()
  }
}
if (!$tdProc.HasExited)
{
  Write-LogEvent -Message "Calling Kill() on PID $($tdProc.Id)"
  $tdProc.Kill()
}

Write-LogEvent -Message "Done with TubeDigger."

if ($null -notlike $OutputDir)
{
  # Give the file system a few seconds
  Start-Sleep -Seconds 2

  $tempItem = Get-ChildItem -Path $TempDir | Sort-Object -Property Length -Descending | Select-Object -First 1
  Write-LogEvent -Message "tempItem=$($tempItem.FullName); Length=$($tempItem.Length)" -Quiet
  if ($null -like $tempItem) { throw [System.IO.FileNotFoundException]::new("Recording not found in TempDir") }

  if ($ReContainer)
  {
    Convert-VideoContainer -Path $tempItem.FullName -Ext ".mp4"
    $tempItem = Get-Item -Path ([IO.Path]::Combine($tempItem.DirectoryName, "$($tempItem.BaseName).mp4"))
    Write-LogEvent -Message "case=ReContainer; tempItem=$($tempItem.FullName); Length=$($tempItem.Length)" -Quiet
  }

  if (!(Test-Path -Path $OutputDir)) { $null = New-Item -Path $OutputDir -ItemType Directory }

  $destName = $OutputDir
  if ($null -notlike $OutputBaseName) { $destName = [IO.Path]::Combine($OutputDir, "$($OutputBaseName)$($tempItem.Extension)") }

  $moveSplat = @{
    Path = $tempItem.FullName
    Destination = $destName
    Force = $true
  }
  Write-LogEvent "Moving: $($moveSplat.Path) -> $($moveSplat.Destination)"
  Move-Item @moveSplat

  Remove-Item -Path $TempDir -Force -Recurse
}

<#
.SYNOPSIS
Invokes TubeDigger to automate stubborn stream recording scenarios

.DESCRIPTION
A PowerShell wrapper around the command line interface for TubeDigger, a commercial (i.e. not free) Windows utility that facilitates recording streaming content. This script works on web pages where a video player is accessible without login or interaction.

.PARAMETER Url
The URL of the web page hosting the video player for the streaming content. Not a stream playlist or manifest.

.PARAMETER DurationSec
In "rec" mode, the number of seconds TubeDigger should record the stream.

.PARAMETER OutputDir
Optionally, the full path to the directory where the recorded stream should be stored. If omitted, the recording will be saved to the default path configured in TubeDigger.

.PARAMETER OutputBaseName
Optionally, the base name (the file name without extension) to use for the recorded stream. If specified, must also specify OutputDir. If omitted, the recording will use the TubeDigger default value.

.PARAMETER Mode
Optional. Run TubeDigger in a specific capture mode. Either "rec", "dl", or "auto". Default "auto".

.PARAMETER Resolution
Optional. The target resolution TubeDigger should attempt to record. Either a preset ("all", "low", "mid", "high"), a resolution ("720p", "1080p"), or a bitrage ("2500k"). Default "high".

.PARAMETER ShowWindow
Optional. Show the TubeDigger UI instead of starting minimized to the system tray.

.PARAMETER Unmute
Optional. Start TubeDigger unmuted.

.PARAMETER TempDir
Optional. A path to temporarily store recordings when using OutputDir and/or OutputBaseName. Defaults to the Windows temp path for your user account.

.PARAMETER FixContainer
Optional. Requires ffmpeg. Use with -Mode dl to copy the video and audio streams into an mp4 container, which may help fix playback issues.

.EXAMPLE
.\InvokeTubeDigger.ps1 -Url 'https://example.com/live-stream' -DurationSec (60 * 30) -OutputDir 'C:\Videos' -OutputBaseName 'ExampleStream' -ReContainer -ShowWindow

.NOTES
Requires a registered version of TubeDigger to be installed at the default location.

TubeDigger configurations may affect the usability of this script. The TubeDigger CLI does not expose all options available from the UI.

If dl mode does not work, try deselecting 'Detect all resolutions/bitrates of video' in settings.

The -ReContainer switch requires ffmpeg to be executable from the working directory (i.e., in a directory configured in your PATH environment variable)

In dl mode, recordings may never finish if the source streams an infinite loop for "on-demand" viewing.

.LINK
https://www.tubedigger.com/

.LINK
https://www.gyan.dev/ffmpeg/builds/
#>
