# Lab 5

## Task 1

**Host OS:** Linux arch 6.18.13-arch1-1.1-g14 #1 SMP PREEMPT_DYNAMIC Fri, 27 Feb 2026 15:28:44 +0000 x86_64 GNU/Linux

**VirtualBox Version:** VirtualBox Graphical User Interface Version 7.2.6 r172322
© 2004-2026 Oracle and/or its affiliates (Qt6.10.2 on xcb)
Copyright © 2026 Oracle and/or its affiliates

**Installation isues:** No issues, installation was successful and VirtualBox launched without problems

## Task 2

### VM Configuration

- **RAM:** 14 GiB
- **Storage:** 25 GiB
- **CPU cores:** 2

### System Information

#### Operating System

Tool: `lsb_release`

```bash
$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.4 LTS
Release:        24.04
Codename:       noble
```

#### Kernel

Tool: `uname`

```bash
$ uname -a
Linux ubuntuserver 6.8.0-101-generic #101-Ubuntu SMP PREEMPT_DYNAMIC Mon Feb  9 10:15:05 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

#### CPU Details

Tools: `lscpu`, `cat /proc/cpuinfo`

```bash
$ lscpu
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             48 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      2
  On-line CPU(s) list:       0,1
Vendor ID:                   AuthenticAMD
  Model name:                AMD Ryzen 7 7735HS with Radeon Graphics
    CPU family:              25
    Model:                   68
    Thread(s) per core:      1
    Core(s) per socket:      2
    Socket(s):               1
    Stepping:                1
    BogoMIPS:                6387.99
Virtualization features:
  Hypervisor vendor:         KVM
  Virtualization type:       full
Caches (sum of all):
  L1d:                       64 KiB (2 instances)
  L1i:                       64 KiB (2 instances)
  L2:                        1 MiB (2 instances)
  L3:                        32 MiB (2 instances)
```

```bash
$ cat /proc/cpuinfo | grep MHz
cpu MHz        : 3193.998
cpu MHz        : 3193.998
```

#### Memory Information

Tool: `free`

```bash
$ free -h
               total        used        free      shared  buff/cache   available
Mem:            14Gi       440Mi        14Gi       1.0Mi       208Mi        14Gi
Swap:             0B          0B          0B
```

#### Storage Information

Tool: `df`

```bash
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           1.5G  1.1M  1.5G   1% /run
/dev/sda2        25G  2.8G   21G  12% /
tmpfs           7.4G     0  7.4G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           1.5G   12K  1.5G   1% /run/user/1000
```

#### Network Configuration

Tool: `ip`

```bash
$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:5e:ea:a0 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 metric 100 brd 10.0.2.255 scope global dynamic enp0s3
       valid_lft 86132sec preferred_lft 86132sec
    inet6 fd17:625c:f037:2:a00:27ff:fe5e:eaa0/64 scope global dynamic mngtmpaddr noprefixroute
       valid_lft 86385sec preferred_lft 14385sec
    inet6 fe80::a00:27ff:fe5e:eaa0/64 scope link
       valid_lft forever preferred_lft forever
```

#### Virtualization Detection

Tool: `systemd-detect-virt`

```bash
$ systemd-detect-virt
oracle
```

The output `oracle` confirms the system is running inside an Oracle VirtualBox VM.

### Reflection

The most useful tools were `lscpu` and `ip addr` — `lscpu` provides a structured overview of CPU architecture, core count, and virtualization details in a single command, while `ip addr` clearly shows all network interfaces with their addresses. `free -h` and `df -h` are straightforward and human-readable for memory and disk. `systemd-detect-virt` is particularly valuable in DevOps conbashs for detecting virtualization type programmatically.
