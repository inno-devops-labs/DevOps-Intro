# Lab 5 — Virtualization & System Analysis

## Host System

OS: macOS 26.2 (25C56)
VirtualBox version: 7.2.6 r172322

## VM Configuration

RAM: 4096 MB
CPU: 2 cores
Disk: 25 GB
OS: Ubuntu 24.04.4 LTS

---

# Operating System Information

Command:
`cat /etc/os-release`

Output:

```
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

Command:
`uname -a`

Output:

```
Linux Ubuntu24 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Fri Jan 16 09:16:28 UTC 2026 aarch64 aarch64 aarch64 GNU/Linux
```

Command:
`hostnamectl`

Output:

```
 Static hostname: Ubuntu24
       Icon name: computer
      Machine ID: 6a22911ebd444d7e9b61145fed18ff16
         Boot ID: 8276994981364b1fbe8c191de6717d2a
Operating System: Ubuntu 24.04.4 LTS
          Kernel: Linux 6.17.0-14-generic
    Architecture: arm64
```

---

# CPU Information

Command:
`lscpu`

Output:

```
Architecture:                aarch64
CPU op-mode(s):              64-bit
Byte Order:                  Little Endian
CPU(s):                      2
On-line CPU(s) list:         0,1
Vendor ID:                   Apple
Model name:                  -
Model:                       0
Thread(s) per core:          1
Core(s) per cluster:         2
Cluster(s):                  1
Stepping:                    0x0
BogoMIPS:                    48.00
Flags:                       fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics
NUMA node(s):                1
NUMA node0 CPU(s):           0,1
```

Command:
`nproc`

Output:

```
2
```

---

# Memory Information

Command:
`free -h`

Output:

```
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       999Mi       1.4Gi        33Mi       1.6Gi       2.8Gi
Swap:             0B          0B          0B
```

Command:
`cat /proc/meminfo | head`

Output:

```
MemTotal:        3987172 kB
MemFree:         1494964 kB
MemAvailable:    2963468 kB
Buffers:           38832 kB
Cached:          1567756 kB
SwapCached:            0 kB
Active:          1861572 kB
Inactive:         354828 kB
Active(anon):     644208 kB
Inactive(anon):        0 kB
```

---

# Network Configuration

Command:
`ip a`

Output:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
    inet 127.0.0.1/8 scope host lo

2: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    link/ether 08:00:27:89:aa:1c
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s8
    inet6 fe80::a00:27ff:fe89:aa1c/64 scope link
```

Command:
`ip route`

Output:

```
default via 10.0.2.2 dev enp0s8 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s8 proto kernel scope link src 10.0.2.15 metric 100
```

Command:
`cat /etc/resolv.conf`

Output:

```
nameserver 127.0.0.53
options edns0 trust-ad
search .
```

---

# Storage Information

Command:
`lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS`

Output:

```
NAME     SIZE TYPE FSTYPE   MOUNTPOINTS
loop0   68.9M loop squashfs /snap/core22/2293
loop1  236.1M loop squashfs /snap/firefox/7764
loop2      4K loop squashfs /snap/bare/5
loop3     10M loop squashfs /snap/snap-store/1271
loop4    503M loop squashfs /snap/gnome-42-2204/245
loop5   91.7M loop squashfs /snap/gtk-common-themes/1535
loop6   41.6M loop squashfs /snap/snapd/25939
loop7    556K loop squashfs /snap/snapd-desktop-integration/346
sda       25G disk
├─sda1     1G part vfat     /boot/efi
└─sda2  23.9G part ext4     /
sr0     1024M rom
```

Command:
`df -hT`

Output:

```
Filesystem     Type      Size  Used Avail Use% Mounted on
tmpfs          tmpfs     390M  1.6M  388M   1% /run
/dev/sda2      ext4       24G  5.4G   17G  25% /
tmpfs          tmpfs     2.0G     0  2.0G   0% /dev/shm
/dev/sda1      vfat      1.1G  6.4M  1.1G   1% /boot/efi
```

---

# Virtualization Detection

Command:
`systemd-detect-virt`

Output:

```
none
```

Command:
`lscpu | grep Hypervisor`

Output:

```
(no hypervisor field detected)
```

Command:
`dmesg | grep -i hypervisor | head`

Output:

```
dmesg: read kernel buffer failed: Operation not permitted
```

---

# Reflection

Most useful tools: `lscpu`, `free`, `ip`, `lsblk`, and `df` because they provide clear information about CPU configuration, memory usage, network interfaces, and storage layout in a single command.

