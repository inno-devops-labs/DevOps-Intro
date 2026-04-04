# Lab 5 — Virtualization & System Analysis



## Task 1 — VirtualBox Installation

### Host operating system and version

Windows 11 Pro (Version 23H2)

### VirtualBox version number

Oracle VirtualBox Manager 7.2.6



Task 2 — Ubuntu VM and System Analysis


### CPU Details

```bash
lscpu
```

```bash
Architecture:       x86_64
  CPU op-mode(s): 32-bit, 64-bit
  Address sizes:    39 bits physical, 48 bits virtual
  Byte Order: Little Endian
CPU(s):              1
  On-line CPU(s) list:   0
Vendor ID:        GenuineIntel
  Model name: 13th Gen Intel(R) Core(TM) i7-13620H
...
```

### Memory Information

```bash
free -h
```

```bash
               total        used        free      shared  buff/cache   available
Mem:           1.9Gi       1.1Gi        67Mi        31Mi       817Mi       791Mi
Swap:             0B          0B          0B
```

### Network Configuration

```bash
ip a
```

```bash
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:d3:da:08 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 85943sec preferred_lft 85943sec
    inet6 fd00::3ecc:760a:db69:2a03/64 scope global temporary dynamic
       valid_lft 86391sec preferred_lft 14391sec
    inet6 fd00::3974:57d4:cacd:45b8/64 scope global dynamic mngtmpaddr noprefixroute
       valid_lft 86391sec preferred_lft 14391sec
    inet6 fe80::d664:4a34:b1d4:31ea/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

### Storage Information

```bash
df -h
```

```bash
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           197M  1.3M  196M   1% /run
/dev/sda1        30G   22G  6.3G  78% /
tmpfs           985M     0  985M   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           197M  128K  197M   1% /run/user/1000
```

### Operating System

```bash
lsb_release -a
```

```bash
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.3 LTS
Release:        24.04
Codename:       noble
```

### Virtualization Detection


```bash
systemd-detect-virt
```

```bash
oracle
```

The most useful tools were `lscpu`, `free -h`, `ip a`, `df -h`, `lsb_release -a` and `systemd-detect-virt`:
- `lscpu` was very helpful because it provides detailed CPU information in a clear and structured format
- `free -h` quickly shows total and available memory in a human-readable way, which makes RAM analysis simple
- `ip a` is essential for checking network interfaces and assigned IP addresses
- `df -h` clearly displays disk usage and filesystem information
- `lsb_release` - a was very useful because it clearly shows the Ubuntu distribution version, release number, and codename. This is important for verifying that the correct OS version is installed
- `systemd-detect-virt` was especially useful to confirm that the system is running inside  a VirtualBox virtual machine
