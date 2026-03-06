# TASK 1

Host system: Windows 11 Home Single Language 23H2
VirtualBox 7.2.6

Installation was ok

# TASK 2

```bash
lscpu

Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          48 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   1
  On-line CPU(s) list:    0
Vendor ID:                AuthenticAMD
  Model name:             AMD Ryzen 5 5600H with Radeon Graphics
    CPU family:           25
    Model:                80
    Thread(s) per core:   1
    Core(s) per socket:   1
    Socket(s):            1
    Stepping:             0
    BogoMIPS:             6587.37
    Flags:                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxs
                          r sse sse2 ht syscall nx mmxext fxsr_opt rdtscp lm constant_tsc rep_good nopl nonstop_t
                          sc cpuid extd_apicid tsc_known_freq pni pclmulqdq ssse3 cx16 sse4_1 sse4_2 movbe popcnt
                           aes rdrand hypervisor lahf_lm cr8_legacy abm sse4a misalignsse 3dnowprefetch vmmcall f
                          sgsbase bmi1 bmi2 rdseed clflushopt arat
Virtualization features:  
  Hypervisor vendor:      KVM
  Virtualization type:    full
Caches (sum of all):      
  L1d:                    32 KiB (1 instance)
  L1i:                    32 KiB (1 instance)
  L2:                     512 KiB (1 instance)
  L3:                     16 MiB (1 instance)
NUMA:                     
  NUMA node(s):           1
  NUMA node0 CPU(s):      0
Vulnerabilities:          
  Gather data sampling:   Not affected
  Ghostwrite:             Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Not affected
  Retbleed:               Not affected
  Spec rstack overflow:   Vulnerable: Safe RET, no microcode
  Spec store bypass:      Not affected
  Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:             Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI Not 
                          affected
  Srbds:                  Not affected
  Tsx async abort:        Not affected
```

```bash
free -h

total        used        free      shared  buff/cache   available

Mem:           1.9Gi       743Mi       203Mi        13Mi       1.2Gi       1.2G

Swap:             0B          0B          0B
```


```bash
ip addr

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:d3:da:08 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 85659sec preferred_lft 85659sec
    inet6 fe80::d664:4a34:b1d4:31ea/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

```bash
df -hT

Filesystem     Type   Size  Used Avail Use% Mounted on
tmpfs          tmpfs  197M  1.3M  196M   1% /run
/dev/sda1      ext4    30G   22G  6.5G  77% /
tmpfs          tmpfs  985M     0  985M   0% /dev/shm
tmpfs          tmpfs  5.0M  8.0K  5.0M   1% /run/lock
tmpfs          tmpfs  197M  120K  197M   1% /run/user/1000
```

```bash
hostnamectl

\ Static hostname: user-pc
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: e763a6f41f68453a8dd23636c66c012d
         Boot ID: 8c7943ce8f9144fea1118cfe3bc926ed
  Virtualization: oracle
Operating System: Ubuntu 24.04.3 LTS              
          Kernel: Linux 6.14.0-27-generic
    Architecture: x86-64
 Hardware Vendor: innotek GmbH
  Hardware Model: VirtualBox
Firmware Version: VirtualBox
   Firmware Date: Fri 2006-12-01
    Firmware Age: 19y 3month 3d   
```

```bash
systemd-detect-virt

oracle
```

I have used the cli commands that specifically do what I wante to get/acheive. They are mostly standard and pre-installed on any Linux distribution (and macOS) that guarantees users' familiarity with them. Most useful and cool was `systemd-detect-virt`. It allowed to detect that oracle was the virtualization provider.