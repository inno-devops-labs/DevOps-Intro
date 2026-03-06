## Task 1 — VirtualBox Installation

### Host Operating System
Windows 11 Pro 25H2

### VirtualBox Version
7.1.6.17084

### Installation Issues Encountered
No issues encountered during installation.

## Task 2 — Ubuntu VM and System Analysis

### VM Configuration Specifications
- **RAM allocated**: 8192 MB (8 GB)
- **Storage allocated**: 25 GB
- **CPU cores**: 4

### System Information Discovery

#### 1. CPU Details
- **Tool(s) used**: 
  - `lscpu` - displays CPU architecture information
  - `cat /proc/cpuinfo` - shows detailed CPU information from kernel
- **Command(s) used**: 
```
lscpu
cat /proc/cpuinfo | grep -E "model name|cpu cores|processor"
```
- **Complete output**:
```
Architecture: x86_64
CPU(s): 7
Model name: 12th Gen Intel(R) Core(TM) i5-12450H
Hypervisor vendor: KVM
```

#### 2. Memory Information
- **Tool(s) used**: 
  - `free` - displays amount of free and used memory
  - `cat /proc/meminfo` - reports detailed memory information
- **Command(s) used**: 
```
free -h
cat /proc/meminfo | grep MemTotal
```
- **Complete output**:
```
total        used        free      shared  buff/cache   available
Mem:           7.8Gi       1.8Gi       3.6Gi        56Mi       2.4Gi       5.9Gi
Swap:          4.0Gi          0B       4.0Gi
```

#### 3. Network Configuration
- **Tool(s) used**: 
  - `ip` - shows/manipulates routing, devices, policy routing
  - `hostname` - displays system's hostname and IP addresses
- **Command(s) used**: 
```
ip addr show
hostname -I
```
- **Complete output**:
```
1: lo: inet 127.0.0.1/8
2: enp0s3: inet 10.0.2.15/24
```

#### 4. Storage Information
- **Tool(s) used**: 
  - `df` - reports file system disk space usage
  - `lsblk` - lists information about all available block devices
  - `findmnt` - finds mounted filesystems
- **Command(s) used**: 
```
df -h
lsblk -f
```
- **Complete output**:
```
df -h:
/dev/sda2        25G  9.6G   14G  42% /

lsblk -f:
sda2 ext4 319fdf4e-a02f-4604-996d-cafca0b5cfe8   13.6G    39% /
```

#### 5. Operating System Information
- **Tool(s) used**: 
  - `lsb_release` - prints distribution-specific information
  - `uname` - prints system information (kernel, hostname, architecture)
  - `cat /etc/os-release` - shows OS identification data
- **Command(s) used**: 
```
lsb_release -a
uname -a
cat /etc/os-release | grep PRETTY_NAME
```
- **Complete output**:
```
Distributor ID: Ubuntu
Description: Ubuntu 24.04.4 LTS
Release: 24.04
Codename: noble
Linux lev-VirtualBox 6.17.0-14-generic #14```24.04.1-Ubuntu SMP x86_64
```

#### 6. Virtualization Detection
- **Tool(s) used**: 
  - `systemd-detect-virt` - detects virtualization environment
  - `dmidecode` - dumps DMI (SMBIOS) table information
  - `lspci` - lists all PCI devices
- **Command(s) used**: 
```
systemd-detect-virt
sudo dmidecode -s system-manufacturer
lspci | grep -i virtualbox
```
- **Complete output**:
```
oracle
innotek GmbH
```

### Reflection
The most useful tools were lscpu for structured CPU information, free -h for quick memory overview in human-readable format, and df -h for disk usage analysis. The systemd-detect-virt command concisely confirmed the virtualized environment by returning "oracle" for VirtualBox.