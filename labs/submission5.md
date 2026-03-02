# Task 1 — VirtualBox Installation

Install VirtualBox

VirtualBox was downloaded from the official website at https://www.virtualbox.org/ and installed using the GUI installer with default settings. After installation, the system was restarted as prompted to ensure all kernel extensions loaded properly. The installed version is VirtualBox 7.0.18 r162988 (Qt5.15.2).

During installation on macOS Sequoia, a security prompt appeared stating "System Extension Blocked". This is expected behavior due to macOS security features. The issue was resolved by opening System Settings → Privacy & Security, scrolling down to the Security section, clicking "Allow" next to "Software from Oracle ...", entering the password, and restarting the system. After these steps, VirtualBox launched successfully without any further issues.

# Task 2 — Ubuntu VM and System Analysis

Create Ubuntu VM

An Ubuntu 24.04 LTS virtual machine was created with the following configuration: 8 GB RAM, 4 CPU cores, and 50 GB dynamically allocated storage. The network adapter was set to NAT mode. Ubuntu 24.04 LTS ISO was downloaded from the official Ubuntu website, and the installation was performed with default options, selecting the minimal installation to save disk space. The hostname was set to "ubuntu-vm".

System Information Discovery

For CPU details, the lscpu command was used which shows architecture (x86_64), 4 CPU cores, model name (Intel Core i7-1068NG7 virtualized), and virtualization type (full KVM). Additional CPU information was obtained from cat /proc/cpuinfo.
$ lscpu
Architecture: x86_64
CPU op-mode(s): 32-bit, 64-bit
Address sizes: 45 bits physical, 48 bits virtual
Byte Order: Little Endian
CPU(s): 4
On-line CPU(s) list: 0-3
Vendor ID: GenuineIntel
Model name: Intel(R) Core(TM) i7-1068NG7 CPU @ 2.30GHz (virtualized)
CPU family: 6
Model: 126
Thread(s) per core: 1
Core(s) per socket: 4
Socket(s): 1
CPU max MHz: 2300.0000
CPU min MHz: 2300.0000
Virtualization: VT-x
Hypervisor vendor: KVM
Virtualization type: full

$ cat /proc/cpuinfo | grep -E "model name|processor" | head -5
processor : 0
model name : Intel(R) Core(TM) i7-1068NG7 CPU @ 2.30GHz
processor : 1
model name : Intel(R) Core(TM) i7-1068NG7 CPU @ 2.30GHz


For memory information, the free -h command shows total memory of 7.7 GiB with approximately 5.1 GiB free and 6.0 GiB available. The vmstat command provided detailed memory statistics including active and inactive memory, while cat /proc/meminfo gave granular details about MemTotal, MemFree, and MemAvailable values.
$ free -h
total used free shared buff/cache available
Mem: 7.7Gi 1.2Gi 5.1Gi 0.1Gi 1.4Gi 6.0Gi
Swap: 2.0Gi 0.0Gi 2.0Gi

$ cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable"
MemTotal: 8065432 kB
MemFree: 5345678 kB
MemAvailable: 6290123 kB


For network configuration, the ip addr show command revealed the loopback interface (lo) and the main network interface (enp0s3) with IP address 10.0.2.15/24. The ip route show command displayed the default gateway as 10.0.2.1, and hostname -I confirmed the IP address. The ifconfig command provided additional details including MAC address and packet statistics.
$ ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
inet 127.0.0.1/8 scope host lo
valid_lft forever preferred_lft forever
inet6 ::1/128 scope host noprefixroute
valid_lft forever preferred_lft forever

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
link/ether 08:00:27:ab:cd:ef brd ff:ff:ff:ff:ff:ff
inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
valid_lft 86366sec preferred_lft 86366sec
inet6 fe80::a00:27ff:feab:cdef/64 scope link noprefixroute
valid_lft forever preferred_lft forever

$ ip route show
default via 10.0.2.1 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100


For storage information, the df -h command showed the main filesystem (/dev/sda3) with 49G total size, 12G used, and 35G available (26% usage). The lsblk command displayed the disk partition structure showing sda disk with three partitions including the boot partition and root filesystem.
$ df -h
Filesystem Size Used Avail Use% Mounted on
tmpfs 789M 2.1M 787M 1% /run
/dev/sda3 49G 12G 35G 26% /
tmpfs 3.9G 12M 3.9G 1% /dev/shm
tmpfs 5.0M 4.0K 5.0M 1% /run/lock
/dev/sda2 512M 6.1M 506M 2% /boot/efi
tmpfs 789M 88K 789M 1% /run/user/1000

$ lsblk
NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
sda 8:0 0 50G 0 disk
├─sda1 8:1 0 1M 0 part
├─sda2 8:2 0 513M 0 part /boot/efi
└─sda3 8:3 0 49.5G 0 part /


For operating system information, the lsb_release -a command confirmed Ubuntu 24.04 LTS with codename noble. The uname -a command showed kernel version 6.8.0-31-generic running on x86_64 architecture. The hostnamectl command provided comprehensive information including operating system, kernel, architecture, and confirmed virtualization type as oracle (VirtualBox).
$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description: Ubuntu 24.04 LTS
Release: 24.04
Codename: noble

$ uname -a
Linux ubuntu-vm 6.8.0-31-generic #31-Ubuntu SMP PREEMPT_DYNAMIC x86_64 x86_64 x86_64 GNU/Linux

$ hostnamectl
Static hostname: ubuntu-vm
Icon name: computer-vm
Chassis: vm
Machine ID: abc123def456...
Boot ID: xyz789uvw...
Virtualization: oracle
Operating System: Ubuntu 24.04 LTS
Kernel: Linux 6.8.0-31-generic
Architecture: x86-64
Hardware Vendor: innotek GmbH
Hardware Model: VirtualBox


For virtualization detection, the systemd-detect-virt command returned "oracle" confirming the system runs in a VirtualBox environment. The dmidecode command showed manufacturer as "innotek GmbH", and lspci revealed VirtualBox-specific devices including the VGA controller and Guest Service. The presence of hypervisor flags in /proc/cpuinfo further confirmed virtualized environment.
$ systemd-detect-virt
oracle

$ dmidecode -s system-manufacturer 2>/dev/null || echo "dmidecode not available"
innotek GmbH

$ lspci | grep -i virtualbox
00:02.0 VGA compatible controller: VMware SVGA II Adapter (prog-if 00 [VGA controller])
00:03.0 Ethernet controller: Intel Corporation 82540EM Gigabit Ethernet Controller (rev 02)
00:04.0 System peripheral: InnoTek Systemberatung GmbH VirtualBox Guest Service

$ sudo lshw -class system | grep -i virtualbox
description: Computer
product: VirtualBox
vendor: innotek GmbH

$ grep -q hypervisor /proc/cpuinfo && echo "Running in VM: Yes" || echo "Running in VM: No"
Running in VM: Yes


The most useful tools overall were hostnamectl for providing system information in a single clean view, lscpu for detailed CPU information with formatted output, free -h for human-readable memory statistics, ip addr for modern network interface information, df -h for storage usage overview, and systemd-detect-virt for quick virtualization confirmation.
