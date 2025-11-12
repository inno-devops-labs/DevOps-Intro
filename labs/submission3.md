# Lab 3 — CI/CD with GitHub Actions (Submission)

## Task 1

### What I did
- Created branch `feature/lab3`.
- Added a minimal push-triggered workflow and pushed to run it.

### Evidence
- **Successful run link (push): https://github.com/NoNesmer/F25-DevOps-Intro/actions/runs/17919233276**
- **Log snippet (key lines from “Print context” step):**
  ```text
  My logs for task1:
Run echo "👋 Hello from Lab 3 — Quickstart"
👋 Hello from Lab 3 — Quickstart
Triggered by: push
Actor: NoNesmer
Ref: refs/heads/feature/lab3
SHA: f72047a1b0b8c38aa89a709a9a8e3b3d6e4fd655

## Task 1

### What I did
- Added workflow-dispatch to enable manual runs
- Added a step to gather OS/CPU/memory/disk info and upload system-info.txt as an artifact

### Evidence
- **Manual run link: https://github.com/NoNesmer/F25-DevOps-Intro/actions/runs/17920488865**
- Artifact (downloaded from the run page):
# Runner system information
Collected at (UTC): 2025-09-22T15:35:21Z
Runner.OS: Linux
Runner.Name: GitHub Actions 1000000006
Runner.Arch: x86_64

## OS release
PRETTY_NAME="Ubuntu 24.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.3 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo

## Kernel
Linux runnervmf4ws1 6.11.0-1018-azure #18~24.04.1-Ubuntu SMP Sat Jun 28 04:46:03 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux

## CPU
Architecture:                         x86_64
CPU op-mode(s):                       32-bit, 64-bit
Address sizes:                        48 bits physical, 48 bits virtual
Byte Order:                           Little Endian
CPU(s):                               4
On-line CPU(s) list:                  0-3
Vendor ID:                            AuthenticAMD
Model name:                           AMD EPYC 7763 64-Core Processor
CPU family:                           25
Model:                                1
Thread(s) per core:                   2
Core(s) per socket:                   2
Socket(s):                            1
Stepping:                             1
BogoMIPS:                             4890.85
Flags:                                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl tsc_reliable nonstop_tsc cpuid extd_apicid aperfmperf tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm cmp_legacy svm cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw topoext vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves user_shstk clzero xsaveerptr rdpru arat npt nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold v_vmsave_vmload umip vaes vpclmulqdq rdpid fsrm
Virtualization:                       AMD-V
Hypervisor vendor:                    Microsoft
Virtualization type:                  full
L1d cache:                            64 KiB (2 instances)
L1i cache:                            64 KiB (2 instances)
L2 cache:                             1 MiB (2 instances)
L3 cache:                             32 MiB (1 instance)
NUMA node(s):                         1
NUMA node0 CPU(s):                    0-3
Vulnerability Gather data sampling:   Not affected
Vulnerability Itlb multihit:          Not affected
Vulnerability L1tf:                   Not affected
Vulnerability Mds:                    Not affected
Vulnerability Meltdown:               Not affected
Vulnerability Mmio stale data:        Not affected
Vulnerability Reg file data sampling: Not affected
Vulnerability Retbleed:               Not affected
Vulnerability Spec rstack overflow:   Vulnerable: Safe RET, no microcode
Vulnerability Spec store bypass:      Vulnerable
Vulnerability Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointer sanitization
Vulnerability Spectre v2:             Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected
Vulnerability Srbds:                  Not affected
Vulnerability Tsx async abort:        Not affected

## Memory
               total        used        free      shared  buff/cache   available
Mem:            15Gi       778Mi        13Gi        38Mi       1.5Gi        14Gi
Swap:          4.0Gi          0B       4.0Gi


### Manual vs automatic:

Automatic (push): runs on every push to matching branches; best for CI on each commit.

Manual (workflow_dispatch): started on demand from UI/API; good for ad-hoc checks/demos.

Both produce similar logs/artifacts; the difference is how they start.


### yaml:
name: Lab 3 — CI/CD Quickstart + System Info

on:
  push:
    branches:
      - '**'          # run on any branch push (including feature/lab3)
  workflow_dispatch:   # manual trigger from the Actions tab

jobs:
  quickstart:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Hello from GitHub Actions
        run: |
          echo "👋 Hello from ${{ github.workflow }}!"
          echo "Triggered by: ${{ github.event_name }}"
          echo "Actor: ${{ github.actor }}"
          echo "Branch/Ref: ${{ github.ref }}"
          echo "Commit SHA: ${{ github.sha }}"

      - name: Print environment summary
        run: |
          echo "Runner OS: ${{ runner.os }}"
          echo "Job: ${{ github.job }}"
          echo "Workflow run number: ${{ github.run_number }}"
          echo "Workflow run ID: ${{ github.run_id }}"

      - name: Gather system information
        id: sysinfo
        shell: bash
        run: |
          set -euxo pipefail
          {
            echo "# Runner system information"
            date -u +"Collected at (UTC): %Y-%m-%dT%H:%M:%SZ"
            echo "Runner.OS: ${{ runner.os }}"
            echo "Runner.Name: ${{ runner.name }}"
            echo "Runner.Arch: $(uname -m)"
            echo

            echo "## OS release"
            if [ -f /etc/os-release ]; then cat /etc/os-release; else sw_vers || systeminfo || ver || true; fi
            echo

            echo "## Kernel"
            uname -a || true
            echo

            echo "## CPU"
            (command -v lscpu >/dev/null && lscpu) || (sysctl -a 2>/dev/null | grep -iE 'brand|cpu\.(core|thread)|machdep.cpu' || true) || (wmic cpu get name,NumberOfCores,NumberOfLogicalProcessors || true)
            echo

            echo "## Memory"
            (free -h || vm_stat || (systeminfo | findstr /C:"Total Physical Memory") || true)
            echo

            echo "## Disk usage"
            df -h || true

            echo
            echo "## Tools"
            bash --version | head -n 1 || true
            python3 --version || true
            node --version || true
            npm --version || true
          } > system-info.txt
          echo "file=system-info.txt" >> "$GITHUB_OUTPUT"

      - name: Upload system-info artifact
        uses: actions/upload-artifact@v4
        with:
          name: system-info
          path: system-info.txt
          if-no-files-found: error
          retention-days: 7