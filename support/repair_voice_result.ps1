param([string]$ArchivePath = "")
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-not $ArchivePath) {
    Add-Type -AssemblyName System.Windows.Forms
    $Picker = New-Object System.Windows.Forms.OpenFileDialog
    $Picker.Filter = "Voice ZIP (*.zip)|*.zip"
    $Picker.Title = "Select voice-result-b70fd5f1.zip"
    if ($Picker.ShowDialog() -ne "OK") { return }
    $ArchivePath = $Picker.FileName
}
$ArchivePath = (Resolve-Path -LiteralPath $ArchivePath).Path
$Fixed = Join-Path (Split-Path -Parent $ArchivePath) ('voice-result-fixed-' + [Guid]::NewGuid().ToString('N').Substring(0,8) + '.zip')
Copy-Item -LiteralPath $ArchivePath -Destination $Fixed
$Zip = [IO.Compression.ZipFile]::Open($Fixed, [IO.Compression.ZipArchiveMode]::Update)
try {
    $ManifestEntry = $Zip.GetEntry('voice-manifest.json')
    if (-not $ManifestEntry) { throw 'Missing manifest.' }
    $Reader = New-Object IO.StreamReader($ManifestEntry.Open())
    try { $Manifest = $Reader.ReadToEnd() | ConvertFrom-Json } finally { $Reader.Dispose() }
    $Chunk = @($Manifest.chunks | Where-Object { $_.file -eq 's02-c007.wav' })
    $Entry = $Zip.GetEntry('s02-c007.wav')
    if ($Manifest.job_id -ne 'd25114a7e48240c9ad31b355c7f8fdb0' -or $Chunk.Count -ne 1 -or
        $Chunk[0].text -match '[\p{L}\p{N}]' -or -not $Entry -or $Entry.Length -ne 46) {
        throw 'This is not the original ZIP inspected for this task. No original files changed.'
    }
    $Memory = New-Object IO.MemoryStream
    $ReadStream = $Entry.Open()
    try { $ReadStream.CopyTo($Memory) } finally { $ReadStream.Dispose() }
    $Hex = [BitConverter]::ToString($Memory.ToArray()).Replace('-','').ToLowerInvariant()
    $Memory.Dispose()
    if ($Hex -ne '524946462600000057415645666d74201200000001000100c05d000080bb00000200100000006461746100000000') {
        throw 'Unexpected WAV contents. Original ZIP kept.'
    }
    $Entry.Delete()
    $Stream = $Zip.CreateEntry('s02-c007.wav').Open()
    try {
        $Header = [Convert]::FromBase64String('UklGRqQWAABXQVZFZm10IBAAAAABAAEAwF0AAIC7AAACABAAZGF0YYAWAAA=')
        $Stream.Write($Header, 0, $Header.Length)
        $Silence = New-Object byte[] 5760
        $Stream.Write($Silence, 0, $Silence.Length)
    } finally { $Stream.Dispose() }
} finally { $Zip.Dispose() }
Write-Host 'Fixed ZIP created. Import this file into the SAME video task:'
Write-Host $Fixed
