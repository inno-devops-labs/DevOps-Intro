# Lab 3 — CI/CD with GitHub Actions

**Student:** Kamilya Shakirova
**Date:** 20-02-2026

---

## Task 1 — First GitHub Actions Workflow (6 pts)
- [x] Link to the successful run (or screenshots).
- [x] Key concepts learned (jobs, steps, runners, triggers).
- [x] A short note on what caused the run to trigger.
- [x] Analysis of workflow execution process.


### 1.1 Follow GitHub Actions Quickstart
Created `.github/workflows/lab3.yml` with basic CI/CD pipeline:
``` sh
PS D:\Programs\DevOps-Intro> mkdir -p .github/workflows
    Каталог: D:\Programs\DevOps-Intro\.github
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        21.02.2026      1:52                workflows

PS D:\Programs\DevOps-Intro> New-Item -Path .github/workflows/lab3.yml -ItemType File
    Каталог: D:\Programs\DevOps-Intro\.github\workflows
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        21.02.2026      1:52              0 lab3.yml
```

### 1.2 Test Workflow Trigger

**Workflow Run #1:** https://github.com/Kamilya05/DevOps-Intro/actions/runs/22244425440

**Status:** Success

**Trigger:** `push` event (automatic when code was pushed to `feature/lab3`)

**Jobs Executed:** `Explore-GitHub-Actions` (5s)


### 1.3 Key Concepts Learned

**Workflows:** YAML-based automation files (`.github/workflows/lab3.yml`) that define CI/CD pipelines. Execute on specified events (push, pull requests, manual dispatch, scheduled times).

**Jobs:** Parallel execution units within a workflow. Each job runs on a separate runner instance. In our workflow:
- `Explore-GitHub-Actions` — shows you how GitHub Actions can work with the contents of your repository

**Steps:** Sequential commands/actions within a job. Types:
- `uses: actions/checkout@v5` — Clone repository code
- `run: |` — Execute shell commands (bash on Linux)

**Runners:** Virtual machines provided by GitHub. GitHub-hosted runners available:
- `ubuntu-latest` (Ubuntu 22.04)
- `windows-latest` (Windows Server 2022)
- `macos-latest` (macOS)

**Triggers:** Events that start workflows. Configured in `on:` section:
- `push:` — Automatic on commit (can filter by branch/tag/path)

### 1.4 Workflow Execution Process

1. **Event Detection:** GitHub detected `.github/workflows/lab3.yml` when commit was pushed to `feature/lab3`
2. **Queue & Allocate:** Workflow queued; GitHub allocated fresh Ubuntu runner
3. **Repository Checkout:** Runner cloned repository using `actions/checkout@v4`
4. **Job Execution:** `Explore-GitHub-Actions` job ran
5. **Step Execution:** Each step's `run:` commands executed sequentially
6. **Output Capture:** All stdout captured and displayed in Actions logs
7. **Success Status:** All steps passed (green checkmarks), workflow marked complete



---

## Task 2 — Manual Trigger + System Information
- [x] Changes made to the workflow file.
- [x] The gathered system information from runner.
- [x] Comparison of manual vs automatic workflow triggers.
- [x] Analysis of runner environment and capabilities.

### 2.1 Add Manual Trigger
I added workflow_dispatch to allow manual runs and a step that prints runner system information (OS/CPU/RAM/disk).


- **Push trigger:** runs automatically on each commit pushed to the target branch.
- **Manual trigger:** can be started from GitHub UI (“Run workflow”), selecting the branch to run against.

### 2.2 Test Manual Dispatch
This workflow run was started manually from the GitHub Actions UI using the workflow_dispatch trigger on the main branch.
**Workflow Run #2:** https://github.com/Kamilya05/DevOps-Intro/actions/runs/22246189221

### 2.3 Gather System Information
```sh
== OS / Kernel ==
Linux runnervmwffz4 6.11.0-1018-azure #18~24.04.1-Ubuntu SMP Sat Jun 28 04:46:03 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux

== CPU ==
4
Architecture:                         x86_64
CPU op-mode(s):                       32-bit, 64-bit
Address sizes:                        46 bits physical, 57 bits virtual
Byte Order:                           Little Endian
CPU(s):                               4
On-line CPU(s) list:                  0-3
Vendor ID:                            GenuineIntel
Model name:                           Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz
CPU family:                           6
Model:                                106
Thread(s) per core:                   2
Core(s) per socket:                   2
Socket(s):                            1
Stepping:                             6
CPU(s) scaling MHz:                   125%
CPU max MHz:                          2800.0000
CPU min MHz:                          800.0000
BogoMIPS:                             5586.87
Flags:                                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc rep_good nopl xtopology tsc_reliable nonstop_tsc cpuid aperfmperf tsc_known_freq pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch tpr_shadow ept vpid ept_ad fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm avx512f avx512dq rdseed adx smap avx512ifma clflushopt clwb avx512cd sha_ni avx512bw avx512vl xsaveopt xsavec xgetbv1 xsaves vnmi avx512vbmi umip avx512_vbmi2 gfni vaes vpclmulqdq avx512_vnni avx512_bitalg avx512_vpopcntdq la57 rdpid fsrm arch_capabilities
Virtualization:                       VT-x
Hypervisor vendor:                    Microsoft
Virtualization type:                  full
L1d cache:                            96 KiB (2 instances)
L1i cache:                            64 KiB (2 instances)
L2 cache:                             2.5 MiB (2 instances)
L3 cache:                             48 MiB (1 instance)
NUMA node(s):                         1
NUMA node0 CPU(s):                    0-3
Vulnerability Gather data sampling:   Not affected
Vulnerability Itlb multihit:          Not affected
Vulnerability L1tf:                   Not affected
Vulnerability Mds:                    Not affected
Vulnerability Meltdown:               Not affected
Vulnerability Mmio stale data:        Vulnerable: Clear CPU buffers attempted, no microcode; SMT Host state unknown
Vulnerability Reg file data sampling: Not affected
Vulnerability Retbleed:               Vulnerable
Vulnerability Spec rstack overflow:   Not affected
Vulnerability Spec store bypass:      Vulnerable
Vulnerability Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointer sanitization
Vulnerability Spectre v2:             Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI Retpoline

== Memory ==
               total        used        free      shared  buff/cache   available
Mem:            15Gi       819Mi        13Gi        39Mi       1.8Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi

== Disk ==
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   53G   92G  37% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G  1.0M  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   32K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   62M  758M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
```
### 2.4 Analysis of workflow execution process 
The manual trigger runs the same job as the push trigger, but it is initiated explicitly by the user via the UI. The system information step confirms the runner environment (kernel/CPU/RAM/disk) used during execution.

