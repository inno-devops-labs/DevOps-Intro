# Lab 5 Submission

## Task 1 - VirtualBox Installation

### 1.1. Install VirtualBox

I installed `VirtualBox` on my Windows 11 system using the official installer with default settings.

### 1.2. Verify Installation

#### VirtualBox version number

I opened VirtualBox and checked the installed version.

VirtualBox version number - `7.2.4 r170995`


### Host operating system and version

`Windows 11 25H2`


### Installation issues encountered

No installation issues were encountered. The installation process completed successfully.


## Task 2 - Ubuntu VM and System Analysis

### 2.1. VM Setup

I created a new virtual machine and configured it with the following parameters:

- OS Version: `Ubuntu-24.04.4`
- RAM: `6144` MB
- CPU: `2` cores
- Storage: `30` GB

### 2.2. System Information Discovery

#### CPU Details

I used the `lscpu` command to check CPU architecture and core information:

```bash
user@user-pc:~$ lscpu
Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          39 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   2
  On-line CPU(s) list:    0,1
Vendor ID:                GenuineIntel
  Model name:             13th Gen Intel(R) Core(TM) i5-13420H
    CPU family:           6
    Model:                186
    Thread(s) per core:   1
    Core(s) per socket:   2
    Socket(s):            1
    Stepping:             2
    BogoMIPS:             5222.39
    Flags:                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxs
                          r sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpu
                          id tsc_known_freq pni ssse3 cx16 sse4_1 sse4_2 x2apic movbe popcnt hypervisor lahf_lm a
                          bm fsgsbase bmi1 bmi2 invpcid arat md_clear flush_l1d arch_capabilities
Virtualization features:  
  Hypervisor vendor:      KVM
  Virtualization type:    full
Caches (sum of all):      
  L1d:                    96 KiB (2 instances)
  L1i:                    64 KiB (2 instances)
  L2:                     2.5 MiB (2 instances)
  L3:                     24 MiB (2 instances)
NUMA:                     
  NUMA node(s):           1
  NUMA node0 CPU(s):      0,1
Vulnerabilities:          
  Gather data sampling:   Not affected
  Ghostwrite:             Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Vulnerable: No microcode
  Retbleed:               Not affected
  Spec rstack overflow:   Not affected
  Spec store bypass:      Vulnerable
  Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:             Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI SW l
                          oop, KVM SW loop
  Srbds:                  Not affected
  Tsx async abort:        Not affected

```

The output shows:
- Architecture: `x86_64`
- `2 CPU cores` assigned
- `Intel` processor model
- `Full virtualization` enabled

This confirms that the VM uses `2 cores` and runs in a `virtualized environment`.

#### Memory Information

I used the `free -h` command to check RAM usage:

```bash
user@user-pc:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:           5.8Gi       786Mi       4.6Gi        11Mi       691Mi       5.0Gi
Swap:             0B          0B          0B
```

The output shows:
- Total memory: `5.8` GiB
- Most memory is `available`
- No `swap space` configured

This confirms that around `6 GB` RAM is allocated to the VM.


#### Network Configuration

I used the `ip a` and `hostname -I` commands to check network interfaces and IP addresses:

```bash
user@user-pc:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:d3:da:08 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86000sec preferred_lft 86000sec
    inet6 fd17:625c:f037:2:ea1b:5f56:fd36:c59a/64 scope global temporary dynamic 
       valid_lft 86319sec preferred_lft 14319sec
    inet6 fd17:625c:f037:2:ad1e:99b0:1de4:dd73/64 scope global dynamic mngtmpaddr noprefixroute 
       valid_lft 86319sec preferred_lft 14319sec
    inet6 fe80::d664:4a34:b1d4:31ea/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever

user@user-pc:~$ hostname -I
10.0.2.15 fd17:625c:f037:2:ea1b:5f56:fd36:c59a fd17:625c:f037:2:ad1e:99b0:1de4:dd73 
```

The output shows:
- Loopback interface (lo)
- Main network interface (enp0s3)
- IPv4 address: `10.0.2.15`

This confirms that the VM is connected to the network using `NAT configuration`.


#### Storage Information

I used the `df -h` command to check disk usage:

```bash
user@user-pc:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           593M  1.2M  592M   1% /run
/dev/sda1        30G   23G  5.7G  80% /
tmpfs           2.9G     0  2.9G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
shared          200G  148G   53G  74% /home/user/shared
tmpfs           593M  120K  593M   1% /run/user/1000
```

The output shows:
- Root partition size: `30G`
- `23G` used
- `5.7G` available

This confirms that the virtual disk is correctly mounted and working.


#### Operating System

I used `cat /etc/os-release` and `uname -r` to check OS version and kernel versionЖ

```bash
user@user-pc:~$ cat /etc/os-release
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.4 LTS
Release:        24.04
Codename:       noble

user@user-pc:~$ uname -r
6.17.0-14-generic
```

The output shows:
- `Ubuntu 24.04.4 LTS`
- Kernel version `6.17.0-14-generic`

This confirms that the system is running `Ubuntu 24.04 LTS`.


#### Virtualization Detection

I used `systemd-detect-virt` and `dmidecode` to confirm virtualization:

```bash
user@user-pc:~$ systemd-detect-virt
oracle

user@user-pc:~$ sudo dmidecode | grep -i virtual
[sudo] password for user: 
        Version: VirtualBox
        Product Name: VirtualBox
        Family: Virtual Machine
        Product Name: VirtualBox
```

The output shows:
- Virtualization: `oracle`
- Hardware model: `VirtualBox`

This confirms that the system is running inside `VirtualBox`.


#### Brief reflection

During this lab, I explored basic Linux system commands to analyze hardware and OS information.
The most useful tools were `lscpu`, `free`, `ip`, and `df` because they provide clear and structured system data.
The command `systemd-detect-virt` was especially helpful to confirm virtualization.
This lab helped me better understand how to inspect system configuration inside a `virtual machine`.