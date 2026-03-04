# Lab 5 Submission — Virtualization & System Analysis

**Student:** Diana Minnakhmetova  
**Date:** 04-03-2026

---

## Task 1: VirtualBox Installation

[X] Host operating system and version (e.g., "Windows 11 Pro 23H2", "macOS Sonoma 14.1", "Ubuntu 22.04 LTS")

[X] VirtualBox version number

[X] Any installation issues encountered

### Prerequisites

```
dminnakhmetova@MacBook-Air-Diana-3 ~ % VBoxManage --version
7.2.6r172322
dminnakhmetova@MacBook-Air-Diana-3 ~ % sw_vers
ProductName:		macOS
ProductVersion:		15.5
BuildVersion:		24F74
```

### 1.1 Host System Configuration

**OS:** macOS Sequoia 15.5  
**VirtualBox Version:** 7.2.6r172322  
**Installation Method:** GUI installer with default settings  
**Issues Encountered:** None

### 1.2 VirtualBox Verification

VirtualBox launched successfully and version confirmed via `VBoxManage --version`. System ready for VM deployment.


## Task 2: Ubuntu VM & System Analysis

[X] VM configuration specifications used (RAM, storage, CPU cores)

[X] For each information type above:
 - Tool name(s) you discovered
 - Command(s) used
 - Complete command output

[X] Brief reflection on which tools were most useful and why

### 2.1 VM Configuration & Deployment

**VM Setup:**
- Name: DevopsUbuntu
- ISO: ubuntu-24.04.4-server-arm64.iso
- RAM: 4GB (4096 MB)
- CPU Cores: 2
- Storage: 25GB
- OS: Ubuntu 24.04 LTS ARM64

**Issues & Resolution:**
- Initial attempt with Desktop amd64 ISO failed on ARM processor (UEFI boot error)
![Fail on arm](https://github.com/user-attachments/assets/3ebb0543-fe95-4ff7-816e-ea12b581754f)
- Switched to Server ARM64 ISO — deployment successful
- First boot completed without errors

![boot](https://github.com/user-attachments/assets/1eb1421c-33fb-4b44-a308-06df40d4b7aa)


### 2.2 System Information Discovery

#### CPU Details

**Tool:** `lscpu`

![lscpu](https://github.com/user-attachments/assets/4f632403-3007-473d-9454-2149769f1ad3)

**Analysis:**
- Architecture: ARM64 (aarch64) — Apple Silicon native
- CPU Count: 2 cores as configured
- Vendor: Apple (M-series processor)
- BogoMIPS: 48.00
- All vulnerability mitigations enabled


#### Memory Information

**Tool:** `free -h`

![free -h](https://github.com/user-attachments/assets/449c8724-fbc0-4922-8c75-918d53b9fcf6)

**Analysis:**
- Total RAM: 3.8GB (allocated 4GB to VM, kernel optimized)
- Used: 305MB
- Available: 3.5GB (healthy margin)
- No swap configured (not needed)


#### Storage Information

**Tool:** `df -h`

![df -h](https://github.com/user-attachments/assets/4f632403-3007-473d-9454-2149769f1ad3)


**Analysis:**
- Root filesystem: 22GB total, 2.7GB used (14%)
- Available space: 18GB free
- Boot partition: Minimal usage (EFI)
- Swap: Not configured (unnecessary for 4GB RAM system)


#### Operating System Version

**Tool:** `lsb_release -a`

![lsb-release](https://github.com/user-attachments/assets/cc9a6e5e-5c58-41d3-9a08-dc7d220c83fb)

**Kernel Info via `uname -a`:**

![uname](https://github.com/user-attachments/assets/5f7c4672-ab9a-476b-8f12-b6442a166cb8)

**Analysis:**
- Ubuntu: 24.04.4 LTS (noble codename)
- Kernel: 6.8.0-101-generic
- Architecture: ARM64 (aarch64)
- Build: PREEMPT_DYNAMIC (real-time optimized)


#### Virtualization Detection

**Tool:** `sudo dmidecode -s system-manufacturer`

![uname](https://github.com/user-attachments/assets/5f7c4672-ab9a-476b-8f12-b6442a166cb8)

**Analysis:**
- System running in virtualized environment
- VirtualBox detected (ARM64 guest without full SMBIOS support)
- Hypervisor layer active and functional

#### Network Configuration

**Tool:** `ip addr`

![ip addr](https://github.com/user-attachments/assets/5f7c4672-ab9a-476b-8f12-b6442a166cb8)

**Analysis:**
- Loopback (lo): 127.0.0.1 — local communications active
- Ethernet (emp0s8): 10.0.2.15/24 — DHCP assigned (VirtualBox NAT)
- IPv6 enabled: fd17:625c:f037:2:a00:27ff:fe09:4b26/64
- MAC: 08:00:27:09:4b:26 (VirtualBox virtual NIC)
- MTU 1500 — standard frame size

### 2.3 Tool Discovery & Reflection

**Tools Used & Their Purpose:**

| Tool | Purpose | Usefulness |
|------|---------|-----------|
| `lscpu` | CPU architecture, cores, flags | Essential for DevOps |
| `free -h` | RAM allocation and usage | Critical for monitoring |
| `df -h` | Disk space by filesystem | Essential for alerts |
| `lsb_release -a` | OS version identification |  Required for compatibility |
| `uname -a` | Kernel version & build | Needed for debugging |
| `ip addr` | Network interfaces & IPs | Critical for networking |
| `dmidecode` | Hardware manufacturer | Useful for VM detection |

**Key insights:**

The most useful tools are the ones that directly support infrastructure decisions:
- **lscpu** tells you exactly what compute you have (ARM vs x86, core count)
- **df -h** and **free -h** are your early warning systems for resource exhaustion
- **ip addr** is fundamental for any network troubleshooting
- **lsb_release** + **uname** are the first diagnostic trio when anything breaks