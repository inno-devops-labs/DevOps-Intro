# Lab 5 — Virtualization & System Analysis

## Task 1 — VirtualBox Installation

### Host Operating System

```bash
leryamerlen@MacBook-Pro ~ % sw_vers
ProductName:		macOS
ProductVersion:		15.5
BuildVersion:		24F74
```

### Host Hardware

```bash
leryamerlen@MacBook-Pro ~ % system_profiler SPHardwareDataType | grep "Chip\|Processor Name\|Model Name"
Model Name: MacBook Pro
Chip: Apple M3 Pro
```

### VirtualBox Version

```bash
leryamerlen@MacBook-Pro ~ % VBoxManage --version
7.2.6r172322
```

### Installation Notes

VirtualBox was installed on macOS using the official installer from the VirtualBox website.
Since the host machine uses Apple Silicon (Apple M3 Pro), the virtual machine was configured to run an ARM64 version of Ubuntu.

Accessibility permissions were granted in macOS Privacy & Security settings so VirtualBox could receive keyboard input.
Due to the ARM architecture limitations, VirtualBox Guest Additions are not supported, therefore shared clipboard functionality is not available.

## Task 2 — Ubuntu Virtual Machine Setup

### VM Configuration
1. VM Name - Ubuntu24-Lab5
2. OS - Ubuntu 24.04 LTS
3. Architecture - ARM64
4. RAM - 4096 MB
5. CPU Cores - 2
6. Disk Size - 25 GB
7. EFI - Enabled
8. Network Mode - NAT

## CPU Details

### Tools used

- `lscpu`

### Commands

```bash
lscpu
```

### Output

```bash
leryamerlen@Ubuntu24-Lab5:~$ lscpu
Architecture:                    aarch64
CPU op-mode(s):                  64-bit
Byte Order:                      Little Endian
CPU(s):                          2
On-line CPU(s) list:             0,1
Vendor ID:                       Apple
Model name:                      -
Model:                           0
Thread(s) per core:              1
Core(s) per cluster:             2
Socket(s):                       -
Cluster(s):                      1
Stepping:                        0x0
BogoMIPS:                        48.00
Flags:                           fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics
                                 fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop
                                 sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm
                                 ssbs sb paca pacg dcpodp flagm2 frint bf16 afp

NUMA:
NUMA node(s):                    1
NUMA node0 CPU(s):               0,1

Vulnerabilities:
Gather data sampling:            Not affected
Ghostwrite:                      Not affected
Indirect target selection:       Not affected
Itlb multihit:                   Not affected
L1tf:                            Not affected
Mds:                             Not affected
Meltdown:                        Not affected
Mmio stale data:                 Not affected
Old microcode:                   Not affected
Reg file data sampling:          Not affected
Retbleed:                        Not affected
Spec rstack overflow:            Not affected
Spec store bypass:               Mitigation; Speculative Store Bypass disabled via prctl
Spectre v1:                      Mitigation; __user pointer sanitization
Spectre v2:                      Mitigation; CSV2, but not BHB
Srds:                            Not affected
Tsa:                             Not affected
Tsx async abort:                 Not affected
Vmscape:                         Not affected
```

## Memory Information

## Tools used

- `free -h`

### Commands

```bash
free -h
```

### Output

```bash
leryamerlen@Ubuntu24-Lab5:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       915Mi       1.8Gi        32Mi       1.2Gi       2.9Gi
Swap:            0B          0B          0B
```

## Network Configuration

### Tools used

- `ip addr`
- `ip route`

### Commands

```bash
ip addr
ip route
```

### Output

```bash
leryamerlen@Ubuntu24-Lab5:~$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host

2: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:e4:fa:13 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s8
    inet6 fd17:625c:f037:2:d43:e1ca:c22c:5bdf/64 scope global temporary dynamic
    inet6 fd17:625c:f037:2:a00:27ff:fee4:fa13/64 scope global dynamic mngtmpaddr
    inet6 fe80::a00:27ff:fee4:fa13/64 scope link

leryamerlen@Ubuntu24-Lab5:~$ ip route
default via 10.0.2.2 dev enp0s8 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s8 proto kernel scope link src 10.0.2.15 metric 100
```

## Storage Information

### Tools used

- `df -h`
- `lsblk`
- `fdisk -l`

### Commands

```bash
df -h
lsblk
sudo fdisk -l
```

### Output

```bash
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           390M  1.4M  388M   1% /run
/dev/sda2        24G  5.8G   17G  26% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
efivarfs        256K   17K  240K   7% /sys/firmware/efi/efivars
/dev/sda1       1.1G  6.4M  1.1G   1% /boot/efi
tmpfs           390M  112K  390M   1% /run/user/1000

NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0     4K  1 loop /snap/bare/5
loop1    7:1    0    10M  1 loop /snap/snap-store/1271
loop2    7:2    0   503M  1 loop /snap/gnome-42-2204/245
loop3    7:3    0  68.9M  1 loop /snap/core22/2933
loop4    7:4    0 236.1M  1 loop /snap/firefox/7764
loop5    7:5    0   556K  1 loop /snap/snapd-desktop-integration/346
loop6    7:6    0  91.7M  1 loop /snap/gtk-common-themes/1535
loop7    7:7    0  41.6M  1 loop /snap/snapd/25939
sda      8:0    0    25G  0 disk
├─sda1   8:1    0     1G  0 part /boot/efi
└─sda2   8:2    0  23.9G  0 part /

Disk /dev/sda: 25 GiB, 26843545600 bytes, 52428800 sectors
Disk model: HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Disklabel type: gpt

Device      Start      End  Sectors  Size Type
/dev/sda1    2048   2203647  2201600    1G EFI System
/dev/sda2 2203648 52426751 50223104 23.9G Linux filesystem
```

## Operating System Information

### Tools used

- `cat /etc/os-release`
- `uname -a`
- `hostnamectl`

### Commands

```bash
cat /etc/os-release
uname -a
hostnamectl
```

### Output

```bash
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_ID="24.04"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian

Linux Ubuntu24-Lab5 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Fri Jan 16 09:16:28 UTC 2 aarch64 aarch64 aarch64 GNU/Linux

Static hostname: Ubuntu24-Lab5
Operating System: Ubuntu 24.04.4 LTS
Kernel: Linux 6.17.0-14-generic
Architecture: arm64
```

## Virtualization Detection

### Tools used

- `systemd-detect-virt`
- `dmidecode`

### Commands

```bash
systemd-detect-virt
sudo dmidecode -s system-product-name
```

### Output

```bash
leryamerlen@Ubuntu24-Lab5:~$ systemd-detect-virt
none
leryamerlen@Ubuntu24-Lab5:~$ sudo dmidecode -s system-product-name
/sys/firmware/efi/systab: SMBIOS entry point missing
```

## Explanation

The systemd-detect-virt command returned none, which can occur when virtualization detection is limited on ARM-based systems or when the hypervisor does not expose certain virtualization identifiers to the guest system.

The dmidecode command could not retrieve the system product name because SMBIOS information is not available in this environment. This is expected when running Ubuntu inside a VirtualBox virtual machine on Apple Silicon hardware.

Even though the tools cannot fully identify the hypervisor, the system is still running inside a virtualized environment provided by VirtualBox.

## Reflection

In this lab a virtual machine running Ubuntu 24.04 was created and analyzed using several Linux system tools.

The virtual machine was deployed using VirtualBox on a macOS host with Apple Silicon hardware. Because the host uses an ARM-based processor, the guest system was configured to run the ARM64 version of Ubuntu.

Several commands were used to explore different aspects of the system. The `lscpu` command provided information about the CPU architecture and virtual processors. The `free -h` command was used to analyze memory allocation and usage inside the VM. Network configuration was examined using `ip addr` and `ip route`, which revealed that the VM was connected through a NAT interface.

Storage layout and filesystem usage were inspected using `df -h`, `lsblk`, and `fdisk -l`. These tools showed the partition structure and mounted filesystems of the virtual disk.

Operating system details were obtained using `cat /etc/os-release`, `uname -a`, and `hostnamectl`, confirming that the system runs Ubuntu 24.04 LTS.

Finally, virtualization detection tools such as `systemd-detect-virt` and `dmidecode` were tested. Due to the ARM architecture and VirtualBox limitations on Apple Silicon, these tools could not fully identify the hypervisor, even though the system is clearly running inside a virtual machine.

Overall, this lab demonstrated how Linux system utilities can be used to inspect hardware, memory, networking, storage, and operating system configuration inside a virtualized environment.