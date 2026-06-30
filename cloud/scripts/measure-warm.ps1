# Lab 10 — measure warm latency (PowerShell). Usage:
#   .\cloud\scripts\measure-warm.ps1 -Url "https://user-space.hf.space/health"

param(
    [Parameter(Mandatory = $true)][string]$Url,
    [int]$Runs = 5
)

$times = @()
1..$Runs | ForEach-Object {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 120 | Out-Null
    } catch {
        Write-Error "Request failed: $_"
    }
    $sw.Stop()
    $t = $sw.Elapsed.TotalSeconds
    $times += $t
    Write-Host ("  run {0}: {1:N3}s" -f $_, $t)
}

$sorted = $times | Sort-Object
$mid = [math]::Floor($sorted.Count / 2)
if ($sorted.Count % 2 -eq 1) {
    $p50 = $sorted[$mid]
} else {
    $p50 = ($sorted[$mid - 1] + $sorted[$mid]) / 2
}
$p95 = $sorted[[math]::Ceiling($sorted.Count * 0.95) - 1]
Write-Host ("p50: {0:N3}s" -f $p50)
Write-Host ("p95: {0:N3}s" -f $p95)
