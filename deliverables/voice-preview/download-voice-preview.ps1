param(
 [Parameter(Mandatory=$true)][string]$PackageUrl,
 [Parameter(Mandatory=$true)][string]$KeyBase64,
 [string]$OutputDirectory = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'AI-Radar-Voice-Preview')
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$null = New-Item -ItemType Directory -Force -Path $OutputDirectory
$encryptedPath = Join-Path $OutputDirectory 'yunxi-preview.radarenc'
Invoke-WebRequest -UseBasicParsing -Uri $PackageUrl -OutFile $encryptedPath
if ((Get-FileHash $encryptedPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'eb64314c14ca52eab243311af389dc81bc72c7740e8b58cecf045591abc533af') { throw 'Downloaded package checksum mismatch.' }
$key = [Convert]::FromBase64String($KeyBase64)
if ($key.Length -ne 64) { throw 'Invalid key length.' }
$bytes = [IO.File]::ReadAllBytes($encryptedPath)
$auth = New-Object Security.Cryptography.HMACSHA256
$auth.Key = [byte[]]$key[32..63]
$tag = $auth.ComputeHash($bytes, 0, $bytes.Length - 32)
$difference = 0
for ($i=0; $i -lt 32; $i++) { $difference = $difference -bor ($tag[$i] -bxor $bytes[$bytes.Length-32+$i]) }
$auth.Dispose()
if ($difference -ne 0) { throw 'Package authentication failed.' }
$aes = [Security.Cryptography.Aes]::Create()
$aes.Key = [byte[]]$key[0..31]
$aes.IV = [byte[]]$bytes[8..23]
$aes.Mode = [Security.Cryptography.CipherMode]::CBC
$aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
$decryptor = $aes.CreateDecryptor()
try { $plain = $decryptor.TransformFinalBlock($bytes,24,$bytes.Length-56) }
finally { $decryptor.Dispose(); $aes.Dispose() }
$sample = Join-Path $OutputDirectory 'yunxi-preview.mp3'
[IO.File]::WriteAllBytes($sample,$plain)
if ((Get-FileHash $sample -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'c63c9947fe200a04cf3b423a7df437321453867fe7cf289fe2776ecd674090b3') { throw 'Sample checksum mismatch.' }
Write-Host ('Ready: '+$sample)
Start-Process -FilePath $sample
Start-Process explorer.exe -ArgumentList $OutputDirectory
