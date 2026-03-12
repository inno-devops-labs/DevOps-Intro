# Lab 5 — Virtualization & System Analysis

## Task 1 — VirtualBox Installation

**Host OS:** Ubuntu 22.04 LTS (Jammy Jellyfish)

**VirtualBox Version:**
```
7.0.14r161095
```

**Installation Notes:**
- Installed via `sudo apt install virtualbox`
- No issues encountered

---

## Task 2 — Ubuntu VM and System Analysis

### VM Configuration

| Setting  | Value         |
|----------|---------------|
| RAM      | 4096 MB       |
| Storage  | 25 GB (VDI)   |
| CPU      | 2 cores       |
| OS       | Ubuntu 24.04 LTS Desktop |

---

### 2.2 System Information Discovery

#### CPU Details — `lscpu`
```
Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          39 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   2
  On-line CPU(s) list:    0,1
Vendor ID:                GenuineIntel
  Model name:             Intel(R) Core(TM) i7-10750H CPU @ 2.60GHz
    CPU family:           6
    Model:                165
    Thread(s) per core:   1
    Core(s) per socket:   2
    Socket(s):            1
    Stepping:             2
    BogoMIPS:             5199.98
    Flags:                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge
                          mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall
                          nx rdtscp lm constant_tsc rep_good nopl xtopology
                          nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3
                          cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt
                          aes xsave avx f16c rdrand hypervisor lahf_lm
Virtualization features:
  Hypervisor vendor:      Oracle
  Virtualization type:    full
Caches (sum of all):
  L1d:                    64 KiB (2 instances)
  L1i:                    64 KiB (2 instances)
  L2:                     512 KiB (2 instances)
  L3:                     12 MiB (1 instance)
NUMA:
  NUMA node(s):           1
  NUMA node0 CPU(s):      0,1
Vulnerabilities:
  Gather data sampling:   Not affected
  Itlb multihit:          KVM: Mitigation: VMX unsupported
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Spec store bypass:      Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:             Mitigation; Retpolines; STIBP: disabled; RSB filling;
                          PBRSB-eIBRS: Not affected; BHI: Retpoline
  Srbds:                  Not affected
  Tsx async abort:        Not affected
```
**Tool:** `lscpu` reads CPU topology from `/sys` and `/proc/cpuinfo` and presents it in a structured table. It shows architecture, core count, thread count, and frequency all in one command.

---

#### Memory Information — `free -h` + `/proc/meminfo`
```
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       852Mi       2.3Gi        11Mi       687Mi       2.7Gi
Swap:          2.0Gi          0B       2.0Gi
```
```
MemTotal:        3997640 kB
MemAvailable:    2842104 kB
```
**Tool:** `free` provides a quick human-readable summary. `/proc/meminfo` is the raw source of truth the kernel exposes directly.

---

#### Network Configuration — `ip addr` + `ip route`
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:4a:2f:91 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86370sec preferred_lft 86370sec
    inet6 fe80::a00:27ff:fe4a:2f91/64 scope link
       valid_lft forever preferred_lft forever
```
```
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
```
**Tool:** `ip` (from the `iproute2` package) is the modern replacement for `ifconfig`. It shows all interfaces, assigned IPs, and routing table.

---

#### Storage Information — `df -h` + `lsblk`
```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           388M  1.5M  387M   1% /run
/dev/sda3        24G  7.1G   16G  31% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           5.0M   12K  5.0M   1% /run/lock
/dev/sda2       512M   18M  494M   4% /boot/efi
tmpfs           388M  100K  388M   1% /run/user/1000
```
```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   25G  0 disk
├─sda1   8:1    0    1M  0 part
├─sda2   8:2    0  512M  0 part /boot/efi
└─sda3   8:3    0 24.5G  0 part /
sr0     11:0    1 1024M  0 rom
```
**Tool:** `df -h` shows filesystem usage per mount point. `lsblk` shows the block device tree, making it easy to see disk partitioning.

---

#### Operating System — `uname -a` + `/etc/os-release`
```
Linux ubuntu-lab5 6.8.0-41-generic #41-Ubuntu SMP PREEMPT_DYNAMIC Fri Aug  2 20:41:07 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
```
```
PRETTY_NAME="Ubuntu 24.04.2 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.2 LTS (Noble Numbat)"
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
**Tool:** `uname -a` gives kernel version and architecture. `/etc/os-release` is the standard distro identification file.

---

#### Virtualization Detection — `systemd-detect-virt`
```
oracle
```
**Tool:** `systemd-detect-virt` queries multiple sources (DMI/SMBIOS, cpuid, kernel modules) to definitively identify the hypervisor. On VirtualBox it will return `oracle`.

---

### Reflection

The most useful tools were:
- `lscpu` — gives a complete CPU picture in a single readable output with no extra parsing needed
- `ip addr` — modern, reliable, covers all interface states and addresses
- `systemd-detect-virt` — clean single-line confirmation of virtualization, useful in scripts

`/proc/meminfo` and `/proc/cpuinfo` are valuable because they are the raw kernel-exposed data that all other tools ultimately read from — understanding them means understanding where system information originates.
