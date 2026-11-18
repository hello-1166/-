param(
    [Parameter(Mandatory=$true)][string]$PackageUrl,
    [string]$InstallParent = 'F:\AI_Tools'
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
$ExpectedHash = 'd64897609637d50f30ecb72e30999e57300bb42f16f6400dd6de6ee7b3da326d'
$UvCommand = Get-Command uv -ErrorAction SilentlyContinue
if (-not $UvCommand) { throw 'uv was not found. Install it with: winget install --id astral-sh.uv -e ; then open a new PowerShell window.' }
$UvExe = $UvCommand.Source
$Project = Join-Path $InstallParent 'IndexTTS-2.5-fast'
$ArchivePath = Join-Path $env:TEMP 'IndexTTS-2.5-fast-d6489760.zip'
Write-Host '[1/4] Downloading verified minimal source package (0.90 MiB)...'
$ArchiveReady = (Test-Path -LiteralPath $ArchivePath) -and ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant() -eq $ExpectedHash)
if (-not $ArchiveReady) { Invoke-WebRequest -UseBasicParsing -Uri $PackageUrl -OutFile $ArchivePath -TimeoutSec 300 }
if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedHash) { throw 'Source package checksum mismatch; extraction stopped.' }
$SourceMarker = Join-Path $Project 'SOURCE_HASHES.json'
if (Test-Path -LiteralPath $Project) {
    if (-not (Test-Path -LiteralPath $SourceMarker)) { throw ('Target directory already exists without this package marker: '+$Project) }
} else {
    $null = New-Item -ItemType Directory -Path $InstallParent -Force
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $InstallParent
}
$Manifest = Get-Content -LiteralPath $SourceMarker -Raw | ConvertFrom-Json
foreach ($Record in $Manifest) {
    $LocalFile = Join-Path $Project $Record.path
    if (-not (Test-Path -LiteralPath $LocalFile)) { throw ('Missing source file: '+$Record.path) }
    if ($Record.path -eq 'uv.lock') { continue } # uv may update registry URLs during a previous interrupted mirror sync.
    if ((Get-FileHash -LiteralPath $LocalFile -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Record.sha256) { throw ('Existing file differs; no overwrite performed: '+$Record.path) }
}
Write-Host ('Source ready: '+$Project)
Write-Host 'Upstream license and packaging notice: LICENSE / PACKAGING_NOTICE.md'
Write-Host '[2/4] Installing Python 3.10 and WebUI dependencies. Large PyTorch downloads are separate from the source package.'
$env:UV_HTTP_TIMEOUT = '300'
$env:USE_MODELSCOPE = 'true'
Push-Location $Project
try {
    & $UvExe sync --python 3.10 --extra webui --default-index https://mirrors.aliyun.com/pypi/simple
    if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed; keep this output and rerun after resolving the reported error.' }
    Write-Host '[3/4] Checking CUDA and RTX GPU...'
    & $UvExe run --no-sync python -c 'import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else None); raise SystemExit(0 if torch.cuda.is_available() else 1)'
    if ($LASTEXITCODE -ne 0) { throw 'PyTorch GPU check failed; WebUI was not started.' }
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { Write-Host 'FFmpeg is not on PATH. If audio decoding fails, install: winget install --id Gyan.FFmpeg -e' }
    Write-Host '[4/4] Starting IndexTTS 2.5 at http://127.0.0.1:7860'
    Write-Host 'Initial model/example downloads use upstream ModelScope mode. Keep this window open.'
    & $UvExe run --no-sync webui.py --version 2.5 --host 127.0.0.1 --port 7860 --fp16
    if ($LASTEXITCODE -ne 0) { throw 'WebUI stopped with an error; inspect the messages above.' }
} finally { Pop-Location }
