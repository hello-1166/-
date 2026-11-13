param(
    [ValidateRange(60, 1800)]
    [int]$WaitTimeout = 300
)
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$stage = "Docker engine"

Push-Location $ProjectRoot
try {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI not found. Install and start Docker Desktop first."
    }
    $engineText = docker info --format '{{json .}}'
    if ($LASTEXITCODE -ne 0) {
        throw "Docker engine unavailable. Start Docker Desktop and wait until it is running."
    }
    $engine = $engineText | ConvertFrom-Json
    if ($engine.OSType -ne "linux") {
        throw "Linux containers are required. Switch Docker Desktop to Linux containers."
    }
    Write-Host "Docker engine ready. Storage driver: $($engine.Driver)"
    if ($engine.Driver -eq "vfs") {
        Write-Warning "VFS copies image layers and needs extra space and inodes. See docs/N8N_TROUBLESHOOTING.md."
    }

    $stage = "Docker Compose"
    docker compose version
    if ($LASTEXITCODE -ne 0) { throw "Docker Compose v2 is required." }

    $stage = "Local configuration"
    if (-not (Test-Path (Join-Path $ProjectRoot ".env"))) {
        & (Join-Path $PSScriptRoot "init_env.ps1")
    }
    docker compose config --quiet
    if ($LASTEXITCODE -ne 0) { throw "Compose configuration failed. Check your local .env." }

    $stage = "n8n image download"
    docker compose pull n8n
    if ($LASTEXITCODE -ne 0) {
        throw "n8n image download failed. Check the Docker error and the troubleshooting guide."
    }

    $stage = "API image build"
    docker compose build api
    if ($LASTEXITCODE -ne 0) {
        throw "API image build failed. Check the build error and the troubleshooting guide."
    }

    $stage = "Service startup and health checks"
    docker compose up -d --no-build --wait --wait-timeout $WaitTimeout
    if ($LASTEXITCODE -ne 0) {
        throw "Services did not become healthy. Run docker compose ps and inspect n8n logs locally."
    }

    $stage = "Smoke tests"
    & (Join-Path $PSScriptRoot "smoke_test.ps1")
    Write-Host "P0 startup checks passed."
    Write-Host "n8n: http://localhost:5678"
    Write-Host "API docs: http://localhost:8000/docs"
} catch {
    Write-Host "P0 startup stopped at: $stage"
    Write-Host "Troubleshooting: docs/N8N_TROUBLESHOOTING.md"
    throw
} finally {
    Pop-Location
}
