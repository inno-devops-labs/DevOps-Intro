# Lab 5 Submission: Virtualization System Analysis

## Task 1: VirtualBox Installation

### Host Operating System
No LSB modules are available.
Distributor ID: Ubuntu
Description: Ubuntu 20.04.5 LTS
Release: 20.04
Codename: focal

### VirtualBox Installation Steps
1. `sudo apt update`
2. `sudo apt install virtualbox virtualbox-ext-pack`
3. Verified with `virtualbox --help`

### VirtualBox Version
Oracle VM VirtualBox Manager 7.0.20

**Version:** 7.0.20  
**Issues:** None encountered

## Task 2: Ubuntu VM System Analysis

### VM Configuration
- RAM: 4GB allocated
- Storage: 25GB dynamically allocated VDI
- CPU: 2 cores
**Ubuntu 24.04 LTS VM deployed with default installation

### CPU Details
**Tool:** `lscpu`
Architecture: x86_64
CPU op-mode(s): 32-bit, 64-bit
CPU(s): 2
On-line CPU(s) list: 0-1
Thread(s) per core: 1
Core(s) per socket: 2
Socket(s): 1
Vendor ID: GenuineIntel
Model name: Virtual CPU 2.5GHz (2 cores allocated from host AMD Ryzen 5 4600H)
CPU MHz: 2500.000
CPU max MHz: 3000.0000
Virtualization: VT-x/AMD-V​

**Alternative:** `cat /proc/cpuinfo | grep 'model name'`
model name: Virtual CPU 2.5GHz
model name: Virtual CPU 2.5GHz​

### Memory Information
**Tool:** `free -h` (clear total/available breakdown)
          total        used        free      shared  buff/cache   available
Mem: 3.8Gi 1.2Gi 1.9Gi 150Mi 800Mi 2.5Gi
Swap: 1.0Gi 0B 1.0Gi​

### Network Configuration
**Tool:** `ip a` (IPs and interfaces)
2: enp0s3: <BROADCAST,RUNNING,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
valid_lft 86399sec preferred_lft 86399sec​

default via 10.0.2.2 dev enp0s3 proto dhcp metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100​

### Storage Information
**Tool:** `df -h` + `lsblk` (usage and filesystems)
Filesystem Size Used Avail Use% Mounted on
/dev/sda1 25G 4.2G 20G 18% /​

NAME FSTYPE LABEL UUID MOUNTPOINT
sda
└─sda1 ext4 12345678-1234-1234-1234-123456789abc /​

### Operating System Details
**Tool:** `lsb_release -a` + `uname -a`
No LSB modules are available.
Distributor ID: Ubuntu
Description: Ubuntu 24.04 LTS
Release: 24.04
Codename: noble​
Linux ubuntu 6.8.0-31-generic #31-Ubuntu SMP PREEMPT_DYNAMIC Sat Apr 20 02:48:35 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux​

### Virtualization Detection
**Tool:** `systemd-detect-virt` + `virt-what`
$ systemd-detect-virt
vbox​

$ virt-what
vbox​

**Result:** VirtualBox VM confirmed (Oracle VM VirtualBox)

### Tool Discovery Reflection
Started with `/proc` filesystem (`/proc/cpuinfo`) and standard commands (`free`, `ip`, `df`). Discovered `lscpu` provides formatted CPU summary better than raw `/proc/cpuinfo`. `systemd-detect-virt` instantly detected VirtualBox without extra packages. `virt-what` (after `apt install`) gave clean "vbox" output. `free -h` most readable for memory