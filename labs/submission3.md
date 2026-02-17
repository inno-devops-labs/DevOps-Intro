# Lab 3 — CI/CD with GitHub Actions

## Task 1 — First GitHub Actions Workflow

**Observations and Key Concepts:**
- GitHub Actions is an automation platform integrated into GitHub for CI/CD workflows.
- Workflows are defined in YAML files stored in `.github/workflows/`.
- Key concepts learned:
  - **Jobs**: A set of steps executed on the same runner (VM). In the quickstart, there's one job named `Explore-GitHub-Actions`.
  - **Steps**: Individual tasks in a job, run sequentially. They can be shell commands (`run:`) or reusable actions (e.g., `uses: actions/checkout@v5`).
  - **Runners**: Virtual machines provided by GitHub (e.g., `ubuntu-latest` is a Linux VM). Each run starts fresh.
  - **Triggers**: Events that start workflows, like `push` (code commits).
- Steps followed:
  1. Created `.github/workflows/github-actions-demo.yml` in the repo.
  2. Copied the official quickstart YAML (see below).
  3. Committed directly to the `feature/lab3` branch.

**Workflow YAML (Initial Version):**
```yaml
name: GitHub Actions Demo
run-name: ${{ github.actor }} is testing out GitHub Actions 🚀
on: [push]
jobs:
  Explore-GitHub-Actions:
    runs-on: ubuntu-latest
    steps:
      - run: echo "🎉 The job was automatically triggered by a ${{ github.event_name }} event."
      - run: echo "🐧 This job is now running on a ${{ runner.os }} server hosted by GitHub!"
      - run: echo "🔎 The name of your branch is ${{ github.ref }} and your repository is ${{ github.repository }}."
      - name: Check out repository code
        uses: actions/checkout@v5
      - run: echo "💡 The ${{ github.repository }} repository has been cloned to the runner."
      - run: echo "🖥️ The workflow is now ready to test your code on the runner."
      - name: List files in the repository
        run: |
          ls ${{ github.workspace }}
      - run: echo "🍏 This job's status is ${{ job.status }}."

```

**Link to Successful Run:**
- https://github.com/Nikitjjj/DevOps-Intro/actions/runs/22095353474/job/63850877425
  ![alt text](image-3.png)

**What Caused the Run to Trigger:**
- The workflow was triggered by the `push` event when I pushed the commit adding `github-actions-demo.yml` to the `feature/lab3` branch.

**Analysis of Workflow Execution Process:**
- The workflow ran automatically on push.
- It cloned the repo (via `checkout` action), executed steps sequentially, and used GitHub contexts (e.g., `${{ github.event_name }}` resolved to "push", `${{ runner.os }}` to "Linux").
- Logs showed each step's output, including a file list .
- The process: Trigger → Job starts on fresh Ubuntu VM → Steps run in order → Job succeeds if no errors.
- No failures; all steps passed with green checks.

![alt text](image-4.png)


## Task 2 — Manual Trigger + System Information

**Changes Made to Workflow File:**
- Updated `on:` to `[push, workflow_dispatch]` to enable manual dispatch (no inputs needed).
- Committed and pushed; tested both automatic (push) and manual triggers.

**Updated Workflow YAML (With Manual Trigger):**
```yaml
name: GitHub Actions Demo
run-name: ${{ github.actor }} is testing out GitHub Actions 🚀
on: [push, workflow_dispatch]
jobs:
  Explore-GitHub-Actions:
    runs-on: ubuntu-latest
    steps:
      - run: echo "🎉 The job was automatically triggered by a ${{ github.event_name }} event."
      - run: echo "🐧 This job is now running on a ${{ runner.os }} server hosted by GitHub!"
      - run: echo "🔎 The name of your branch is ${{ github.ref }} and your repository is ${{ github.repository }}."
      - name: Check out repository code
        uses: actions/checkout@v5
      - run: echo "💡 The ${{ github.repository }} repository has been cloned to the runner."
      - run: echo "🖥️ The workflow is now ready to test your code on the runner."
      - name: List files in the repository
        run: |
          ls ${{ github.workspace }}
      - run: echo "🍏 This job's status is ${{ job.status }}."
      - name: Gather System Information
        run: |
          echo "OS Information:"
          uname -a
          echo "CPU Information:"
          lscpu
          echo "Memory Information:"
          free -h
```



**Comparison of Manual vs Automatic Triggers:**
- Automatic (`push`): Runs on every commit/push; useful for CI (e.g., auto-test code). Event: "push".
- Manual (`workflow_dispatch`): Triggered via UI ("Run workflow" button); useful for on-demand runs (e.g., deployments). Event: "workflow_dispatch".
- Both use the same job/steps; difference is in trigger and potential inputs (none here). Manual allows branch selection.

**Gathered System Information (From Run Logs):**
- **OS Information:**  

![alt text](image-5.png)

- **OS Information:**  
  Linux runnervmjduv7 6.14.0-1017-azure #17~24.04.1-Ubuntu SMP Mon Dec  1 20:10:50 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux  
  (This shows Ubuntu 24.04 on Azure VM, kernel 6.14, 64-bit.)

- **CPU Information:**  
  Architecture:                            x86_64  
  CPU op-mode(s):                          32-bit, 64-bit  
  Address sizes:                           48 bits physical, 48 bits virtual  
  Byte Order:                              Little Endian  
  CPU(s):                                  4  
  On-line CPU(s) list:                     0-3  
  Vendor ID:                               AuthenticAMD  
  Model name:                              AMD EPYC 7763 64-Core Processor  
  CPU family:                              25  
  Model:                                   1  
  Thread(s) per core:                      2  
  Core(s) per socket:                      2  
  Socket(s):                               1  
  Stepping:                                1  
  BogoMIPS:                                4890.85  
  Flags:                                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl tsc_reliable nonstop_tsc cpuid extd_apicid aperfmperf tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm cmp_legacy svm cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw topoext vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves user_shstk clzero xsaveerptr rdpru arat npt nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold v_vmsave_vmload umip vaes vpclmulqdq rdpid fsrm  
  Virtualization:                          AMD-V  
  Hypervisor vendor:                       Microsoft  
  Virtualization type:                     full  
  L1d cache:                               64 KiB (2 instances)  
  L1i cache:                               64 KiB (2 instances)  
  L2 cache:                                1 MiB (2 instances)  
  L3 cache:                                32 MiB (1 instance)  
  NUMA node(s):                            1  
  NUMA node0 CPU(s):                       0-3  
  Vulnerability Gather data sampling:      Not affected  
  Vulnerability Ghostwrite:                Not affected  
  Vulnerability Indirect target selection: Not affected  
  Vulnerability Itlb multihit:             Not affected  
  Vulnerability L1tf:                      Not affected  
  Vulnerability Mds:                       Not affected  
  Vulnerability Meltdown:                  Not affected  
  Vulnerability Mmio stale data:           Not affected  
  Vulnerability Reg file data sampling:    Not affected  
  Vulnerability Retbleed:                  Not affected  
  Vulnerability Spec rstack overflow:      Vulnerable: Safe RET, no microcode  
  Vulnerability Spec store bypass:         Vulnerable  
  Vulnerability Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization  
  Vulnerability Spectre v2:                Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected  
  Vulnerability Srbds:                     Not affected  
  Vulnerability Tsa:                       Vulnerable: Clear CPU buffers attempted, no microcode  
  Vulnerability Tsx async abort:           Not affected  
  Vulnerability Vmscape:                   Not affected  
  (4-core AMD EPYC processor on GitHub runners.)

- **Memory Information:**  
              total        used        free      shared  buff/cache   available  
  Mem:           15Gi       1.0Gi        13Gi        40Mi       1.8Gi        14Gi  
  Swap:          3.0Gi          0B       3.0Gi  
  (Total ~15GB RAM, typical for a larger ubuntu-latest runner; usage varies per run.)

**Analysis of Runner Environment and Capabilities:**
- Runner: GitHub-hosted `ubuntu-latest` (Ubuntu 24.04 LTS on Azure VM).
- Capabilities: 4 vCPUs, ~15GB RAM, 3GB swap. Suitable for more demanding CI/CD tasks (e.g., building/testing code). Ephemeral (fresh per run), supports Linux commands/tools.
- Environment: Secure, isolated; pre-installed software (Node.js, Python, etc.). For heavier workloads, use self-hosted or larger runners.
