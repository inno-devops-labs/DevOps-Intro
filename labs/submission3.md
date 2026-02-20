# Task 1

Successful Run link:
https://github.com/myavg/DevOps-Intro/actions/runs/22226803324


Key concepts learned (jobs, steps, runners, triggers)

Trigger — an event that starts the workflow (here: push).

Job — a group of tasks executed on the same runner.

Steps — individual commands executed sequentially inside a job.

Runner — the machine that executes the job (GitHub-hosted ubuntu-latest).

What caused the run to trigger

The workflow was triggered automatically after a commit was pushed to the feature/lab3 branch, because the workflow listens to the push event.

Analysis of workflow execution process

After the push event, GitHub created a workflow run and started a hosted Ubuntu runner. The runner executed the job and its steps in order, printed the output to the logs, and completed successfully.

# Task 2

Changes made to the workflow file

Added the workflow_dispatch trigger to allow manual execution.

Added a new step to collect system information from the runner (OS, CPU, memory, disk).

Gathered system information from the runner

The runner is a GitHub-hosted Ubuntu virtual machine.
The logs show details about the operating system, CPU architecture, available memory, and disk space.

Comparison of manual vs automatic workflow triggers

Automatic trigger (push) — runs automatically when commits are pushed to the repository.

Manual trigger (workflow_dispatch) — started manually from the GitHub Actions UI.

Both execute the same workflow but are initiated differently.

Analysis of runner environment and capabilities

The workflow runs on a cloud-based GitHub-hosted runner (ubuntu-latest).
It provides a preconfigured Linux environment with standard development tools and limited virtual hardware resources suitable for CI tasks.


logs:
Run echo "=== OS ==="
=== OS ===
Linux runnervmwffz4 6.11.0-1018-azure #18~24.04.1-Ubuntu SMP Sat Jun 28 04:46:03 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
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
=== CPU ===
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
BogoMIPS:                             4890.84
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
=== Memory ===
               total        used        free      shared  buff/cache   available
Mem:            15Gi       831Mi        13Gi        35Mi       1.8Gi        14Gi
Swap:          3.0Gi          0B       3.0Gi
=== Disk ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       145G   53G   92G  37% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G 1008K  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   32K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   62M  758M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
=== Runner env ===
RUNNER_OS=Linux
RUNNER_ARCH=X64
RUNNER_NAME=GitHub Actions 1000000001
RUNNER_TEMP=/home/runner/work/_temp
RUNNER_TOOL_CACHE=/opt/hostedtoolcache