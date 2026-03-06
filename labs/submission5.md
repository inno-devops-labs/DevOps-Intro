## Task 1 - VirtualBox Installation

**Host operating system:**  
Windows 11 Home Single Language, Version 25H2 (Build 26200.7840)

**VirtualBox version:**  
VirtualBox 7.2.6 r172322 (Qt 6.8.0 on Windows)

**Installation notes:**  
VirtualBox was downloaded from the official website and installed using the default GUI installer settings.  
The installation completed successfully without any issues. No additional configuration was required.

**Verification:**  
VirtualBox was launched successfully after installation, and the version information was confirmed through the graphical interface.

**Screenshot:**  
The screenshot below shows the host operating system information.



# Task 2 — Ubuntu VM and System Analysis

## VM Configuration

The Ubuntu virtual machine was created with the following configuration:

- OS: Ubuntu 24.04.4 LTS
- RAM: 4096 MB
- CPU: 2 cores
- Storage: 25 GB
- Network Mode: NAT

---

# Operating System Information


### Command

```bash
$ cat /etc/os-release
```

### Output
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian

# CPU Information

### Command
```bash
$ lscpu
```

### Output
Architecture:                    x86_64
CPU op-mode(s):                  32-bit, 64-bit
Byte Order:                      Little Endian
CPU(s):                          2
On-line CPU(s) list:             0,1
Vendor ID:                       GenuineIntel
Model name:                      Intel(R) Core(TM) i5-8250U CPU @ 1.60GHz
CPU family:                      6
Model:                           142
Thread(s) per core:              1
Core(s) per socket:              2
Socket(s):                       1
Hypervisor vendor:               Oracle
Virtualization type:             full


# Memory Information


### Command
```bash
$ free -h
```

### Output
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.0Gi       1.5Gi        35Mi       1.3Gi       2.6Gi
Swap:            0B          0B          0B


# Network Configuration


### Command
```bash
$ ip a
```

### Output
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
    inet 127.0.0.1/8 scope host lo

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    link/ether 08:00:27:0a:c9:3c brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic
 
# Storage Information

### Command
```bash
$ df -h
```

### Output
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.7M  390M   1% /run
/dev/sda2        25G  5.4G   18G  24% /
tmpfs           2.0G     0  2.0G   0% /dev/shm


# Additional Disk Details

``` bash
$ lsblk
```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0    25G  0 disk
├─sda1   8:1    0     1G  0 part /boot/efi
└─sda2   8:2    0    24G  0 part /

# Virtualization Detection
Tool
``` bash
$ systemd-detect-virt
```

### Output

oracle
Tool
``` bash
$ sudo dmidecode -s system-product-name
```

### Output

VirtualBox

# Reflection

Several Linux command-line utilities were used to inspect the system configuration of the virtual machine.

The lscpu command provided detailed information about the processor architecture and number of virtual CPU cores assigned to the VM.
The free -h command was used to analyze memory allocation and usage inside the virtual machine.

Network configuration was examined using ip a, which revealed that the system was connected through a VirtualBox NAT network adapter with an automatically assigned IP address.

Disk usage and filesystem layout were inspected using df -h and lsblk. These tools confirmed that the VM was using a virtual disk with a capacity of approximately 25 GB.

Finally, virtualization detection tools such as systemd-detect-virt and dmidecode confirmed that the operating system is running inside a VirtualBox virtual machine.

Overall, this lab demonstrated how Linux system utilities can be used to explore CPU, memory, storage, networking, and operating system configuration inside a virtualized environment.