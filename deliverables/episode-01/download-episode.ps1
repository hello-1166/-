param(
 [Parameter(Mandatory=$true)][string]$PackageUrl,
 [Parameter(Mandatory=$true)][string]$KeyBase64,
 [string]$OutputDirectory = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'AI-Radar-Episode-01')
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$null = New-Item -ItemType Directory -Force -Path $OutputDirectory
$encryptedPath = Join-Path $OutputDirectory 'episode-01.radarenc'
Invoke-WebRequest -UseBasicParsing -Uri $PackageUrl -OutFile $encryptedPath
if ((Get-FileHash $encryptedPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne '36e554de6ca4419380a69a81ff794540d2105c5e88af7e13d826ba926bd49df4') { throw 'Downloaded package checksum mismatch.' }
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
$zip = Join-Path $OutputDirectory 'fredtalk-ab397345-return.zip'
[IO.File]::WriteAllBytes($zip,$plain)
if ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'd4bd6165b4272c379bdcb5e51a5c4385fd6c45357d83883f4f666c5e78374c29') { throw 'Decrypted ZIP checksum mismatch.' }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
try {
 $entry = $archive.GetEntry('video.mp4')
 if ($null -eq $entry) { throw 'Missing video.mp4' }
 [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,(Join-Path $OutputDirectory 'video.mp4'),$true)
} finally { $archive.Dispose() }
Write-Host ('Ready: '+$zip)
Write-Host ('Video: '+(Join-Path $OutputDirectory 'video.mp4'))
Start-Process explorer.exe -ArgumentList $OutputDirectory
