
## Task 1

**Link to a successful run:**  

https://github.com/Uiyrte/F25-DevOps-Intro/actions/runs/17895083050


**Learned key concepts**

 **Workflow** is an automated process described in a YAML file, which is placed in the .github/workflows/.
 **Trigger** (on: push) is an event that triggers a workflow. In this case, it is a push commit to a repository branch.
 **Job** is a set of steps that are executed on a single runner. The current workflow uses one job called Explore-GitHub-Actions.
 **Steps** are sequential actions within a job. They can be either custom commands (run:) or built-in actions (uses:).
 **Runner** is a server provided by GitHub, on which jobs are executed. This task uses ubuntu-latest.


**What triggered the workflow to run**

Workflow was activated automatically after a commit with the github-actions-demo.yml file was pushed to the feature/lab3 branch. The push event acted as a trigger that initiated the process execution.

## Task 2
**OS Info**
```
Linux runnervmf4ws1 6.11.0-1018-azure #18~24.04.1-Ubuntu SMP Sat Jun 28 04:46:03 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
```
**Disk Info**
```
Filesystem     1K-blocks     Used Available Use% Mounted on
/dev/root       75085112 47591588  27477140  64% /
tmpfs            8189736       84   8189652   1% /dev/shm
tmpfs            3275896     1104   3274792   1% /run
tmpfs               5120        0      5120   0% /run/lock
/dev/sdb16        901520    60640    777752   8% /boot
/dev/sdb15        106832     6250    100582   6% /boot/efi
/dev/sda1       76829444  4194336  68686668   6% /mnt
tmpfs            1637944       12   1637932   1% /run/user/1001
```
**RAM Info**
```
               total        used        free      shared  buff/cache   available
Mem:        16379472      745352    14444848       36172     1530600    15634120
Swap:        4194300           0     4194300
```
**CPU Info**
```
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
BogoMIPS:                             4890.86
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
```