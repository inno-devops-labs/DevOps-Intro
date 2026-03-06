# Task 1

## Host operating system and version
Windows 10 pro 22H2

## VirtualBox version number
7.0.24 r167081

## Any installation issues encountered
There were no issues

# Task 2

## VM configuration specifications
8 GB RAM, 4 CPU cores, 25 GB storage

## CPU Details
Tool name: lscpu

Command: lscpu

Output:

```
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             39 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      4
  On-line CPU(s) list:       0-3
Vendor ID:                   GenuineIntel
  Model name:                13th Gen Intel(R) Core(TM) i9-13900HX
    CPU family:              6
    Model:                   183
    Thread(s) per core:      1
    Core(s) per socket:      4
    Socket(s):               1
    Stepping:                1
    BogoMIPS:                4838.39
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pg
                             e mca cmov pat pse36 clflush mmx fxsr sse sse2 ht s
                             yscall nx rdtscp lm constant_tsc rep_good nopl xtop
                             ology nonstop_tsc cpuid tsc_known_freq pni pclmulqd
                             q ssse3 cx16 pcid sse4_1 sse4_2 movbe popcnt aes rd
                             rand hypervisor lahf_lm abm 3dnowprefetch ibrs_enha
                             nced fsgsbase bmi1 bmi2 invpcid rdseed clflushopt a
                             rat md_clear flush_l1d arch_capabilities
Virtualization features:     
  Hypervisor vendor:         KVM
  Virtualization type:       full
Caches (sum of all):         
  L1d:                       192 KiB (4 instances)
  L1i:                       128 KiB (4 instances)
  L2:                        8 MiB (4 instances)
  L3:                        144 MiB (4 instances)
NUMA:                        
  NUMA node(s):              1
  NUMA node0 CPU(s):         0-3
Vulnerabilities:             
  Gather data sampling:      Not affected
  Ghostwrite:                Not affected
  Indirect target selection: Mitigation; Aligned branch/return thunks
  Itlb multihit:             Not affected
  L1tf:                      Not affected
  Mds:                       Not affected
  Meltdown:                  Not affected
  Mmio stale data:           Not affected
  Old microcode:             Not affected
  Reg file data sampling:    Not affected
  Retbleed:                  Mitigation; Enhanced IBRS
  Spec rstack overflow:      Not affected
  Spec store bypass:         Vulnerable
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user poi
                             nter sanitization
  Spectre v2:                Mitigation; Enhanced / Automatic IBRS; PBRSB-eIBRS 
                             SW sequence; BHI SW loop, KVM SW loop
  Srbds:                     Not affected
  Tsa:                       Not affected
  Tsx async abort:           Not affected
  Vmscape:                   Not affected
```

## Memory Information
Tool name: free

Command: free -h

Output:

```
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       1.1Gi       5.6Gi        31Mi       1.3Gi       6.7Gi
Swap:          4.0Gi          0B       4.0Gi
```

## Network Configuration
Tool name: ip

Command: ip -brief address

Output:

```
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp0s3           UP             10.0.2.15/24 fe80::a00:27ff:feea:589d/64 
```

## Storage Information
Tool name: df and lsblk
Command: df -h
Command: lsblk
Output:

```
df
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           795M  1.5M  793M   1% /run
/dev/sda2        25G  9.5G   14G  41% /
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           795M  120K  794M   1% /run/user/1000
/dev/sr0         53M   53M     0 100% /media/devops/VBox_GAs_7.0.24

lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0     4K  1 loop /snap/bare/5
loop1    7:1    0    74M  1 loop /snap/core22/2292
loop2    7:2    0 251.7M  1 loop /snap/firefox/7766
loop3    7:3    0 531.4M  1 loop /snap/gnome-42-2204/247
loop4    7:4    0  18.5M  1 loop /snap/firmware-updater/210
loop5    7:5    0  91.7M  1 loop /snap/gtk-common-themes/1535
loop6    7:6    0  10.8M  1 loop /snap/snap-store/1270
loop7    7:7    0  48.1M  1 loop /snap/snapd/25935
loop8    7:8    0   576K  1 loop /snap/snapd-desktop-integration/343
sda      8:0    0    25G  0 disk 
├─sda1   8:1    0     1M  0 part 
└─sda2   8:2    0    25G  0 part /
sr0     11:0    1  52.3M  0 rom  /media/devops/VBox_GAs_7.0.24
```

## Operating System
Tool name: /etc/os-release and uname
Command: cat /etc/os-release
Command: uname -a
Output:

```
cat /etc/os-release

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

uname -a

Linux devops-VirtualBox 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```

## Virtualization Detection
Tool name: systemd-detect-virt (and procfs check)
Command: systemd-detect-virt
Output:

```
oracle
```

## Brief reflection on which tools were most useful and why
I think hardware commands are useful in this case 
beacause it allows to estimate services requirements for development

CPU & RAM: lscpu and /proc/meminfo — reliable, detailed hardware and memory metrics.
Storage: df -h and lsblk -f — quick view of disk usage and filesystem layout.
Network: ip -brief address — concise interface status and IPs.
OS & kernel: cat /etc/os-release and uname -r — definitive distro and kernel info.
Virtualization: systemd-detect-virt + /proc/cpuinfo checks — clear VM detection evidence.

