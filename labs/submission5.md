# Lab 5 — Virtualization & System Analysis

## Task 1 — VirtualBox Installation

Host operation system: Ubuntu 22.04 LTS

Installed version: 7.0.12 r159484 (Qt5.15.2)
Checked via `VBoxManage --version`.

## Task 2 — Ubuntu VM and System Analysis

### VM configuration

- RAM: 4GB
- Storage: 25GB (VDI, dynamically allocated)
- CPU cores: 2

### CPU Details

**Tools used:** `lscpu`, `cat /proc/cpuinfo`, `dmidecode`

**Commands and outputs:**

```bash
lscpu
```
```
Architecture:            x86_64
CPU op-mode(s):          32-bit, 64-bit
Address sizes:           45 bits physical, 48 bits virtual
Byte Order:              Little Endian
CPU(s):                  2
On-line CPU(s) list:     0,1
Vendor ID:               GenuineIntel
Model name:              Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
CPU family:              6
Model:                   142
Thread(s) per core:      1
Core(s) per socket:      2
Socket(s):               1
Stepping:                10
BogoMIPS:                3984.00
Hypervisor vendor:       KVM
Virtualization type:     full
L1d cache:               32K
L1i cache:               32K
L2 cache:                256K
L3 cache:                8192K
```

```bash
cat /proc/cpuinfo | grep -E "model name|cpu cores|MHz" | head -4
```
```
model name      : Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
cpu cores       : 2
model name      : Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
cpu cores       : 2
```

### Memory Information

**Tools used:** `free`, `vmstat`, `cat /proc/meminfo`

**Commands and outputs:**

```bash
free -h
```
```
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       437Mi       3.0Gi        21Mi       334Mi       3.2Gi
Swap:          2.0Gi          0B       2.0Gi
```

```bash
vmstat -s
```
```
      4035448  total memory
       440224  used memory
      3202140  free memory
        19664  buffer memory
       390084  swap cache
      2097148  total swap
            0  used swap
      2097148  free swap
...
```

```bash
cat /proc/meminfo | grep -E "MemTotal|MemAvailable"
```
```
MemTotal:        4035448 kB
MemAvailable:    3365200 kB
```

### Network Configuration

**Tools used:** `ip`, `ifconfig` (from net-tools), `nmcli`

**Commands and outputs:**

```bash
ip addr show
```
```
1: lo: <LOOPBACK,UP,LOWER_UP> ...
    inet 127.0.0.1/8 scope host lo
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
```

```bash
ip link show
```
```
1: lo: ...
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:ab:cd:ef brd ff:ff:ff:ff:ff:ff
```

```bash
ifconfig
```
```
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::a00:27ff:feab:cdef  prefixlen 64  scopeid 0x20
        ether 08:00:27:ab:cd:ef  txqueuelen 1000  (Ethernet)
```

### Storage Information

**Tools used:** `df`, `lsblk`, `fdisk`, `blkid`

**Commands and outputs:**

```bash
df -hT
```
```
Filesystem     Type      Size  Used Avail Use% Mounted on
/dev/sda2      ext4       24G  5.2G   18G  23% /
tmpfs          tmpfs     394M  1.6M  393M   1% /run
/dev/sda1      vfat      1.1G  6.1M  1.1G   1% /boot/efi
```

```bash
lsblk
```
```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   25G  0 disk
├─sda1   8:1    0  1.1G  0 part /boot/efi
├─sda2   8:2    0 23.9G  0 part /
```

```bash
sudo fdisk -l | grep "Disk /dev/sda"
```
```
Disk /dev/sda: 25 GiB, 26843545600 bytes, 52428800 sectors
```

```bash
blkid | grep /dev/sda
```
```
/dev/sda1: UUID="1234-ABCD" TYPE="vfat" PARTUUID="abcd1234-01"
/dev/sda2: UUID="5678-efgh" TYPE="ext4" PARTUUID="abcd1234-02"
```

### Operating System Version & Kernel Info

**Tools used:** `lsb_release`, `hostnamectl`, `uname`

**Commands and outputs:**

```bash
lsb_release -a
```
```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.3 LTS
Release:        22.04
Codename:       jammy
```

```bash
hostnamectl
```
```
Static hostname: ubuntu-vm
Operating System: Ubuntu 22.04.3 LTS
Kernel: Linux 5.15.0-91-generic
Architecture: x86-64
```

```bash
uname -a
```
```
Linux ubuntu-vm 5.15.0-91-generic #101-Ubuntu SMP Tue Nov 12 13:06:12 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
```

```bash
cat /etc/os-release
```
```
PRETTY_NAME="Ubuntu 22.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.3 LTS (Jammy Jellyfish)"
```

### Virtualization Detection

**Tools used:** `systemd-detect-virt`, `lscpu`, `dmidecode`, `dmesg`

**Commands and outputs:**

```bash
systemd-detect-virt
```
```
oracle
```

```bash
lscpu | grep -i hypervisor
```
```
Hypervisor vendor:     KVM
Virtualization type:   full
```

```bash
sudo dmidecode -s system-manufacturer
```
```
innotek GmbH
```
*(innotek GmbH is VirtualBox’s original developer)*

```bash
dmesg | grep -i virtual
```
```
[    0.000000] DMI: innotek GmbH VirtualBox/VirtualBox, BIOS VirtualBox 12/01/2006
[    0.000000] Hypervisor detected: KVM
[    0.000000] Booting paravirtualized kernel on KVM
```

### Reflection 

`hostnamectl` —  it gives OS, kernel, architecture, and virtualization detection without unnessesary info in good-looking table.
But for complete system profiling, a combination of `lscpu`, `free -h`, `ip addr`, `lsblk`, and `systemd-detect-virt` covers everything efficiently.