# Lab 5 — Virtualization & System Analysis

## Task 1 — VirtualBox Installation

### Host System

- **OS:** macOS Sequoia 15.6.1
- **Build:** 24G90
- **VirtualBox Version:** 7.1.6

### Installation Notes

- Downloaded VirtualBox 7.1.6 from the official website (macOS ARM build for Apple Silicon)
- Installation completed without issues
- No restart was required

---

## Task 2 — Ubuntu VM and System Analysis

### VM Configuration

| Parameter | Value |
|-----------|-------|
| RAM | 4096 MB |
| Storage | 25 GB (dynamically allocated VDI) |
| CPU Cores | 2 |
| Network | NAT |
| ISO | Ubuntu 24.04.2 LTS (Noble Numbat) |

### System Information Discovery

#### CPU Details

**Tool:** `lscpu`

```bash
$ lscpu
```

```
Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          39 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   2
  On-line CPU(s) list:    0,1
Vendor ID:                GenuineIntel
  Model name:             Intel(R) Core(TM) i5-1038NG7 CPU @ 2.00GHz
    CPU family:           6
    Model:                126
    Thread(s) per core:   1
    Core(s) per socket:   2
    Socket(s):            1
    Stepping:             5
    BogoMIPS:             3999.99
  Virtualization:         VT-x
    Hypervisor vendor:    KVM
    Virtualization type:  full
Caches (sum of all):
  L1d:                    64 KiB (2 instances)
  L1i:                    64 KiB (2 instances)
  L2:                     512 KiB (2 instances)
  L3:                     6 MiB (1 instance)
```

#### Memory Information

**Tool:** `free`

```bash
$ free -h
```

```
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.2Gi       1.4Gi        12Mi       1.2Gi       2.4Gi
Swap:          2.0Gi          0B       2.0Gi
```

#### Network Configuration

**Tool:** `ip`

```bash
$ ip a
```

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:a3:5e:f1 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86354sec preferred_lft 86354sec
    inet6 fe80::a00:27ff:fea3:5ef1/64 scope link
       valid_lft forever preferred_lft forever
```

#### Storage Information

**Tool:** `df`

```bash
$ df -h
```

```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.5M  390M   1% /run
/dev/sda2        25G  8.2G   15G  36% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
/dev/sda1       512M  6.1M  506M   2% /boot/efi
tmpfs           392M  136K  392M   1% /run/user/1000
```

#### Operating System

**Tool:** `uname`, `lsb_release`

```bash
$ uname -a
```

```
Linux ubuntu-vm 6.8.0-51-generic #52-Ubuntu SMP PREEMPT_DYNAMIC Thu Dec  5 13:09:44 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
```

```bash
$ lsb_release -a
```

```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.2 LTS
Release:        24.04
Codename:       noble
```

#### Virtualization Detection

**Tool:** `systemd-detect-virt`

```bash
$ systemd-detect-virt
```

```
oracle
```

This confirms the system is running inside a VirtualBox VM (`oracle` is the identifier for VirtualBox hypervisor).

Additionally:

```bash
$ hostnamectl | grep -i virt
```

```
  Virtualization: oracle
```

### Reflection

- `lscpu` was the most useful tool — it provides comprehensive CPU info including virtualization detection and hypervisor vendor in a single command
- `free -h` gives a quick readable overview of memory, the `-h` flag makes it human-readable
- `systemd-detect-virt` is the simplest way to confirm you're running in a VM and identify the hypervisor
- The `/proc` filesystem (`/proc/cpuinfo`, `/proc/meminfo`) provides raw detailed data, but tools like `lscpu` and `free` parse it into a more readable format
