# Lab 5 Bonus — VM resource baseline. Run in an ADMIN PowerShell (Hyper-V needs it).
#   powershell -ExecutionPolicy Bypass -File submissions\lab5-bonus-vm.ps1
# Saves to submissions\lab5-bonus-vm.txt.
$ErrorActionPreference = 'Continue'
$repo = 'C:\study\DEVOPS\DevOps-Intro'
$log  = Join-Path $repo 'submissions\lab5-bonus-vm.txt'
Set-Location $repo
Remove-Item $log -ErrorAction SilentlyContinue
function L($m){ $m | Tee-Object -FilePath $log -Append }

L "### cold boot: vagrant halt, then timed vagrant up (boot only, already provisioned)"
vagrant halt 2>&1 | Tee-Object -FilePath $log -Append
$t = Measure-Command { vagrant up 2>&1 | Tee-Object -FilePath $log -Append }
L ("BOOT_SECONDS = {0}" -f [math]::Round($t.TotalSeconds,1))

L "### idle RAM (free -h)"
vagrant ssh -c "free -h" 2>&1 | Tee-Object -FilePath $log -Append

L "### process count (ps -A | wc -l)"
vagrant ssh -c "ps -A --no-headers | wc -l" 2>&1 | Tee-Object -FilePath $log -Append

L "### VM disk image size (diff + parent chain)"
try {
  $disk  = (Get-VM quicknotes-vm | Get-VMHardDiskDrive).Path
  $vhd   = Get-VHD $disk
  $total = $vhd.FileSize
  $p     = $vhd.ParentPath
  while ($p) { $pv = Get-VHD $p; $total += $pv.FileSize; $p = $pv.ParentPath }
  L ("VM_DISK_GB = {0}  (disk: {1})" -f [math]::Round($total/1GB,2), $disk)
} catch { L "VHD size error: $_" }

L "### DONE - results in submissions/lab5-bonus-vm.txt"
