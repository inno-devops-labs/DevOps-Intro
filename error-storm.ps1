# error-storm.ps1
# Generate a sustained >5% error ratio against QuickNotes so the
# QuickNotesHighErrorRate alert moves Inactive -> Pending -> Firing.
#
# Mix per second: 8 healthy GET /health (200) + 2 malformed POST /notes (400)
#   => ~20% error ratio, comfortably above the 5% threshold.
# Runs ~6 minutes so the 5m `for:` clause is satisfied with margin.
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\error-storm.ps1
# Adjust $base if your published port is not 8080.

$base = "http://localhost:8080"
$end  = (Get-Date).AddMinutes(6)

Write-Host "Firing mixed traffic at $base until $end (Ctrl+C to stop early)..."
while ((Get-Date) -lt $end) {
    1..8 | ForEach-Object { curl.exe -s -o NUL "$base/health" }
    1..2 | ForEach-Object {
        curl.exe -s -o NUL -X POST "$base/notes" -H "Content-Type: application/json" -d "{bad json"
    }
    Start-Sleep -Seconds 1
}
Write-Host "Done. Check http://localhost:9090/alerts for the Firing state."
