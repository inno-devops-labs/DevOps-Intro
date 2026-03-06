# Lab 5 Submission — Virtualization & System Analysis

## Task 1 — VirtualBox Installation

- **Host Operating System:** Pop!_OS 24.04 LTS
- **VirtualBox Version:** 7.2.4r170995
- **Installation Notes:** VirtualBox was previously installed and verified via the `vboxmanage --version` CLI tool. 

---

## Task 2 — Ubuntu VM and System Analysis

### VM Configuration
- **OS:** Ubuntu 24.04 LTS (Booted into Live/Try Mode via TTY)
- **RAM:** 4096MB
- **CPU Cores:** 2
- **Storage:** 25GB

### System Information Discovery

#### 1. CPU Details
- **Tool:** `lscpu`
- **Output Snippet:**
```text
Architecture:            x86_64
CPU(s):                  2
Vendor ID:               AuthenticAMD
Model name:              AMD Ryzen 7 6800H with Radeon Graphics
Hypervisor vendor:       KVM
Virtualization type:     full
```

#### 2. Memory Information
- **Tool:** `free -h`
- **Output:**
```text
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.3Gi       148Mi        67Mi       2.7Gi       2.5Gi
Swap:             0B          0B          0B
```
*(Note: Swap is 0B because the system is running in a Live ISO environment).*

#### 3. Network Configuration
- **Tool:** `ip addr`
- **Output Snippet:**
```text
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
```

#### 4. Storage Information
- **Tool:** `df -h`
- **Output Snippet:**
```text
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.9M  390M   1% /run
/dev/sr0        6.2G  6.2G     0 100% /cdrom
/cow            2.0G   56M  1.9G   3% /
```
*(Note: Because the system was booted in Live mode to bypass a GUI hang that I encountered, the root filesystem `/` is mounted as an in-memory copy-on-write `/cow` overlay, and the installation media is mounted at `/cdrom`).*

#### 5. Operating System & Virtualization Detection
- **Tools:** `uname -a` and `systemd-detect-virt`
- **OS Output:** 
```text
Linux ubuntu 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```
- **Virtualization Output:** 
```text
oracle
```

### Reflection & Troubleshooting
During the boot sequence, I encountered a graphics driver hang (black screen) preventing the desktop from loading. To troubleshoot and complete the lab, I used a host-key shortcut to switch to a raw TTY console (`Host+F3`). From there, I logged into the Live environment and executed the required analysis commands. 

The most useful tool was `lscpu` because it provided a clear summary of the virtual hardware in a single command. It was helpful to see that the VM correctly recognized my CPU and the 2 cores I assigned to it in the VirtualBox settings. I also found `systemd-detect-virt` interesting because it was the quickest way to confirm the system knew it was running inside a VirtualBox (`oracle`) environment.
