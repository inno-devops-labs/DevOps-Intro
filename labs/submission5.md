# Lab 5 — Virtualization & System Analysis

## Task 1 — VirtualBox Installation

### 1.1 Installation Details
- **Host Operating System:** macOS Sonoma 14.6
- **Host Hardware:** Apple M3 Pro, 36 GB RAM
- **VirtualBox Version:** 7.2.6 r172322 (Qt6.8.0 on cocoa)
- **Installation Issues:** Installation completed successfully without any issues.

## Task 2 — Ubuntu VM and System Analysis

### 2.1 VM Configuration
- **VM Name:** DevOps2
- **VM Folder:** /Users/shiyanovn/VirtualBox VMs
- **OS Type:** Ubuntu (64-bit ARM)
- **ISO Image:** ubuntu-25.10-desktop-arm64.iso
- **Version:** 25.10 (Not an LTS release, used with instructor's permission due to better ARM support on Apple Silicon)
- **RAM:** 8192 MB (8 GB)
- **Storage:** 25 GB (VDI, dynamic allocation)
- **CPU Cores:** 4
- **Installation Notes:** Used Ubuntu 25.10 after receiving permission from the instructor (Dmitriy Creed) due to compatibility issues with 24.04 LTS on Apple M3 Pro (ARM architecture).

### 2.2 System Information Discovery

#### CPU Details
- **Tool discovered:** `lscpu`
- **Command used:** `lscpu`
- **Output:**

```bash
Architecture:                    aarch64
CPU op-mode(s):                 64-bit
Byte Order:                     Little Endian
CPU(s):                         4
On-line CPU(s) list:            0-3
Vendor ID:                      Apple
Model name:                     -
Model:                          0
Thread(s) per core:             1
Core(s) per cluster:            4
Socket(s):                      1
Cluster(s):                     1
Stepping:                       0x0
BogoMIPS:                       48.00
Flags:                          fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm iset feat lete dcpop sha3 asimddp sha512 asimdhm dit uscat ilrcpc flagm ssbs sb paca pacg dcpodp flagm2 frint
NUMA:                           
NUMA node(s):                   1
NUMA node0 CPU(s):              0-3
Vulnerabilities:                
Gather data sampling:           Not affected
```

- **Reflection:** `lscpu` provides a well-structured overview of the CPU architecture, confirming we are running on ARM (aarch64) with 4 cores from Apple. The detailed flags show the extensive instruction set support.

#### Memory Information
- **Tool discovered:** `free -h`
- **Command used:** `free -h`
- **Output:**
```bash
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       2.4Gi       748Mi       389Mi       5.3Gi       5.3Gi
Swap:            0B          0B          0B
```
- **Reflection:** The `-h` flag makes `free` output human-readable, showing 7.7GB total RAM with 2.4GB used. The VM has no swap space configured, which is typical for a fresh installation.

#### Network Configuration
- **Tool discovered:** `ip addr`
- **Command used:** `ip addr`
- **Output:**

```bash
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:16:2e:be brd ff:ff:ff:ff:ff:ff
    altname enx080027162ebe
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s8
       valid_lft 86092sec preferred_lft 86092sec
    inet6 fd17:625c:f037:2::a00:27ff:fe16:2ebe/64 scope global dynamic noprefixroute
       valid_lft 86354sec preferred_lft 14354sec
    inet6 fe80::a00:27ff:fe16:2ebe/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

- **Reflection:** `ip addr` shows the network interface configuration with IPv4 address 10.0.2.15 and multiple IPv6 addresses, indicating proper network connectivity through VirtualBox's NAT configuration.

#### Storage Information
- **Tool discovered:** `df -h`
- **Command used:** `df -h`
- **Output:**

```bash
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        25G  6.2G   18G  26% /
/dev/sda1       1.5G  6.1M  1.4G   1% /boot/efi
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           1.6G  1.2M  1.6G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
```

- **Reflection:** `df -h` shows the 25GB virtual disk is properly partitioned with 26% used, confirming the storage configuration from Task 2.1.

#### Operating System
- **Tool discovered:** `uname -a`
- **Command used:** `uname -a`
- **Output:**

```bash
Linux DevOps2 6.17.0-14-generic #14-Ubuntu SMP PREEMPT_DYNAMIC Fri Jan 9 16:29:17 UTC 2026 aarch64 GNU/Linux
```

- **Reflection:** The `uname -a` command shows we're running Linux kernel 6.17.0 on Ubuntu 25.10, confirming the ARM64 architecture.

#### Virtualization Detection
- **Tool discovered:** `systemd-detect-virt`
- **Command used:** `systemd-detect-virt`
- **Output:**

```bash
none
```
**Command 2:** `lsmod | grep -i vbox`
**Output:**
```bash
vboxguest 57344 0
```

- **Reflection:** The standard `systemd-detect-virt` tool returns "none" on Apple Silicon (M3 Pro) because VirtualBox uses Apple's native Hypervisor.framework, which is not recognized as traditional virtualization. However, the presence of the `vboxguest` kernel module (VirtualBox Guest Additions) confirms the system is running inside a VirtualBox VM. This demonstrates that multiple detection methods may be necessary depending on the host platform.
