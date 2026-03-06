# Lab 5 — Virtualization & System Analysis

**Student:** Kamilya Shakirova
**Date:** 06-03-2026


---


## Task 1 — VirtualBox Installation 

- [x] Host operating system and version
- [x] VirtualBox version number
- [x] Any installation issues encountered

### Install VirtualBox


- Host operating system: Windows 11 Home 25H2
- Host RAM: 16GB
- Host Processor: 12th Gen Intel(R) Core(TM) i9-12900H (2.50 GHz)

I have already downloaded VirtualBox. When I installed it, I didn't have any problems.
- VirtualBox version: 7.2.4 r170995 (Qt6.8.0 on windows)

---

## Task 2 — Ubuntu VM and System Analysis 

- [x] VM configuration specifications used (RAM, storage, CPU cores)
- [x] For each information type above:
  - Tool name(s) you discovered
  - Command(s) used
  - Complete command output
- [x] Brief reflection on which tools were most useful and why


### 2.1 Ubuntu VM Configuration

**VM Setup:**
I have already created VM in VirtualBox

| Setting | Value |
|---------|-------|
| **OS Type** | Ubuntu 24.04.4 LTS |
| **RAM Allocation** | [4 GB] |
| **CPU Cores** | [8 cores] |
| **Storage Size** | [25 GB] |
| **Video Memory** | [16 MB] |
| **Network Adapter** | Intel PRO/1000 MT Desktop (NAT) |

### 2.2 System Information Discovery

### CPU Details
**Tools Discovered:** `lscpu`, `cat /proc/cpuinfo`, `nproc`

**Commands Used:**
```bash
lscpu
cat /proc/cpuinfo | grep -E
nproc
```

**Command Output:**
``` bash
kamilya@kamilya:~$ lscpu
Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          39 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   8
  On-line CPU(s) list:    0-7
Vendor ID:                GenuineIntel
  Model name:             12th Gen Intel(R) Core(TM) i9-12900H
    CPU family:           6
    Model:                154
    Thread(s) per core:   1
    Core(s) per socket:   8
    Socket(s):            1
    Stepping:             3
    BogoMIPS:             5836.82
    Flags:                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge m
                          ca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall
                           nx rdtscp lm constant_tsc rep_good nopl xtopology non
                          stop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 cx16
                           sse4_1 sse4_2 movbe popcnt aes rdrand hypervisor lahf
                          _lm abm 3dnowprefetch ibrs_enhanced fsgsbase bmi1 bmi2
                           invpcid rdseed clflushopt md_clear flush_l1d arch_cap
                          abilities
Virtualisation features:  
  Hypervisor vendor:      KVM
  Virtualisation type:    full
Caches (sum of all):      
  L1d:                    384 KiB (8 instances)
  L1i:                    256 KiB (8 instances)
  L2:                     10 MiB (8 instances)
  L3:                     192 MiB (8 instances)
NUMA:                     
  NUMA node(s):           1
  NUMA node0 CPU(s):      0-7
Vulnerabilities:          
  Gather data sampling:   Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Vulnerable: No microcode
  Retbleed:               Mitigation; Enhanced IBRS
  Spec rstack overflow:   Not affected
  Spec store bypass:      Vulnerable
  Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointe
                          r sanitization
  Spectre v2:             Mitigation; Enhanced / Automatic IBRS; RSB filling; PB
                          RSB-eIBRS SW sequence; BHI SW loop, KVM SW loop
  Srbds:                  Not affected
  Tsx async abort:        Not affected

kamilya@kamilya:~$ ncat /proc/cpuinfo | grep -E
model name : 12th Gen Intel(R) Core(TM) i9-12900H
cpu MHz  : 2918.410
cpu cores : 8
model name : 12th Gen Intel(R) Core(TM) i9-12900H
cpu MHz  : 2918.410
cpu cores : 8
model name : 12th Gen Intel(R) Core(TM) i9-12900H
cpu MHz  : 2918.410
cpu cores : 8
model name : 12th Gen Intel(R) Core(TM) i9-12900H



kamilya@kamilya:~$ nproc
8
```

### Memory Information
**Tools Discovered:** `free -h`

**Commands Used:**
```bash
free -h
cat /proc/meminfo | head -10
```

**Command Output:**
``` bash
kamilya@kamilya:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.6Gi       210Mi        67Mi       2.0Gi       1.9Gi
Swap:          2.6Gi          0B       2.6Gi

kamilya@kamilya:~$ cat /proc/meminfo | head -10
MemTotal:        4008400 kB
MemFree:          224080 kB
MemAvailable:    1995812 kB
Buffers:           49140 kB
Cached:          1964100 kB
SwapCached:            0 kB
Active:          2880276 kB
Inactive:         533872 kB
Active(anon):    1451980 kB
Inactive(anon):    18116 kB
```

### Network Configuration
**Tools Discovered:** `ip addr`

**Commands Used:**
```bash
ip addr show
```

**Command Output:**
```bash
kamilya@kamilya:~$ ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:b7:9a:01 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 85056sec preferred_lft 85056sec
    inet6 fd17:625c:f037:2:f1e8:91b7:ada:df18/64 scope global temporary dynamic 
       valid_lft 86141sec preferred_lft 14141sec
    inet6 fd17:625c:f037:2:c410:89dc:791a:368d/64 scope global dynamic mngtmpaddr noprefixroute 
       valid_lft 86141sec preferred_lft 14141sec
    inet6 fe80::f86f:c5ac:9ed4:9a67/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

### Storage Information
**Tools Discovered:** `df -h`

**Commands Used:**
```bash
df -h
```

**Command Output:**
```bash
kamilya@kamilya:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.6M  390M   1% /run
/dev/sda3        24G   13G   11G  55% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
/dev/sda2       512M  6.1M  506M   2% /boot/efi
tmpfs           392M  112K  392M   1% /run/user/1000
```

### Operating System Details
**Tools Discovered:** `lsb_release -a`

**Commands Used:**
```bash
lsb_release -a
```

**Command Output:**
```bash
kamilya@kamilya:~$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description: Ubuntu 22.04.4 LTS
Release: 22.04
Codename: jammy
```

---

### Most Useful Tools

**Which tools were most useful and why?**

The `lscpu` and `free -h` commands stood out as the most immediately useful tools during this analysis. `lscpu` provides a clean, organized view of processor architecture, core counts, and clock speeds in a single command, making it far more readable than parsing through `/proc/cpuinfo`. Similarly, `free -h` presents memory information in human-readable format with an excellent breakdown of used, available, and cached memory—crucial for understanding real memory pressure versus what applications are actually using.
