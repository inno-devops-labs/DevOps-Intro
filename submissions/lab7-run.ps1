# Lab 7 — run the Ansible deploy against the Lab 5 VM. ADMIN PowerShell.
#   powershell -ExecutionPolicy Bypass -File submissions\lab7-run.ps1
# Saves the transcript to submissions\lab7-run.txt.
$ErrorActionPreference = 'Continue'
$repo = 'C:\study\DEVOPS\DevOps-Intro'
$log  = Join-Path $repo 'submissions\lab7-run.txt'
Set-Location $repo
Remove-Item $log -ErrorAction SilentlyContinue
function Sec($t){ "`n========== $t ==========" | Tee-Object -FilePath $log -Append }

Sec "restore Vagrantfile (it lives on the feature/lab5 branch) so vagrant can drive the VM"
[IO.File]::WriteAllText((Join-Path $repo 'Vagrantfile'), ((git show feature/lab5:Vagrantfile) -join "`n"))
"Vagrantfile present: $(Test-Path (Join-Path $repo 'Vagrantfile'))" | Tee-Object -FilePath $log -Append

Sec "ensure VM up"
vagrant up 2>&1 | Tee-Object -FilePath $log -Append

Sec "clean any previous quicknotes install so Ansible deploys fresh"
vagrant ssh -c "sudo systemctl disable --now ansible-pull-quicknotes.timer 2>/dev/null; sudo systemctl disable --now quicknotes 2>/dev/null; sudo rm -rf /var/lib/quicknotes /etc/systemd/system/quicknotes.service /usr/local/bin/quicknotes; sudo userdel quicknotes 2>/dev/null; sudo systemctl daemon-reload; echo cleaned" 2>&1 | Tee-Object -FilePath $log -Append

Sec "install ansible + git in the VM, fetch the playbook"
vagrant ssh -c "sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-pip git >/dev/null 2>&1; sudo pip3 install -q 'ansible>=10,<11' 2>&1 | tail -2; ansible --version | head -1" 2>&1 | Tee-Object -FilePath $log -Append
vagrant ssh -c "rm -rf /tmp/qn && git clone -q -b feature/lab7 https://github.com/rikire/DevOps-Intro.git /tmp/qn && echo cloned" 2>&1 | Tee-Object -FilePath $log -Append

# Run Ansible on the VM, labelling the host 'lab5-vm' (connection local).
$PB = "cd /tmp/qn/ansible && sudo ansible-playbook -i inventory.local.ini playbook.yaml"

Sec "TASK 1 -- first run (deploy)"
vagrant ssh -c "$PB" 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 1 -- service active + /health (in the VM)"
vagrant ssh -c "systemctl is-active quicknotes; curl -s localhost:8080/health" 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 1 -- /health from the host via port forward (18080)"
$ip = ((vagrant ssh-config | Select-String 'HostName').ToString().Trim() -split '\s+')[-1]
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=18080 2>$null | Out-Null
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=18080 connectaddress=$ip connectport=8080 2>&1 | Out-Null
Start-Sleep -Seconds 1
"host curl 127.0.0.1:18080/health => $(curl.exe -s http://127.0.0.1:18080/health)" | Tee-Object -FilePath $log -Append

Sec "TASK 2 -- second run (idempotency, expect changed=0)"
vagrant ssh -c "$PB" 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 2 -- one-variable change: listen_addr=:9090 (template + handler only)"
vagrant ssh -c "$PB -e listen_addr=:9090" 2>&1 | Tee-Object -FilePath $log -Append

Sec "TASK 2 -- --check --diff: listen_addr=:9091"
vagrant ssh -c "$PB -e listen_addr=:9091 --check --diff" 2>&1 | Tee-Object -FilePath $log -Append

Sec "restore listen_addr :8080"
vagrant ssh -c "$PB" 2>&1 | Tee-Object -FilePath $log -Append

Sec "BONUS -- install ansible-pull service + timer in the VM"
vagrant ssh -c "sudo cp /tmp/qn/ansible/ansible-pull-quicknotes.service /tmp/qn/ansible/ansible-pull-quicknotes.timer /etc/systemd/system/ && sudo sed -i 's#-i ansible/inventory.local.ini#-i ansible/inventory.local.ini#' /etc/systemd/system/ansible-pull-quicknotes.service && sudo systemctl daemon-reload && sudo systemctl enable --now ansible-pull-quicknotes.timer && echo timer-installed" 2>&1 | Tee-Object -FilePath $log -Append

Sec "BONUS -- systemctl list-timers"
vagrant ssh -c "systemctl list-timers ansible-pull-quicknotes.timer --no-pager" 2>&1 | Tee-Object -FilePath $log -Append

Sec "BONUS -- trigger one pull now, show it reconciles the node"
vagrant ssh -c "sudo systemctl start ansible-pull-quicknotes.service; sleep 6; echo '--- deployed unit ADDR ---'; grep ADDR /etc/systemd/system/quicknotes.service; systemctl is-active quicknotes; journalctl -u ansible-pull-quicknotes.service --no-pager -n 3 | tail -3" 2>&1 | Tee-Object -FilePath $log -Append

Sec "DONE - results in submissions/lab7-run.txt"
