# Lab 5 — Virtualization & System Analysis

## 1.1: Install VirtualBox

**Host Operating System:**  
> Ubuntu 25.04

**VirtualBox Version:**  
> 7.2.4 r170995

## Installation Notes

- Downloaded VirtualBox from https://www.virtualbox.org/
- Installed using default settings
- There was a problem with KVM kernel extension

## Task 2 — Ubuntu VM and System Analysis

### 2.1 VM Configuration

| Resource | Value Used |
|-----------|------------|
| OS | Ubuntu 24.04 LTS |
| RAM |  6 GB |
| CPU Cores | 3 |
| Storage | 25 GB |

---

### 2.2 System Information Discovery

---

### CPU Details

**Tool(s):** `lscpu`, `cat /proc/cpuinfo`  
**Commands:**
```bash
lscpu
cat /proc/cpuinfo | grep -E "model name|cpu cores|cpu MHz"
```
**Output:**
```
Architecture: x86_64
  CPU op-mode(s): 32-bit, 64-bit
  Address sizes: 39 bits physical, 48 bits virtual
  Byte Order: Little Endian
CPU(s): 3
  On-line CPU(s) list: 0-2
Vendor ID: GenuineIntel
  Model name: 12th Gen Intel(R) Core(TM) i5-12450H
    CPU family: 6
    Model: 154
    Thread(s) per core: 1
    Core(s) per socket: 3
    Socket(s): 1
    Stepping: 3
    BogoMIPS: 4991.99
    Flags: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch fsgsbase bmi1 avx2 bmi2 invpcid rdseed adx clflushopt sha_ni arat md_clear flush_l1d arch_capabilities
Virtualization features:
  Hypervisor vendor: KVM
  Virtualization type: full
Caches (sum of all):
  L1d: 144 KiB (3 instances)
  L1i: 96 KiB (3 instances)
  L2: 3.8 MiB (3 instances)
  L3: 36 MiB (3 instances)
NUMA:
  NUMA node(s): 1
  NUMA node0 CPU(s): 0-2
Vulnerabilities:
  Gather data sampling: Not affected
  Ghostwrite: Not affected
  Indirect target selection: Mitigation; Aligned branch/return thunks
  Itlb multihit: Not affected
  L1tf: Not affected
  Mds: Not affected
  Meltdown: Not affected
  Mmio stale data: Not affected
  Old microcode: Not affected
  Reg file data sampling: Mitigation; Clear Register File
  Retbleed: Not affected
  Spec rstack overflow: Not affected
  Spec store bypass: Vulnerable
  Spectre v1: Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2: Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI SW loop, KVM SW loop
  Srbds: Not affected
  Tsa: Not affected
  Tsx async abort: Not affected
  Vmscape: Not affected
model name : 12th Gen Intel(R) Core(TM) i5-12450H
cpu MHz : 2495.998
cpu cores : 3
model name : 12th Gen Intel(R) Core(TM) i5-12450H
cpu MHz : 2495.998
cpu cores : 3
model name : 12th Gen Intel(R) Core(TM) i5-12450H
cpu MHz : 2495.998
cpu cores : 3
```

### Memory Information
**Tool(s):** `free -h`, `cat /proc/meminfo`  
**Commands:**
```bash
free -h
cat /proc/meminfo | head -n 5
```
**Output:**
```
               total        used        free      shared  buff/cache   available
Mem:           5.7Gi       1.8Gi       1.5Gi       52Mi       2.3Gi       3.8Gi
Swap:          0B          0B          0B
MemTotal:      5927384 kB
MemFree:       1591324 kB
MemAvailable:  4001500 kB
Buffers:       40236 kB
Cached:        2355640 kB
```

### Network Configuration
**Tool(s):** `ip -c addr show`, `ip route`  
**Commands:**
```bash
ip -c addr show
ip route
```
**Output:**
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:4b:7c:b0 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 85457sec preferred_lft 85457sec
    inet6 fd17:625c:f037:2:59ee:6f70:b414:1c76/64 scope global temporary dynamic
       valid_lft 86029sec preferred_lft 14029sec
    inet6 fd17:625c:f037:2:a00:27ff:fe4b:7cb0/64 scope global dynamic mngtmpaddr
       valid_lft 86029sec preferred_lft 14029sec
    inet6 fe80::a00:27ff:fe4b:7cb0/64 scope link
       valid_lft forever preferred_lft forever
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
```

### Storage Information
**Tool(s):** `df -h`, `lsblk -f`  
**Commands:**
```bash
df -h
lsblk -f
```
**Output:**
```
Filesystem     Size  Used Avail Use% Mounted on
tmpfs          579M  1.5M  578M   1% /run
/dev/sda2       25G  6.1G   18G  26% /
tmpfs          2.9G     0  2.9G   0% /dev/shm
tmpfs          5.0M  8.0K  5.0M   1% /run/lock
tmpfs          579M  124K  579M   1% /run/user/1000
NAME FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0
     squash 4.0                                                     0 100% /snap/core22/2292
loop1
     squash 4.0                                                     0 100% /snap/bare/5
loop2
     squash 4.0                                                     0 100% /snap/firefox/7766
loop3
     squash 4.0                                                     0 100% /snap/firmware-updater/210
loop4
     squash 4.0                                                     0 100% /snap/gnome-42-2204/247
loop5
     squash 4.0                                                     0 100% /snap/gtk-common-themes/1535
loop6
     squash 4.0                                                     0 100% /snap/snap-store/1270
loop7
     squash 4.0                                                     0 100% /snap/snapd/25935
loop8
     squash 4.0                                                     0 100% /snap/snapd-desktop-integration/343
sda                                                                          
├─sda1                                                                       
└─sda2     ext4  1.0       2214ff01-3845-4258-9b17-5ce546a065ac   17.2G    25% /
sr0
```

### Operating System
**Tool(s):** `uname -a`, `cat /etc/os-release`  
**Commands:**
```bash
uname -a
cat /etc/os-release
```
**Output:**
```
Linux DevOps 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

### Virtualization Detection
**Tool(s):** `systemd-detect-virt`, `cat /sys/class/dmi/id/product_name`  
**Commands:**
```bash
systemd-detect-virt
cat /sys/class/dmi/id/product_name
```
**Output:**
```
oracle
VirtualBox
```

## Reflection
The most useful tools were `lscpu` (gives a perfect summary of CPU + virtualization flags), `free -h` and `ip -c addr show` (human-readable and coloured).  
I started with the `/proc` filesystem as suggested in the lab, then discovered the friendlier wrappers using `man -k`.  
`systemd-detect-virt` instantly confirmed we are inside a VM (reports "oracle" because VirtualBox is from Oracle).  
All commands worked without installing any extra packages — exactly as intended.

**References used:**
- VirtualBox manual: https://www.virtualbox.org/manual/
- Linux command reference: https://linuxcommand.org
- `/proc` filesystem docs: https://www.kernel.org/doc/html/latest/filesystems/proc.html
