# Submission 3 Notes

## Task 1 — First GitHub Actions Workflow

### Link to the successful run (or screenshots)
**Screenshot**
![](images/actions_run.png)

**Link**
https://github.com/pixel4lex/DevOps-Intro/actions/runs/22037748808/job/63673423412

### Key concepts learned
**Jobs** — A job is a set of steps that run together on the same runner within a workflow. Jobs can run in parallel by default or be configured with dependencies to run sequentially.

**Steps** — Steps are individual tasks inside a job, such as running a command or using an action. They execute in order and share the same environment within that job.

**Runners** — Runners are the machines (virtual or self-hosted) that execute jobs. GitHub provides hosted runners (e.g., Ubuntu, Windows, macOS), or you can use your own infrastructure.

**Triggers** — Triggers define the events that start a workflow, such as pushes, pull requests, schedules, or manual dispatch. They determine when the automation runs.

### What caused the run to trigger
The workflow run was triggered automatically by a push event to the repository, because the configuration specifies on: [push]. Any commit pushed to any branch starts the workflow, which then executes the defined job on a GitHub-hosted Ubuntu runner.

### Analysis of workflow execution process
1. **Trigger Activation (`on: [push]`)**  
   Any push to the repository triggers the workflow automatically. GitHub creates a new run with the specified workflow name and a dynamic run name showing the user who pushed the changes.

2. **Job Queuing and Runner Provisioning**  
   The workflow contains a single job (`Explore-GitHub-Actions`) configured to run on `ubuntu-latest`. GitHub provisions a hosted Ubuntu virtual machine and prepares the workspace directory for the job.

3. **Sequential Step Execution**  
   All steps execute in order on the same runner and share the same filesystem and environment variables.

4. **Step Details:**  
   - `echo` steps print contextual information such as the triggering event (`push`), runner OS, branch reference, and repository name.  
   - `actions/checkout@v5` clones the repository into the runner workspace so subsequent steps can access the code.  
   - Additional `echo` commands confirm readiness and provide status messages.  
   - The `ls ${{ github.workspace }}` command lists repository files, verifying the checkout succeeded.  
   - The final step prints the job status (typically `success` if no errors occurred).

5. **Completion and Result**  
   If all steps succeed (exit code 0), the job and workflow run are marked as successful. If any step fails, the job stops and the run is marked as failed.


## Task 2 — Manual Trigger + System Information
### Changes Made to the Workflow File
An additional step was added to collect detailed system information about the GitHub-hosted runner. This step runs standard Linux commands (`uname`, `lscpu`, `free`, `df`) to gather operating system details, hardware specifications, memory usage, and disk information.

### Gathered system information from runner
```
===== OS Information =====
Linux runnervmjduv7 6.14.0-1017-azure #17~24.04.1-Ubuntu SMP Mon Dec  1 20:10:50 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
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
===== CPU Information =====
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
BogoMIPS:                                4890.86
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
===== Memory Information =====
               total        used        free      shared  buff/cache   available
Mem:            15Gi       1.0Gi        13Gi        39Mi       1.8Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi
===== Disk Information =====
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   53G   92G  37% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G 1008K  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   32K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   63M  757M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
```

### Comparison of Manual vs Automatic Workflow Triggers
**Automatic Trigger (Push Event)**  
The workflow is configured with `on: [push]`, meaning it runs automatically whenever changes are pushed to the repository. This is useful for continuous integration, ensuring code is tested or validated immediately after each commit without user intervention.

**Manual Trigger (Workflow Dispatch)**  
Manual workflows are started explicitly by a user from the GitHub Actions interface using `workflow_dispatch`. They are useful for on-demand tasks such as maintenance operations, reruns with specific parameters, or controlled deployments.

**Differences:**
- Automatic triggers support continuous integration and rapid feedback.
- Manual triggers provide control and intentional execution.
- Automatic runs may occur frequently; manual runs occur only when requested.
- Manual triggers can accept input parameters, while push triggers react to repository events.

### Analysis of Runner Environment and Capabilities
The job runs on a GitHub-hosted `ubuntu-latest` runner, which is a temporary virtual machine provisioned for each workflow run. The environment includes a modern Linux OS, preinstalled development tools, package managers, and common utilities.

**Observed Capabilities:**
- Linux-based environment with full shell access
- AMD EPYC 7763 64-Core Processor and 15 gigabytes of RAM
- Preinstalled tools (Git, Docker, language runtimes, build tools)
- Internet access for downloading dependencies

**Implications:**
- Ensures clean, reproducible builds because each run starts from a fresh environment
- Suitable for compiling code, running tests, and performing system-level diagnostics
- Persistent data must be stored using artifacts or external storage, since local changes do not survive between runs