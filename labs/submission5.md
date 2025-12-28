# Lab 5

## Task 1 - VirtualBox Installation

### Host System Information

- Host OS: macOS Sequoia 15.6.1
- Architecture: Apple Silicon M4
- VirtualBox Version: 7.2.2 r170484 (Qt6.8.0 on cocoa)

### Installation Issues

- No installation issues discovered
- Note: VirtualBox on Apple Silicon M4 uses experimental ARM support, which may explain some of the unusual system information results seen in Task 2

## Task 2 - Ubuntu VM and System Analysis

### 2.1: Creating Ubuntu VM

- ISO Used: ubuntu-24.04-desktop-arm64.iso
- Created VM with minimal setup (4GB RAM, 2 CPU cores, 25GB Disk)
- Installation: Default installation process completed successfully

### 2.2: System Information Discovery

#### CPU details

**Tools Discovered**: lscpu, cat /proc/cpuinfo

```bash
> lscpu
Architecture:                aarch64
  CPU op-mode(s):            64-bit
  Byte Order:                Little Endian
CPU(s):                      2
  On-line CPU(s) list:       0,1
Vendor ID:                   Apple
  Model name:                -
    Model:                   0
    Thread(s) per core:      1
    Core(s) per cluster:     2
    Socket(s):               -
    Cluster(s):              1
    Stepping:                0x0
    BogoMIPS:                48.00
    Flags:                   fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics 
                             fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop 
                             sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm
                              sb paca pacg dcpodp flagm2 frint bf16 afp
```

```bash
> cat /proc/cpuinfo
processor : 0
BogoMIPS : 48.00
Features : fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm sb paca pacg dcpodp flagm2 frint bf16 afp
CPU implementer : 0x61
CPU architecture: 8
CPU variant : 0x0
CPU part : 0x000
CPU revision : 0

processor : 1
BogoMIPS : 48.00
Features : fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm sb paca pacg dcpodp flagm2 frint bf16 afp
CPU implementer : 0x61
CPU architecture: 8
CPU variant : 0x0
CPU part : 0x000
CPU revision : 0
```

**Output Analysis**:

- Architecture: aarch64 (ARM64) - correct for Apple Silicon
- CPU Cores: 2 cores as configured
- Vendor: Apple - correctly identifies the host hardware
- The CPU model shows as "-" which is unusual and may be related to VirtualBox's experimental ARM support on M4

#### Memory Information

**Tools Discovered**: free -h, cat /proc/meminfo

```bash
> free -h
               total        used        free      shared  buff/cache   available
Mem:           3.3Gi       1.7Gi       378Mi        63Mi       1.5Gi       1.6Gi
Swap:             0B          0B          0B
```

```bash
> cat /proc/meminfo
MemTotal:        3466204 kB
MemFree:          397116 kB
MemAvailable:    1732652 kB
Buffers:           53672 kB
Cached:          1441748 kB
SwapCached:            0 kB
Active:          2009972 kB
Inactive:         707952 kB
Active(anon):    1219016 kB
Inactive(anon):    68368 kB
Active(file):     790956 kB
Inactive(file):   639584 kB
Unevictable:          16 kB
Mlocked:              16 kB
SwapTotal:             0 kB
SwapFree:              0 kB
Zswap:                 0 kB
Zswapped:              0 kB
Dirty:               460 kB
Writeback:             0 kB
AnonPages:       1222436 kB
Mapped:           545424 kB
Shmem:             65080 kB
KReclaimable:      62492 kB
Slab:             220452 kB
SReclaimable:      62492 kB
SUnreclaim:       157960 kB
KernelStack:       12160 kB
ShadowCallStack:    3048 kB
PageTables:        26464 kB
SecPageTables:         0 kB
NFS_Unstable:          0 kB
Bounce:                0 kB
WritebackTmp:          0 kB
CommitLimit:     1733100 kB
Committed_AS:    5935940 kB
VmallocTotal:   135288315904 kB
VmallocUsed:       28896 kB
VmallocChunk:          0 kB
Percpu:             1312 kB
HardwareCorrupted:     0 kB
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
ShmemPmdMapped:        0 kB
FileHugePages:         0 kB
FilePmdMapped:         0 kB
CmaTotal:          32768 kB
CmaFree:           10968 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:               0 kB
```

**Output Analysis**:

- Total RAM: 3.3GiB (slightly less than configured 4GB due to system overhead)
- Available: 1.6GiB after system startup
- Swap: 0B (no swap configured by default)

#### Network Configuration

**Tools Discovered**: ip addr, ip route

```bash
> ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:b4:04:0d brd ff:ff:ff:ff:ff:ff
    altname enx080027b4040d
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s8
       valid_lft 85731sec preferred_lft 85731sec
    inet6 fd17:625c:f037:2:3f1e:7658:9cf0:6593/64 scope global temporary dynamic 
       valid_lft 86372sec preferred_lft 14372sec
    inet6 fd17:625c:f037:2:a00:27ff:feb4:40d/64 scope global dynamic mngtmpaddr proto kernel_ra 
       valid_lft 86372sec preferred_lft 14372sec
    inet6 fe80::a00:27ff:feb4:40d/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
```

```bash
> ip route
default via 10.0.2.2 dev enp0s8 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s8 proto kernel scope link src 10.0.2.15 metric 100
```

**Output Analysis**:

- Interface: enp0s8 (VirtualBox default network adapter)
- IP Address: 10.0.2.15/24 (VirtualBox NAT network)
- Gateway: 10.0.2.2 (VirtualBox default gateway)

#### Storage Information

**Tools Discovered**: df -h, lsblk

```bash
> df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           339M  1.8M  337M   1% /run
/dev/sda2        24G  6.3G   16G  28% /
tmpfs           1.7G     0  1.7G   0% /dev/shm
efivarfs        256K  5.0K  251K   2% /sys/firmware/efi/efivars
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
tmpfs           1.7G  3.8M  1.7G   1% /tmp
tmpfs           1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
/dev/sda1       1.1G  6.4M  1.1G   1% /boot/efi
tmpfs           339M  144K  339M   1% /run/user/1000
```

```bash
> lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0  11.4M  1 loop /snap/desktop-security-center/60
loop1    7:1    0 228.4M  1 loop /snap/firefox/6039
loop2    7:2    0     4K  1 loop /snap/bare/5
loop3    7:3    0  68.9M  1 loop /snap/core22/1912
loop4    7:4    0 493.5M  1 loop /snap/gnome-42-2204/201
loop5    7:5    0  91.7M  1 loop /snap/gtk-common-themes/1535
loop6    7:6    0  13.1M  1 loop /snap/prompting-client/105
loop7    7:7    0  38.7M  1 loop /snap/snapd/23772
loop8    7:8    0    10M  1 loop /snap/snap-store/1271
loop9    7:9    0   544K  1 loop /snap/snapd-desktop-integration/255
sda      8:0    0    25G  0 disk 
├─sda1   8:1    0     1G  0 part /boot/efi
└─sda2   8:2    0  23.9G  0 part /
sr0     11:0    1  1024M  0 rom
```

**Output Analysis**:

- Root Partition: 24GB used 6.3GB (28% used) - matches 25GB configuration
- Boot Partition: 1.1GB EFI system partition
- Device: /dev/sda (virtual disk)

#### Operating System

**Tools Discovered**: lsb_release -a, uname -a

```bash
> lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description: Ubuntu 25.04
Release: 25.04
Codename: plucky
```

```bash
> uname -a
Linux Ubuntu 6.14.0-32-generic #32-Ubuntu SMP PREEMPT_DYNAMIC Fri Aug 29 14:04:54 UTC 2025 aarch64 aarch64 aarch64 GNU/Linux
```

**Output Analysis**:

- Kernel: 6.14.0-32-generic (modern kernel)
- Architecture: aarch64 confirmed
- The output shows Ubuntu 25.04, but I installed Ubuntu 24.04 LTS. This discrepancy may be due to:
    1. Using a development/nightly build of Ubuntu 24.04 that has version information for the next release
    2. VirtualBox experimental ARM support causing version detection issues
    3. Possible ISO file issue

#### Virtualization Detection

**Tools Discovered**: systemd-detect-virt, lshw -class system

```bash
> systemd-detect-virt
none
```

```bash
> sudo lshw -class system
[sudo] password for admin: 
ubuntu                      
    description: Computer
    width: 64 bits
    capabilities: smp cp15_barrier swp tagged_addr_disabled
  *-pnp00:00
       product: PnP device PNP0c02
       physical id: a
       capabilities: pnp
       configuration: driver=system
```

**Output Analysis**:

- Virtualization: systemd-detect-virt returns "none" - this is unexpected as the system is clearly running in a VM. Possible Reasons:
    1. VirtualBox's ARM virtualization may not be properly detected by systemd
- Hardware Info: Basic system information without clear virtualization indicators

#### Reflection on Tool Effectiveness

**Most Useful Tools**:

1. lscpu - Provided clear CPU architecture and core count information
2. free -h - Gave immediate memory usage overview in human-readable format
3. ip addr - Clearly displayed network configuration and IP addresses
4. df -h - Showed disk usage in an easily understandable way

### Key Observations

- VirtualBox on Apple Silicon M4 works but shows some unusual behaviors in system detection
- The ARM64 Ubuntu installation is functional despite version information discrepancies
- Standard Linux system analysis tools work well, but virtualization detection is limited in this experimental setup
- The system successfully meets all functional requirements despite the architectural challenges
