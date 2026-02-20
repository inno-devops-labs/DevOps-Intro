
# Lab 3 — CI/CD (GitHub Actions)

Platform: GitHub Actions

## Task 1 — First workflow + push trigger
Run link: https://github.com/vizitei-dmitri/DevOps-Intro/actions/runs/22235770166
Key concepts:
- Workflow file: `.github/workflows/lab3.yml`
- Jobs: `basic-info`, `system-info`
- Runner: `ubuntu-latest`
- Trigger: push to `feature/lab3`

What triggered it:
- A commit pushed to `feature/lab3`

## Workflow file (`.github/workflows/lab3.yml`)
```yaml
name: Lab 3 CI

on:
  push:
    branches: [ "feature/lab3" ]
  workflow_dispatch:

jobs:
  basic-info:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Basic info
        run: |
          echo "Triggered by: ${{ github.event_name }}"
          echo "Branch: ${{ github.ref }}"
          echo "Commit: ${{ github.sha }}"
          date
          pwd
          ls -la

  system-info:
    runs-on: ubuntu-latest
    steps:
      - name: System info
        run: |
          uname -a
          nproc
          free -h
          df -h

## Task 2 — Manual trigger + system information
Manual run link: 
https://github.com/vizitei-dmitri/DevOps-Intro/actions/runs/22236576033
System info log snippet:
```text
uname -a
  nproc
  free -h
  df -h
  shell: /usr/bin/bash -e {0}
Linux runnervmwffz4 6.11.0-1018-azure #18~24.04.1-Ubuntu SMP Sat Jun 28 04:46:03 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
4
               total        used        free      shared  buff/cache   available
Mem:            15Gi       914Mi        13Gi        35Mi       1.8Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   53G   92G  37% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G 1008K  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   29K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   62M  758M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           1.6G   12K  1.6G   1% /run/user/1001


