# Lab 5 Submission

## Task 1 — VirtualBox Installation

- Host OS and version: Windows 11
- VirtualBox version: 7.2.4
- Installation issues: vmwgfx error fixed by adjusting display settings

---

## Task 2 — Ubuntu VM and System Analysis

### 2.1 VM Configuration

- RAM: 4096 MB
- CPU cores: 2
- Storage: 25 GB
- ISO source: https://ubuntu.com/download/desktop

---

### 2.2 System Information Discovery

#### Operating System

Tools: lsb_release, uname

Commands:
- lsb_release -a
- uname -a

Output:
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.4 LTS
Release:        24.04
Codename:       noble

Linux ubuntu 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
---

#### CPU Details

Tool: lscpu

Command:
- lscpu

Output:
Architecture:                         x86_64
CPU op-mode(s):                       32-bit, 64-bit
Address sizes:                        48 bits physical, 48 bits virtual
Byte Order:                           Little Endian
CPU(s):                               2
On-line CPU(s) list:                  0,1
Vendor ID:                            AuthenticAMD
Model name:                           AMD Ryzen 5 5600H with Radeon Graphics
CPU family:                           25
Model:                                80
Thread(s) per core:                   1
Core(s) per socket:                   2
Socket(s):                            1
Hypervisor vendor:                    KVM
Virtualization type:                  full

---

#### Memory Information

Tool: free

Command:
- free -h

Output:
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.3Gi       1.2Gi        38Mi       1.6Gi       2.5Gi
Swap:          3.8Gi          0B       3.8Gi

---

#### Network Configuration

Tool: ip

Commands:
- ip a
- ip route

Output:
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3

default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100

---

#### Storage Information

Tools: df, lsblk

Commands:
- df -hT
- lsblk -f

Output:
Filesystem     Type   Size  Used Avail Use% Mounted on
/dev/sda2      ext4    25G  9.3G   14G  40% /

---

#### Virtualization Detection

Tool: systemd-detect-virt

Command:
- systemd-detect-virt

Output:
oracle

---

### Brief Reflection

The most useful tools were lscpu, ip, and df because they provide concise and comprehensive system information. These commands allow quick inspection of hardware, network, and storage configuration inside the virtual machine.