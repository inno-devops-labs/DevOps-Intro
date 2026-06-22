# Lab 5 — one-shot runner. Run in an ADMIN PowerShell (Hyper-V + netsh need it).
#   powershell -ExecutionPolicy Bypass -File submissions\lab5-run.ps1
# Saves the full transcript to submissions\lab5-run.txt.
$ErrorActionPreference = 'Continue'
$repo = 'C:\study\DEVOPS\DevOps-Intro'
$log  = Join-Path $repo 'submissions\lab5-run.txt'
Set-Location $repo
Remove-Item $log -ErrorAction SilentlyContinue
function Sec($t){ "`n========== $t ==========" | Tee-Object -FilePath $log -Append }

Sec "vagrant destroy + up (hyperv)"
vagrant destroy -f 2>&1 | Tee-Object -FilePath $log -Append
vagrant up --provider=hyperv 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 1 verify -- guest: go version"
vagrant ssh -c "/usr/local/go/bin/go version" 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 1 verify -- guest: service + curl /health (inside VM)"
vagrant ssh -c "systemctl is-active quicknotes; curl -s localhost:8080/health" 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 1 verify -- host: portproxy 127.0.0.1:18080 -> guest:8080"
$ip = ((vagrant ssh-config | Select-String 'HostName').ToString().Trim() -split '\s+')[-1]
"guest IP = $ip" | Tee-Object -FilePath $log -Append
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=18080 2>$null | Out-Null
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=18080 connectaddress=$ip connectport=8080 2>&1 | Tee-Object -FilePath $log -Append
Start-Sleep -Seconds 1
"host curl 127.0.0.1:18080/health =>" | Tee-Object -FilePath $log -Append
(curl.exe -s http://127.0.0.1:18080/health) 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 2 -- snapshot save 'clean-baseline'"
vagrant snapshot save clean-baseline 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 2 -- BREAK (wipe Go + binary + stop service)"
vagrant ssh -c "sudo rm -rf /usr/local/go /usr/local/bin/quicknotes; sudo systemctl stop quicknotes; echo BROKEN" 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 2 -- verify broken"
vagrant ssh -c "/usr/local/go/bin/go version 2>&1 || echo GO_GONE; curl -s -m 3 localhost:8080/health || echo HEALTH_DOWN" 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 2 -- snapshot restore (timed)"
$t = Measure-Command { vagrant snapshot restore clean-baseline 2>&1 | Tee-Object -FilePath $log -Append }
"RESTORE_SECONDS = $([math]::Round($t.TotalSeconds,1))" | Tee-Object -FilePath $log -Append

Sec "TASK 2 -- verify recovered"
vagrant ssh -c "/usr/local/go/bin/go version; systemctl is-active quicknotes; curl -s localhost:8080/health" 2>&1 | Tee-Object -FilePath $log -Append

Sec "DONE - results saved to submissions/lab5-run.txt"
