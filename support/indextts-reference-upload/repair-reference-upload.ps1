param(
 [Parameter(Mandatory=$true)][string]$BaseUrl,
 [string]$ProjectPath='F:\AI_Tools\IndexTTS-2.5-fast'
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$ProgressPreference='SilentlyContinue'
$Python=Join-Path $ProjectPath '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $Python)) { throw ('Installed environment not found: '+$Python) }
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath 'webui.py'))) { throw 'IndexTTS WebUI was not found.' }
$TempDirectory=Join-Path $env:TEMP ('radar-reference-fix-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $TempDirectory
$Hashes=@{
 'radar_reference_upload.py'='156d1cee6e8b2d4c4ba053d550689981ecc07da9366dd04e1d3fd1117f1dbc09'
 'patch_upload.py'='5d2a64aa199fe6e810516741760993f97d08fcd9015f964fd0ac70c4a608ef03'
}
foreach ($Name in $Hashes.Keys) {
 $LocalFile=Join-Path $TempDirectory $Name
 Invoke-WebRequest -UseBasicParsing -Uri ($BaseUrl.TrimEnd('/')+'/'+$Name) -OutFile $LocalFile -TimeoutSec 120
 if ((Get-FileHash -LiteralPath $LocalFile -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Hashes[$Name]) { throw ('Download checksum mismatch: '+$Name) }
}
$Helper=Join-Path $ProjectPath 'radar_reference_upload.py'
if ((Test-Path -LiteralPath $Helper) -and ((Get-FileHash -LiteralPath $Helper -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Hashes['radar_reference_upload.py'])) { throw 'An existing custom reference helper was found; no files were overwritten.' }
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
 Write-Host 'Preparing a bundled FFmpeg decoder for local audio conversion...'
 uv pip install --python $Python imageio-ffmpeg==0.6.0 --default-index https://mirrors.aliyun.com/pypi/simple
 if ($LASTEXITCODE -ne 0) { throw 'Audio decoder installation failed; WebUI was not changed.' }
}
Copy-Item -LiteralPath (Join-Path $TempDirectory 'radar_reference_upload.py') -Destination $Helper -Force
& $Python (Join-Path $TempDirectory 'patch_upload.py') $ProjectPath
if ($LASTEXITCODE -ne 0) { throw 'Reference-upload patch was not applied. Keep the error output for diagnosis.' }
$env:USE_MODELSCOPE='true'
Push-Location $ProjectPath
try {
 Write-Host 'Open http://127.0.0.1:7860 and refresh. Use the new compatible-upload box below the original audio box.'
 & $Python webui.py --version 2.5 --host 127.0.0.1 --port 7860 --fp16
 if ($LASTEXITCODE -ne 0) { throw 'WebUI stopped with an error; inspect the output above.' }
} finally { Pop-Location }
