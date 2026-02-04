# Lab 5 Submission - Virtualization & System Analysis

## Task 1 — VirtualBox Installation

### Installation

- **OS**: macOS 15.6.1 (24G90)
- **VirtualBox**: Version 7.2.2 r170484 (Qt6.8.0 on cocoa)
- **No issues were encountered at this stage**

## Task 2 — Ubuntu VM and System Analysis

I have encountered a problem, that Intel/AMD 64 Bit images weren't possible to run on my mac even through virtualization. After researching similar issues and reviewing a reference PR from a friend ([PR #65](https://github.com/inno-devops-labs/F25-DevOps-Intro/pull/65)), I decided to install the same version he used: [Ubuntu 24.04.3 (Noble Numbat)](https://cdimage.ubuntu.com/releases/noble/release/)

### VM Configuration

- **RAM**: 4096 MB (4GB)
- **CPUs**: 2
- **Disk**: 20 GB

### System Information Discovery

#### CPU

**Tools discovered:** `lscpu`, `cat /proc/cpuinfo`, `nproc`

**Commands used:**

```sh
$ lscpu
```

```
Architecture:                aarch64
CPU op-mode(s):            64-bit
Byte Order:                Little Endian
CPU(s):                      2
On-line CPU(s) list:       0-1
Vendor ID:                   Apple
Model name:                -
Model:                   0
Thread(s) per core:      1
Core(s) per cluster:      2
Socket(s):               -
Cluster(s):              1
Stepping:                0x0
BogoMIPS:                48.00
Flags:                   fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics 
                         fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop 
                         sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm
                         sb paca pacg dcpodp flagm2 frint bf16 afp
NUMA:                    
NUMA node(s):              1
NUMA node0 CPU(s):         0-1
Vulnerabilities:         
Gather data sampling:      Not affected
Ghostwrite:                Not affected
Indirect target selection: Not affected
Itlb multihit:             Not affected
L1tf:                      Not affected
Mds:                       Not affected
Meltdown:                  Not affected
Mmio stale data:           Not affected
Reg file data sampling:    Not affected
Retbleed:                  Not affected
Spec rstack overflow:      Not affected
Spec store bypass:         Vulnerable
Spectre v1:                Mitigation; __user pointer sanitization
Spectre v2:                Mitigation; CSV2, but not BHB
Srbds:                     Not affected
Tsx async abort:           Not affected
```

#### Memory

**Tools discovered:** `free`, `cat /proc/meminfo`, `vmstat`

**Commands used:**

```sh
$ free -h
```

```
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       892Mi       2.5Gi        28Mi       456Mi       3.0Gi
Swap:             0B          0B          0B
```

```sh
$ vmstat -s
```

```
      3987456 K total memory
       914432 K used memory
        987648 K active memory
       184832 K inactive memory
      2621440 K free memory
        32768 K buffer memory
       467968 K swap cache
            0 K total swap
            0 K used swap
            0 K free swap
          512 non-nice user cpu ticks
           32 nice user cpu ticks
          491 system cpu ticks
        60949 idle cpu ticks
          118 IO-wait cpu ticks
            0 IRQ cpu ticks
           21 softirq cpu ticks
            0 stolen cpu ticks
            0 non-nice guest cpu ticks
            0 nice guest cpu ticks
       361772 K paged in
        12102 K paged out
            0 pages swapped in
            0 pages swapped out
        78418 interrupts
       139877 CPU context switches
   1759397297 boot time
         1530 forks
```

#### Network

**Tools discovered:** `ip`, `hostname`, `ss`, `netstat`

**Commands used:**

```sh
$ ip addr show
```

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:a4:c2:9e brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86057sec preferred_lft 86057sec
    inet6 fd17:625c:f037:2:7a3b:4c2f:9e1a:8b2d/64 scope global temporary dynamic 
       valid_lft 86058sec preferred_lft 14058sec
    inet6 fd17:625c:f037:2:a00:27ff:fea4:c29e/64 scope global dynamic mngtmpaddr 
       valid_lft 86058sec preferred_lft 14058sec
    inet6 fe80::a00:27ff:fea4:c29e/64 scope link 
       valid_lft forever preferred_lft forever
```

```sh
$ hostname -I
```

```
10.0.2.15 fd17:625c:f037:2:7a3b:4c2f:9e1a:8b2d fd17:625c:f037:2:a00:27ff:fea4:c29e 
```

#### Storage

**Tools discovered:** `df`, `lsblk`, `fdisk`, `du`

**Commands used:**

```sh
$ df -h
```

```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           391M  1.2M  390M   1% /run
/dev/sda2        19G  4.2G   14G  24% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
efivarfs        256K  102K  155K  40% /sys/firmware/efi/efivars
/dev/sda1       1.1G  6.4M  1.1G   1% /boot/efi
tmpfs           391M   60K  391M   1% /run/user/1000
/dev/sr0         51M   51M     0 100% /media/user/VBox_GAs_7.2.21
```

```sh
$ lsblk -f
```

```
NAME FSTYPE FSVER LABEL          UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0
     squash 4.0                                                             0   100% /snap/bare/5
loop1
     squash 4.0                                                             0   100% /snap/core22/2049
loop2
     squash 4.0                                                             0   100% /snap/gnome-42-2204/201
loop3
     squash 4.0                                                             0   100% /snap/firefox/6563
loop4
     squash 4.0                                                             0   100% /snap/gtk-common-themes/1535
loop5
     squash 4.0                                                             0   100% /snap/snap-store/1271
loop6
     squash 4.0                                                             0   100% /snap/snapd/24787
loop7
     squash 4.0                                                             0   100% /snap/snapd-desktop-integration/316
sda                                                                              
├─sda1
│    vfat   FAT32                618C-0389                                 1G     1% /boot/efi
└─sda2
     ext4   1.0                  8cf5a297-b38f-4e24-91c2-2f35eeb8478e   14G    24% /
sr0  iso966 Jolie VBox_GAs_7.2.2 2025-09-10-17-10-16-91                     0   100% /media/user/VBox_GAs_7.2.21
```

#### OS Information

**Tools discovered:** `hostnamectl`, `uname`, `lsb_release`, `cat /etc/os-release`

**Commands used:**

```sh
$ hostnamectl
```

```
 Static hostname: lab5-arthur-vm
       Icon name: computer
      Machine ID: aa5b90af40dc4111817f6285972a601e
         Boot ID: 457da82c8fd942df9b897e00179ec8e3
Operating System: Ubuntu 24.04.3 LTS          
          Kernel: Linux 6.14.0-33-generic
    Architecture: arm64
```

```sh
$ uname -a
```

```
Linux lab5-arthur-vm 6.14.0-33-generic #33~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Nov 6 18:20:15 UTC 2025 aarch64 aarch64 aarch64 GNU/Linux
```

```sh
$ lsb_release -a
```

```
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 24.04.3 LTS
Release:	24.04
Codename:	noble
```

### Virtualization Detection

**Tools discovered:** `dmesg`, `lsmod`, `lspci`, `systemd-detect-virt` (didn't work), `virt-what` (didn't work), `dmidecode` (didn't work)

When trying to detect virtualization, I ran into some unexpected behavior. The standard commands like `systemd-detect-virt` just returned "none", and `virt-what` gave me nothing at all. Even `dmidecode` failed because the SMBIOS tables weren't available.

Turns out this is a known thing with VirtualBox on Apple Silicon - the ARM port doesn't expose virtualization info the same way. So I had to dig deeper and use alternative methods to confirm we're actually running in a VM.

**Commands used:**

```sh
$ sudo dmesg | grep -i virtual
```

```
[    0.446990] usb 1-1: Manufacturer: VirtualBox
[    0.683089] usb 1-2: Manufacturer: VirtualBox
[    0.691243] input: VirtualBox USB Keyboard as /devices/pci0000:00/0000:00:06.0/usb1/1-1/1-1:1.0/0003:80EE:0010.0001/input/input0
[    0.742844] hid-generic 0003:80EE:0010.0001: input,hidraw0: USB HID v1.10 Keyboard [VirtualBox USB Keyboard] on usb-0000:00:06.0-1/input0
[    0.743045] input: VirtualBox USB Tablet as /devices/pci0000:00/0000:00:06.0/usb1/1-2/1-2:1.0/0003:80EE:0021.0002/input/input1
[    0.743348] hid-generic 0003:80EE:0021.0002: input,hidraw1: USB HID v1.10 Mouse [VirtualBox USB Tablet] on usb-0000:00:06.0-2/input0
[    2.316299] input: VirtualBox mouse integration as /devices/pci0000:00/0000:00:01.0/input/input2
```

```sh
$ lsmod | grep vbox
```

```
vboxguest             507904  4
```

```sh
$ lspci | grep -i virtualbox
```

```
00:01.0 System peripheral: InnoTek Systemberatung GmbH VirtualBox Guest Service
```

## Reflection

Most of the tools I needed were already there - no need to install anything extra. `lscpu` and `hostnamectl` gave me all the CPU and OS info I needed right away. For networking, `ip addr` was way more useful than the old `ifconfig`.

The storage commands (`df -h` and `lsblk -f`) worked great together - one shows usage, the other shows the actual device structure.

The virtualization detection was tricky though. Since the standard tools didn't work on Apple Silicon VirtualBox, I had to check kernel messages and loaded modules instead. `dmesg` and `lsmod` saved the day here - they clearly showed VirtualBox devices and modules running.

Bottom line: Linux has pretty much everything built-in for system analysis.
