# Task 1

## VirtualBox Installation

My host OS is macOS Tahoe 26.3 (build 25D125), running on a Mac.

I downloaded VirtualBox from the official website and installed it using the default GUI installer. After installation I restarted my Mac as it was prompted.

VirtualBox version: `7.2.6 `

No major issues during the VirtualBox installation itself. However, I had a hard time getting data out of the VM. Shared clipboard did not work, shared folders did not mount, and I could not copy command outputs from the Ubuntu terminal. Eventually I solved it by running a Python HTTP server inside the VM (`python3 -m http.server 8080`), setting up NAT port forwarding with `VBoxManage`, and downloading the output file from the host using `curl`.

# Task 2

## 2.1 Ubuntu VM Setup

I downloaded Ubuntu 25.10 ISO from the official Ubuntu website. I could not use Ubuntu 24.04 LTS because it does not support ARM architecture, and my Mac has an ARM-based chip. Ubuntu 25.10 has ARM support so I used that instead. Then I created a new VM in VirtualBox with the following configuration:

- RAM: 4 GB
- Storage: 25 GB (dynamically allocated)
- CPU: 2 cores

I attached the ISO to the VM and went through the default Ubuntu installation process. Everything installed without problems.

## 2.2 System Information Discovery

### CPU Details

Tool: `lscpu`

Command: `lscpu`

```
Architecture:                            aarch64
CPU op-mode(s):                          64-bit
Byte Order:                              Little Endian
CPU(s):                                  2
On-line CPU(s) list:                     0,1
Vendor ID:                               Apple
Model name:                              -
Model:                                   0
Thread(s) per core:                      1
Core(s) per cluster:                     2
Socket(s):                               -
Cluster(s):                              1
Stepping:                                0x0
BogoMIPS:                                48.00
Flags:                                   fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm ssbs sb paca pacg dcpodp flagm2 frint bf16
```

The VM has 2 CPU cores with aarch64 (ARM) architecture, provided by the Apple silicon chip on the host.

### Memory Information

Tool: `free`

Command: `free -h`

```
               total        used        free      shared  buff/cache   available
Mem:           3.3Gi       1.1Gi       974Mi        24Mi       1.4Gi       2.2Gi
Swap:             0B          0B          0B
```

Total RAM is 3.3 GB (I allocated 4 GB in VirtualBox, some is used by the system overhead). No swap configured.

### Network Configuration

Tool: `ip`

Command: `ip a`

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:3c:d4:54 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s8
       valid_lft 86296sec preferred_lft 86296sec
    inet6 fd17:625c:f037:2:a00:27ff:fe3c:d454/64 scope global dynamic noprefixroute
       valid_lft 86298sec preferred_lft 14298sec
    inet6 fe80::a00:27ff:fe3c:d454/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

The VM has a loopback interface and one network adapter `enp0s8` with IP `10.0.2.15` (NAT mode in VirtualBox).

### Storage Information

Tool: `df`

Command: `df -h`

```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           677M  1.5M  675M   1% /run
/dev/sda2        24G  6.2G   17G  28% /
tmpfs           1.7G     0  1.7G   0% /dev/shm
efivarfs        256K  6.3K  250K   3% /sys/firmware/efi/efivars
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           1.7G  8.0K  1.7G   1% /tmp
/dev/sda1       1.1G  6.6M  1.1G   1% /boot/efi
tmpfs           339M   88K  339M   1% /run/user/1000
```

The main disk `/dev/sda2` is 24 GB with 6.2 GB used (28%).

### Operating System

Tools: `uname`, `lsb_release`

Command: `uname -a`

```
Linux ubuntu 6.17.0-14-generic #14-Ubuntu SMP PREEMPT_DYNAMIC Fri Jan  9 16:29:17 UTC 2026 aarch64 GNU/Linux
```

Command: `lsb_release -a`

```
Distributor ID: Ubuntu
Description:    Ubuntu 25.10
Release:        25.10
Codename:       questing
```

The VM runs Ubuntu 25.10 (Questing) with kernel 6.17.0-14-generic on aarch64.

### Virtualization Detection

Tool: `systemd-detect-virt`

Command: `systemd-detect-virt`

```
none
```

This command returned `none`, so it did not detect virtualization. This happens on ARM-based VirtualBox setups.

I then tried `dmesg` which successfully confirmed the VM:

Tool: `dmesg`

Command: `dmesg | grep -i virtual`

```
[    0.000000] arch_timer: cp15 timer(s) running at 24.00MHz (virt).
[    0.066474] virtio_scsi virtio0: 2/0/0 default/read/poll queues
[    0.066691] scsi host0: Virtio SCSI HBA
[    0.428337] usb 1-1: Manufacturer: VirtualBox
[    0.436246] input: VirtualBox USB Keyboard as /devices/pci0000:00/0000:00:06.0/usb1/1-1/1-1:1.0/0003:80EE:0010.0001/input/input0
[    0.486918] hid-generic 0003:80EE:0010.0001: input,hidraw0: USB HID v1.10 Keyboard [VirtualBox USB Keyboard] on usb-0000:00:06.0-1/input0
[    0.676253] usb 1-2: Manufacturer: VirtualBox
[    0.678511] input: VirtualBox USB Tablet as /devices/pci0000:00/0000:00:06.0/usb1/1-2/1-2:1.0/0003:80EE:0021.0002/input/input1
[    0.678640] hid-generic 0003:80EE:0021.0002: input,hidraw1: USB HID v1.10 Mouse [VirtualBox USB Tablet] on usb-0000:00:06.0-2/input0
[    2.290426] input: VirtualBox mouse integration as /devices/pci0000:00/0000:00:01.0/input/input3
```

The kernel log clearly shows VirtualBox USB devices (keyboard, tablet, mouse integration), confirming the system is running inside a VirtualBox VM.

### Reflection

`lscpu` and `free -h` were the most useful tools because they give a clear and concise overview of CPU and memory. `df -h` is also very handy for quick disk usage check. `ip a` gives full network info in one command. `systemd-detect-virt` is the simplest way to check for virtualization, although in this case it did not detect VirtualBox on ARM.
