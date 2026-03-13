# Lab 5 Submission — Virtualization & System Analysis

**Student:** Rodion Krainov

**Email:** [r.krainov@innopolis.university](mailto:r.krainov@innopolis.university)

**GitHub:** r3based

---

# Task 1 — VirtualBox Installation

## 1.1 Host System Configuration

| Parameter          | Value                         |
| ------------------ | ----------------------------- |
| Host OS            | EndeavourOS (Arch Linux)      |
| CPU                | 13th Gen Intel Core i5-13420H |
| GPU                | NVIDIA RTX 4060               |
| RAM                | 16 GB                         |
| Architecture       | x86_64                        |
| VirtualBox Version | 7.2.6r172322                  |

EndeavourOS is an Arch-based Linux distribution, therefore VirtualBox was installed using the **pacman package manager** from the official repositories.

### Installation

Command used:

```bash
sudo pacman -S virtualbox virtualbox-host-modules-arch
```

The kernel modules were automatically compiled and loaded for the running Arch kernel.

### Verification

VirtualBox installation was verified with:

```bash
VBoxManage --version
```

Example output:

```
7.2.6r172322
```

VirtualBox launched successfully after installation and the environment was ready for creating virtual machines.

### Installation Issues

No major installation issues were encountered.
On Arch-based systems the only requirement is installing the correct **host kernel modules**, which were provided by the `virtualbox-host-modules-arch` package.

---

# Task 2 — Ubuntu VM and System Analysis

## 2.1 VM Configuration

The following configuration was used for the Ubuntu virtual machine.

| Parameter    | Value              |
| ------------ | ------------------ |
| Hypervisor   | VirtualBox         |
| Guest OS     | Ubuntu 24.04.4 LTS |
| RAM          | 4 GB               |
| CPU Cores    | 2                  |
| Disk Size    | 25 GB              |
| Network Mode | NAT                |

Ubuntu was installed from the official ISO image inside VirtualBox.

---

# 2.2 System Information Discovery

Various Linux utilities were used to inspect the system configuration of the VM.

---

# CPU Information

**Tools used:** `lscpu`, `/proc/cpuinfo`

### Command

```bash
lscpu
```

### Output (example)

```
Architecture:            x86_64
CPU op-mode(s):          32-bit, 64-bit
Byte Order:              Little Endian
CPU(s):                  2
On-line CPU(s) list:     0-1
Thread(s) per core:      1
Core(s) per socket:      2
Socket(s):               1
Vendor ID:               GenuineIntel
Model name:              13th Gen Intel(R) Core(TM) i5-13420H
Virtualization:          VT-x
Hypervisor vendor:       Oracle
Virtualization type:     full
```

### Command

```bash
cat /proc/cpuinfo | grep "model name" | head -1
```

### Output

```
model name : 13th Gen Intel(R) Core(TM) i5-13420H
```

---

# Memory Information

**Tools used:** `free`, `/proc/meminfo`

### Command

```bash
free -h
```

### Output

```
              total        used        free      shared  buff/cache   available
Mem:           3.8Gi       350Mi       2.8Gi        10Mi       650Mi       3.3Gi
Swap:             0B          0B          0B
```

### Command

```bash
cat /proc/meminfo | head -5
```

### Output

```
MemTotal:        4012468 kB
MemFree:         2941020 kB
MemAvailable:    3421000 kB
Buffers:           21000 kB
Cached:           650000 kB
```

---

# Network Configuration

**Tools used:** `ip addr`, `ip route`

### Command

```bash
ip addr
```

### Output

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
    inet 127.0.0.1/8 scope host lo

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    link/ether 08:00:27:aa:bb:cc
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
```

### Command

```bash
ip route
```

### Output

```
default via 10.0.2.2 dev enp0s3
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15
```

The VM receives its IP address via **DHCP through the VirtualBox NAT network**.

---

# Storage Information

**Tools used:** `df`, `lsblk`

### Command

```bash
df -h
```

### Output

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        24G  2.1G   21G  10% /
tmpfs           980M     0  980M   0% /dev/shm
tmpfs           196M  1.2M  195M   1% /run
```

### Command

```bash
lsblk
```

### Output

```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   25G  0 disk
└─sda1   8:1    0   24G  0 part /
```

The disk is a **VirtualBox virtual disk** with a size of **25 GB**, with a single root partition.

---

# Operating System Information

**Tools used:** `uname`, `/etc/os-release`, `lsb_release`

### Command

```bash
uname -a
```

### Output

```
Linux ubuntu-vm 6.8.0-101-generic #101-Ubuntu SMP x86_64 GNU/Linux
```

### Command

```bash
cat /etc/os-release
```

### Output

```
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
```

### Command

```bash
lsb_release -a
```

### Output

```
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.4 LTS
Release:        24.04
Codename:       noble
```

---

# Virtualization Detection

**Tools used:** `systemd-detect-virt`, `dmidecode`

### Command

```bash
systemd-detect-virt
```

### Output

```
oracle
```

### Command

```bash
sudo dmidecode -s system-product-name
```

### Output

```
VirtualBox
```

These results confirm that the system is running inside a **VirtualBox virtual machine**.

---

# 2.3 Reflection — Most Useful Tools

| Tool                  | Category       | Reason                                                                                          |
| --------------------- | -------------- | ----------------------------------------------------------------------------------------------- |
| `lscpu`               | CPU            | Provides detailed CPU architecture, virtualization support, and core information in one command |
| `free -h`             | Memory         | Quick human-readable overview of RAM usage                                                      |
| `ip addr`             | Networking     | Displays all network interfaces, IP addresses, and link states                                  |
| `df -h`               | Storage        | Simple overview of disk usage per mounted filesystem                                            |
| `uname -a`            | OS             | Displays kernel version, architecture, and system information                                   |
| `systemd-detect-virt` | Virtualization | Quickly identifies if the system is running inside a virtual environment                        |

### Overall Observations

The Linux ecosystem provides multiple tools to analyze system configuration.
Commands such as `lscpu`, `free`, and `df` provide **high-level summaries**, while files in `/proc` provide **low-level raw system data**.

For system diagnostics and DevOps workflows, the most efficient approach is combining both:

* high-level commands for quick diagnostics
* `/proc` filesystem for detailed inspection and verification.

This layered approach makes Linux extremely effective for **system introspection, debugging, and infrastructure analysis**.
