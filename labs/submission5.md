# Lab 5

## Task 1 - Install VirtualBox

- Host OS: `Windows 11 IoT Enterprise LTSC 24H2`
- VirtualBox version: `7.2.4 r170995`
- Installation issues: none

## Task 2 - Ubuntu VM and system analysis

### VM config

- Guest OS: `Ubuntu 24.04.4 LTS`
- CPU: `4 vCPU`
- RAM: `4.1 GiB`
- Storage: `25 GiB` virtual disk (`/dev/sda2`, `ext4`)
- Network: NAT (`enp0s3`, `10.0.2.15/24`)

### 1) CPU details

Ran:

```bash
lscpu
```

Output:

```
Architecture:                x86_64
CPU op-mode(s):              32-bit, 64-bit
Address sizes:               48 bits physical, 48 bits virtual
Byte Order:                  Little Endian
CPU(s):                      4
On-line CPU(s) list:         0-3
Vendor ID:                   AuthenticAMD
Model name:                  AMD Ryzen 7 7840HS w/ Radeon 780M Graphics
CPU family:                  25
Model:                       116
Thread(s) per core:          1
Core(s) per socket:          4
Socket(s):                   1
Stepping:                    1
BogoMIPS:                    7585.26
Virtualization features:
Hypervisor vendor:           KVM
Virtualization type:         full
NUMA node(s):                1
NUMA node0 CPU(s):           0-3
```

Also checked CPU frequency:

Ran:

```bash
grep -m1 -i "cpu MHz" /proc/cpuinfo
lscpu -e=CPU,MHZ,MAXMHZ,MINMHZ | head
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
```

Output:

```
cpu MHz		: 3792.634
CPU       MHZ MAXMHZ MINMHZ
  0 3792.6340      -      -
  1 3792.6340      -      -
  2 3792.6340      -      -
  3 3792.6340      -      -
cat: /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq: No such file or directory
```

### 2) Memory info

Ran:

```bash
free -h
```

Output:

```
               total        used        free      shared  buff/cache   available
Mem:           4.1Gi       1.2Gi       1.6Gi        35Mi       1.5Gi       2.8Gi
Swap:             0B          0B          0B
```

### 3) Network config

Ran:

```bash
ip a
ip r
resolvectl status
```

Output (`ip a`):

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:c1:9b:a0 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86284sec preferred_lft 86284sec
    inet6 fd17:625c:f037:2:73c8:1d91:13f7:815c/64 scope global temporary dynamic
       valid_lft 86386sec preferred_lft 14386sec
    inet6 fd17:625c:f037:2:a00:27ff:fec1:9ba0/64 scope global dynamic mngtmpaddr
       valid_lft 86386sec preferred_lft 14386sec
    inet6 fe80::a00:27ff:fec1:9ba0/64 scope link
       valid_lft forever preferred_lft forever
```

Output (`ip r`):

```
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
```

Output (`resolvectl status`):

```
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub

Link 2 (enp0s3)
    Current Scopes: DNS
         Protocols: +DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 1.1.1.1
       DNS Servers: 1.1.1.1 192.168.31.1
```

### 4) Storage info

Ran:

```bash
df -hT
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS,MODEL
```

Output (`df -hT`):

```
Filesystem     Type     Size  Used Avail Use% Mounted on
tmpfs          tmpfs    419M  1.5M  417M   1% /run
/dev/sda2      ext4      25G  5.7G   18G  25% /
tmpfs          tmpfs    2.1G     0  2.1G   0% /dev/shm
tmpfs          tmpfs    5.0M  8.0K  5.0M   1% /run/lock
CompArc        vboxsf   477G  382G   96G  81% /media/sf_CompArc
tmpfs          tmpfs    419M  128K  419M   1% /run/user/1000
/dev/sr0       iso9660   51M   51M     0 100% /media/a/VBox_GAs_7.2.4
```

Output (`lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS,MODEL`):

```
NAME     SIZE FSTYPE   TYPE MOUNTPOINTS                         MODEL
loop0     74M squashfs loop /snap/core22/2292
loop1      4K squashfs loop /snap/bare/5
loop2   18.5M squashfs loop /snap/firmware-updater/210
loop3  251.7M squashfs loop /snap/firefox/7766
loop4   91.7M squashfs loop /snap/gtk-common-themes/1535
loop5  531.4M squashfs loop /snap/gnome-42-2204/247
loop6   10.8M squashfs loop /snap/snap-store/1270
loop7   48.1M squashfs loop /snap/snapd/25935
loop8    576K squashfs loop /snap/snapd-desktop-integration/343
sda       25G          disk                                     VBOX HARDDISK
|-sda1     1M          part
\-sda2    25G ext4     part /
sr0     50.7M iso9660  rom  /media/a/VBox_GAs_7.2.4             VBOX CD-ROM
```

### 5) OS info

Ran:

```bash
lsb_release -a
uname -a
cat /etc/os-release
```

Output (`lsb_release -a`):

```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.4 LTS
Release:        24.04
Codename:       noble
```

Output (`uname -a`):

```
Linux DevOps 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```

Output (`cat /etc/os-release`):

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

### 6) Virtualization detection

Ran:

```bash
systemd-detect-virt
lscpu | grep -i hypervisor
```

Output (`systemd-detect-virt`):

```
oracle
```

Output (`lscpu | grep -i hypervisor`):

```
Flags: ... hypervisor ...
Hypervisor vendor: KVM
```

## Reflection

Most useful tools:

- `lscpu` for CPU + virtualization hints in one place
- `ip` + `resolvectl` for network state (interfaces/routes/DNS)
- `df` + `lsblk` for filesystem usage and disk mapping

These were fast to run, easy to read, and I did not need extra packages.
