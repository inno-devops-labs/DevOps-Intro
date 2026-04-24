param(
    [ValidateSet("All", "Traditional", "Wasm")]
    [string]$Mode = "All",
    [switch]$KeepServer,
    [switch]$Rebuild
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Ensure-Docker {
    docker version | Out-Null
}

function Ensure-Builder {
    $builderName = "lab12builder"
    $builders = docker buildx ls
    if (-not ($builders | Select-String -SimpleMatch $builderName)) {
        docker buildx create --name $builderName --driver docker-container | Out-Null
    }
    return $builderName
}

function Show-FileSize {
    param([string]$Path)
    $file = Get-Item -LiteralPath $Path
    $sizeMiB = [math]::Round($file.Length / 1MB, 3)
    Write-Host "$($file.Name): $($file.Length) bytes ($sizeMiB MiB)"
}

function Run-TraditionalDemo {
    Write-Step "Build traditional image"
    docker build -t moscow-time-traditional -f Dockerfile .

    Write-Step "Traditional image size"
    docker images moscow-time-traditional --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
    $imageBytes = docker image inspect moscow-time-traditional --format "{{.Size}}"
    Write-Host "Exact image size: $imageBytes bytes"

    Write-Step "CLI mode"
    docker run --rm -e MODE=once moscow-time-traditional

    Write-Step "Server mode"
    $existing = docker ps -a --format "{{.Names}}" | Select-String -SimpleMatch "test-traditional"
    if ($existing) {
        docker rm -f test-traditional | Out-Null
    }
    $containerId = docker run -d --rm --name test-traditional -p 8080:8080 moscow-time-traditional
    Start-Sleep -Seconds 2

    Write-Host "Container ID: $containerId"
    Write-Host "Open in browser: http://localhost:8080"
    Write-Host "API endpoint:     http://localhost:8080/api/time"
    Write-Host "API response:"
    curl.exe -s http://localhost:8080/api/time

    if ($KeepServer) {
        Write-Host ""
        Write-Host "The server is still running in container 'test-traditional'."
        Write-Host "Stop it later with: docker stop test-traditional"
    }
    else {
        docker stop test-traditional | Out-Null
    }
}

function Run-WasmDemo {
    Write-Step "Build main.wasm"
    if ($Rebuild -or -not (Test-Path -LiteralPath ".\main.wasm")) {
        docker run --rm -v "${PWD}:/src" -w /src tinygo/tinygo:0.39.0 tinygo build -o main.wasm -target=wasi main.go
    }
    Show-FileSize ".\main.wasm"

    Write-Step "Export WASM OCI archive"
    $builderName = Ensure-Builder
    if ($Rebuild -and (Test-Path -LiteralPath ".\moscow-time-wasm.oci")) {
        Remove-Item -LiteralPath ".\moscow-time-wasm.oci" -Force
    }
    docker buildx build `
        --builder $builderName `
        --platform=wasi/wasm `
        -t moscow-time-wasm:latest `
        -f Dockerfile.wasm `
        --output=type=oci,dest=moscow-time-wasm.oci,annotation=index:org.opencontainers.image.ref.name=moscow-time-wasm:latest `
        .
    Show-FileSize ".\moscow-time-wasm.oci"

    Write-Step "Import into containerd and show ctr metadata"
    $importCommand = 'apk add --no-cache containerd-ctr >/dev/null && ctr --address /run/containerd/containerd.sock -n lab12 images import --platform wasi/wasm --index-name docker.io/library/moscow-time-wasm:latest /src/moscow-time-wasm.oci && echo && ctr --address /run/containerd/containerd.sock -n lab12 images ls | grep "moscow-time-wasm"'
    docker run --rm -v /run/containerd:/run/containerd -v "${PWD}:/src" alpine:3.20 sh -lc $importCommand

    Write-Host ""
    Write-Host "The current host can build and import the WASM image."
    Write-Host "It cannot complete 'ctr run' here because Docker Desktop does not expose a usable wasmtime shim."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptDir

try {
    Ensure-Docker

    switch ($Mode) {
        "Traditional" { Run-TraditionalDemo }
        "Wasm" { Run-WasmDemo }
        "All" {
            Run-TraditionalDemo
            Run-WasmDemo
        }
    }
}
finally {
    Pop-Location
}
