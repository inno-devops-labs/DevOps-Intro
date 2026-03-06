# Lab 5 Submission — Virtualization & System Analysis

## Task 1 — VirtualBox Installation

- **Host OS:** macOS (Apple M3, ARM64 architecture)
- **VirtualBox Version:** 7.1.x (attempted)
- **Installation Issue:** The standard VirtualBox installer (.dmg) returned the following error:
  > "Unsupported hardware architecture detected. The installer has detected an unsupported architecture. VirtualBox only runs on the amd64 architecture."
- **Resolution:** VirtualBox does not officially support Apple Silicon (ARM64) on its standard release channel. As a result, I switched to **Multipass** — Canonical's official lightweight VM manager that leverages the native macOS Hypervisor framework (Apple Hypervisor.framework). This is the recommended virtualization approach for M-series Macs, as it provides full hardware-accelerated virtualization without requiring x86 emulation.

---

## Task 2 — Ubuntu VM and System Analysis

### 2.1 VM Configuration

| Parameter | Value |
|-----------|-------|
| Platform | Multipass (Apple Hypervisor framework) |
| Guest OS | Ubuntu 24.04.4 LTS (Noble Numbat) |
| RAM | 4 GB |
| Storage | 25 GB |
| CPU Cores | 2 |

> Multipass was launched with the following command:
> ```bash
> multipass launch 24.04 --name lab5 --cpus 2 --memory 4G --disk 25G
> ```

---

### 2.2 System Information Discovery

#### CPU Details

**Tools used:** `lscpu`, `/proc/cpuinfo`

**Command:**
```bash
lscpu
```

**Output:**
```
Architecture:                aarch64
  CPU op-mode(s):            64-bit
  Byte Order:                Little Endian
CPU(s):                      1
  On-line CPU(s) list:       0
Vendor ID:                   Apple
  Model name:                -
    Model:                   0
    Thread(s) per core:      1
    Core(s) per socket:      1
    Socket(s):               1
    Stepping:                0x0
    BogoMIPS:                48.00
    Flags:                   fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics
                             fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop
                             sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm
                              sb paca pacg dcpodp flagm2 frint bf16 afp
NUMA:
  NUMA node(s):              1
  NUMA node0 CPU(s):         0
Vulnerabilities:
  Gather data sampling:      Not affected
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
  Tsa:                       Not affected
  Tsx async abort:           Not affected
  Vmscape:                   Not affected
```

**Command:**
```bash
cat /proc/cpuinfo | grep "model name" | head -1
```

**Output:**
```
(no output — model name field is not populated for Apple Silicon ARM virtualized CPUs)
```

---

#### Memory Information

**Tools used:** `free`, `/proc/meminfo`

**Command:**
```bash
free -h
```

**Output:**
```
               total        used        free      shared  buff/cache   available
Mem:           1.9Gi       225Mi       1.1Gi       1.1Mi       652Mi       1.7Gi
Swap:             0B          0B          0B
```

**Command:**
```bash
cat /proc/meminfo | head -5
```

**Output:**
```
MemTotal:        2003060 kB
MemFree:         1191008 kB
MemAvailable:    1772908 kB
Buffers:           20176 kB
Cached:           616480 kB
```

---

#### Network Configuration

**Tools used:** `ip addr`, `ip route`

**Command:**
```bash
ip addr
```

**Output:**
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enp0s1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:e9:5a:96 brd ff:ff:ff:ff:ff:ff
    inet 192.168.64.2/24 metric 100 brd 192.168.64.255 scope global dynamic enp0s1
       valid_lft 3218sec preferred_lft 3218sec
    inet6 fd3a:f6ac:ad62:1f66:5054:ff:fee9:5a96/64 scope global dynamic mngtmpaddr noprefixroute
       valid_lft 2591951sec preferred_lft 604751sec
    inet6 fe80::5054:ff:fee9:5a96/64 scope link
       valid_lft forever preferred_lft forever
```

**Command:**
```bash
ip route
```

**Output:**
```
default via 192.168.64.1 dev enp0s1 proto dhcp src 192.168.64.2 metric 100
192.168.64.0/24 dev enp0s1 proto kernel scope link src 192.168.64.2 metric 100
192.168.64.1 dev enp0s1 proto dhcp scope link src 192.168.64.2 metric 100
```

---

#### Storage Information

**Tools used:** `df`, `lsblk`

**Command:**
```bash
df -h
```

**Output:**
```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           196M  1.2M  195M   1% /run
efivarfs        256K   15K  242K   6% /sys/firmware/efi/efivars
/dev/sda1        24G  2.0G   22G   9% /
tmpfs           979M     0  979M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda16      891M   60M  769M   8% /boot
/dev/sda15       98M  6.4M   92M   7% /boot/efi
tmpfs           196M   12K  196M   1% /run/user/1000
```

**Command:**
```bash
lsblk
```

**Output:**
```
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda       8:0    0   25G  0 disk
├─sda1    8:1    0   24G  0 part /
├─sda15   8:15   0   99M  0 part /boot/efi
└─sda16 259:0    0  923M  0 part /boot
vda     253:0    0   54K  1 disk
```

---

#### Operating System

**Tools used:** `uname`, `/etc/os-release`, `lsb_release`

**Command:**
```bash
uname -a
```

**Output:**
```
Linux lab5 6.8.0-101-generic #101-Ubuntu SMP PREEMPT_DYNAMIC Fri Feb  6 20:07:40 UTC 2026 aarch64 aarch64 aarch64 GNU/Linux
```

**Command:**
```bash
cat /etc/os-release
```

**Output:**
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

**Command:**
```bash
lsb_release -a
```

**Output:**
```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.4 LTS
Release:        24.04
Codename:       noble
```

---

#### Virtualization Detection

**Tools used:** `systemd-detect-virt`, `dmidecode`

**Command:**
```bash
systemd-detect-virt
```

**Output:**
```
qemu
```

**Command:**
```bash
sudo dmidecode -s system-product-name
```

**Output:**
```
QEMU Virtual Machine
```

The system is confirmed to be running inside a virtual machine. `systemd-detect-virt` identifies the hypervisor as **QEMU**, and `dmidecode` reports the system product name as **QEMU Virtual Machine** — both are consistent with Multipass, which uses QEMU under the hood on macOS ARM via Apple's Hypervisor framework.

---

### 2.3 Reflection — Most Useful Tools

| Tool | Category | Why Useful |
|------|----------|------------|
| `lscpu` | CPU | Single command, structured output, shows architecture, cores, vendor, and security vulnerability status |
| `free -h` | Memory | Human-readable, instant overview of total/used/available RAM and swap |
| `ip addr` | Network | Shows all interfaces with IP addresses (both IPv4 and IPv6), link state, and MAC address |
| `df -h` | Storage | Clear filesystem usage per mount point in human-readable sizes |
| `uname -a` | OS | One-liner that gives kernel version, hostname, and architecture simultaneously |
| `systemd-detect-virt` | Virtualization | Definitively confirms virtualization and names the hypervisor in one word |

**Overall:** `lscpu` and `systemd-detect-virt` were the most immediately useful — the former because it consolidates all CPU-related information in one structured view, and the latter because it provides unambiguous confirmation that the system is virtualized without requiring any additional parsing. The `/proc` filesystem (`/proc/cpuinfo`, `/proc/meminfo`) proved valuable as a low-level source of truth that the higher-level tools read from internally.
