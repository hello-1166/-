param(
 [Parameter(Mandatory=$true)][string]$PackageUrl,
 [string]$ProjectPath='F:\github1113\AI_Frontier_Radar_P0',
 [string]$IndexTTSRoot='F:\AI_Tools\IndexTTS-2.5-fast'
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$ProgressPreference='SilentlyContinue'
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath 'docker-compose.yml'))) {
 throw 'Original Radar folder not found. Set -ProjectPath to your existing project.'
}
if (-not (Test-Path -LiteralPath (Join-Path $IndexTTSRoot '.venv/Scripts/python.exe'))) {
 throw 'Installed IndexTTS environment not found. Set -IndexTTSRoot. No model reinstall is needed.'
}
$Download=[Uri]$PackageUrl
if ($Download.Scheme -ne 'https' -or $Download.Host -ne 'raw.githubusercontent.com' -or
    -not $Download.AbsolutePath.StartsWith('/hello-1166/-/')) {
 throw 'Use the pinned GitHub raw release URL.'
}
# Do not start a second model instance. Stop the old window before installing.
$Socket=New-Object Net.Sockets.TcpClient
$Listening=$false
try {
 $Attempt=$Socket.BeginConnect('127.0.0.1',7860,$null,$null)
 if ($Attempt.AsyncWaitHandle.WaitOne(1000)) {
  try { $Socket.EndConnect($Attempt); $Listening=$Socket.Connected } catch { }
 }
} finally { $Socket.Close() }
if ($Listening) { throw 'Stop the old IndexTTS window using Ctrl+C, then rerun this same command.' }
$Worker=New-Object Threading.Mutex($false,'Local\AIFrontierRadarVideoWorker')
$WorkerFree=$false
try { $WorkerFree=$Worker.WaitOne(0) } catch [Threading.AbandonedMutexException] { $WorkerFree=$true }
if ($WorkerFree) { $Worker.ReleaseMutex() }
$Worker.Dispose()
if (-not $WorkerFree) { throw 'Stop the old video_worker.ps1 window using Ctrl+C, then rerun this command.' }
$Temporary=Join-Path $env:TEMP ('radar-indextts-upgrade-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Temporary | Out-Null
$Archive=Join-Path $Temporary 'radar-indextts-upgrade.zip'
Write-Host '[1/4] Downloading small integration package; model weights are unchanged...'
Invoke-WebRequest -UseBasicParsing -Uri $PackageUrl -OutFile $Archive -TimeoutSec 120
$Expected='0bb6fb542562bd5b4fe9a999d9271a117f4c5d35e0d14410ea5c74031dac5bad'
if ((Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Expected) {
 throw 'Upgrade ZIP checksum failed. No project files changed.'
}
Expand-Archive -LiteralPath $Archive -DestinationPath $Temporary
Write-Host '[2/4] Backing up and upgrading Radar code; preserving existing local data...'
& (Join-Path $Temporary 'AI_Frontier_Radar_P6/scripts/upgrade_p6.ps1') -ExistingProjectPath $ProjectPath
& (Join-Path $ProjectPath 'scripts/setup_indextts_bridge.ps1') -IndexTTSRoot $IndexTTSRoot
Write-Host '[3/4] Rebuilding the Radar API only. Existing n8n data is preserved...'
Push-Location $ProjectPath
try {
 docker compose config --quiet
 if ($LASTEXITCODE -ne 0) { throw 'Compose configuration is invalid. Existing .env was not changed.' }
 docker compose build api
 if ($LASTEXITCODE -ne 0) { throw 'API build failed. Fix the reported build error and rerun this installer.' }
 docker compose up -d --no-deps --wait --wait-timeout 120 api
 if ($LASTEXITCODE -ne 0) { throw 'API startup failed. Inspect docker compose logs api.' }
 $Status=Invoke-RestMethod -Uri 'http://127.0.0.1:8000/api/v1/videos/status' -TimeoutSec 20
 if (@($Status.voice_modes) -notcontains 'indextts_local') { throw 'API has not loaded the new voice integration.' }
} finally { Pop-Location }
Write-Host '[4/4] Starting the local IndexTTS WebUI and the video worker in separate windows...'
$ModelScript=Join-Path $ProjectPath 'scripts/start_indextts.ps1'
$WorkerScript=Join-Path $ProjectPath 'scripts/video_worker.ps1'
Start-Process powershell.exe -WorkingDirectory $ProjectPath -ArgumentList (
 '-NoProfile -ExecutionPolicy Bypass -NoExit -File "'+$ModelScript+'" -IndexTTSRoot "'+$IndexTTSRoot+'"')
Start-Process powershell.exe -WorkingDirectory $ProjectPath -ArgumentList (
 '-NoProfile -ExecutionPolicy Bypass -NoExit -File "'+$WorkerScript+'" -IndexTTSRoot "'+$IndexTTSRoot+'"')
Write-Host ''
Write-Host 'Wait for IndexTTS to show http://127.0.0.1:7860, then save a voice preset there.'
Write-Host 'Open http://localhost:8000/videos ; choose IndexTTS in the task voice settings and enter that preset name.'
Write-Host 'Save the settings, then add the task to the automatic queue. Preview before publishing.'
Write-Host "Installer package retained for review at: $Temporary"
