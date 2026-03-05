## Task 1

### Host Operating System
Host system info:

```bash
cat /etc/os-release

PRETTY_NAME="Ubuntu 22.04.5 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.5 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy
```

### VirtualBox Version

```bash
$ VBoxManage --version
7.1.16r172425
```

### Installation notes

VirtualBox was installed on the host system using the deb package.
No problems were encountered during installation.

# Task 2

## VM Configuration
Ubuntu vm was created with the following configuration:

* Operating System: Ubuntu 24.04.4 LTS (Noble Numbat)
* RAM: 4 GB
* Storage: 25 GB
* CPU: 2 cores

# Operating System Information

```bash
cat /etc/os-release

PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
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
### Analysis

This command reads system information from `/etc/os-release`, which contains metadata about the operating system.
The VM is running Ubuntu 24.04.4 LTS, which is a long-term support release.

# CPU Information

Command: `lscpu`

```bash
lscpu

Architecture:                    x86_64
CPU op-mode(s):                  32-bit, 64-bit
Address sizes:                   39 bits physical, 48 bits virtual
Byte Order:                      Little Endian
CPU(s):                          2
On-line CPU(s) list:             0,1
Vendor ID:                       AuthenticAMD
Model name:                      AMD Ryzen 3 5300U with Radeon GraphicsCPU 
family:                          6
Model:                           142
Thread(s) per core:              1
Core(s) per socket:              2
Socket(s):                       1
Stepping:                        10
BogoMIPS:                        4415.96
Flags:                           fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch pti fsgsbase bmi1 avx2 bmi2 invpcid rdseed adx clflushopt arat md_clear flush_l1d arch_capabilities
Virtualization features:
Hypervisor vendor:               KVM
Virtualization type:             full
Caches (sum of all):
L1d:                             64 KiB (2 instances)
L1i:                             64 KiB (2 instances)
L2:                              512 KiB (2 instances)
L3:                              8 MiB (2 instances)
NUMA:
NUMA node(s):                    1
NUMA node0 CPU(s):               0,1
```
The VM has 2 virtual cpu cores.
The underlying physical CPU is AMD Ryzen 3 5300U with Radeon GraphicsCPU .

# Memory Information

### Tool used

Command: `free -h`

```bash
free -h

               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.1Gi       1.4Gi        36Mi       1.6Gi       2.7Gi
Swap:             0B          0B          0B
```

### Analysis

The VM has approximately 4 gb of RAM.
The system currently uses about 1.1 gb.

# Network Configuration

### Tool used

Command: `ip a`

```bash
$ ip a

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:0a:c9:3c brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
```

### Analysis

The VM uses a VirtualBox NAT network adapter
ip address is typical for virtualbox.

# Storage Information

### Tool used

Command: `df -h`

```bash
df -h

Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.7M  390M   1% /run
/dev/sda2        25G  5.4G   18G  24% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           392M  152K  392M   1% /run/user/1000
```

# Virtualization detection

```bash
$ sudo dmidecode -s system-product-name
VirtualBox
```

The system is running inside a VirtualBox vm
