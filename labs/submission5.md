# **Lab 5 — Virtualization & System Analysis**

## **Task 1 — VirtualBox Installation**

* Host Operating System — `Windows 11 Pro 23H2`
* VirtualBox version number — `7.2.6 r172322 (Qt6.8.0 on windows)`
* During the installation there were not any issues arise

## **Task 2 — Ubuntu VM and System Analysis**

1. VM configuration specifications

* RAM: `4096 MB`
* Storage: `15 GB`
* CPU: `6 cores`

2. System Information

* Command `lscpu`
```bash
maks@maks-VirtualBox:~$ lscpu
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             48 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      6
  On-line CPU(s) list:       0-5
Vendor ID:                   AuthenticAMD
  Model name:                AMD Ryzen 5 5500U with Radeon Graphics
    CPU family:              23
    Model:                   104
    Thread(s) per core:      1
    Core(s) per socket:      6
    Socket(s):               1
    Stepping:                1
    BogoMIPS:                4191.98
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pg
                             e mca cmov pat pse36 clflush mmx fxsr sse sse2 ht s
                             yscall nx mmxext fxsr_opt rdtscp lm constant_tsc re
                             p_good nopl xtopology nonstop_tsc cpuid extd_apicid
                              tsc_known_freq pni pclmulqdq ssse3 fma cx16 sse4_1
                              sse4_2 movbe popcnt aes xsave avx f16c rdrand hype
                             rvisor lahf_lm cmp_legacy cr8_legacy abm sse4a misa
                             lignsse 3dnowprefetch ssbd vmmcall fsgsbase bmi1 av
                             x2 bmi2 rdseed adx clflushopt sha_ni arat
Virtualization features:     
  Hypervisor vendor:         KVM
  Virtualization type:       full
NUMA:                        
  NUMA node(s):              1
  NUMA node0 CPU(s):         0-5
Vulnerabilities:             
  Gather data sampling:      Not affected
  Ghostwrite:                Not affected
  Indirect target selection: Not affected
  Itlb multihit:             Not affected
  L1tf:                      Not affected
  Mds:                       Not affected
  Meltdown:                  Not affected
  Mmio stale data:           Not affected
  Old microcode:             Not affected
  Reg file data sampling:    Not affected
  Retbleed:                  Mitigation; untrained return thunk; SMT disabled
  Spec rstack overflow:      Mitigation; SMT disabled
  Spec store bypass:         Not affected
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user poi
                             nter sanitization
  Spectre v2:                Mitigation; Retpolines; STIBP disabled; RSB filling
                             ; PBRSB-eIBRS Not affected; BHI Not affected
  Srbds:                     Not affected
  Tsa:                       Not affected
  Tsx async abort:           Not affected
  Vmscape:                   Not affected
```

* Command `free -h`

```bash
maks@maks-VirtualBox:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.4Gi       496Mi        36Mi       2.2Gi       2.4Gi
Swap:          2.4Gi          0B       2.4Gi
```

* Command `ip addr`

```bash
maks@maks-VirtualBox:~$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 85965sec preferred_lft 85965sec
    inet6 fd17:.../64 scope global temporary dynamic 
       valid_lft 86193sec preferred_lft 14193sec
    inet6 fd17:.../64 scope global dynamic mngtmpaddr 
       valid_lft 86193sec preferred_lft 14193sec
    inet6 fe80::.../64 scope link 
       valid_lft forever preferred_lft forever
```

* Command `df -h`

```bash
maks@maks-VirtualBox:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.9M  390M   1% /run
/dev/sda2        15G   11G  3.9G  73% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           392M  120K  392M   1% /run/user/1000
/dev/sr0         51M   51M     0 100% /media/maks/VBox_GAs_7.2.6
```

* Command `lsb_release -a`

```bash
maks@maks-VirtualBox:~$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 24.04.4 LTS
Release:	24.04
Codename:	noble
```

* Command `hostnamectl`

```bash
maks@maks-VirtualBox:~$ hostnamectl
 Static hostname: maks-VirtualBox
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: 7cd69a4861404b6697ace20e26ac3766
         Boot ID: d6b3271faf694453983de6a5f68b7e42
  Virtualization: oracle
Operating System: Ubuntu 24.04.4 LTS              
          Kernel: Linux 6.17.0-14-generic
    Architecture: x86-64
 Hardware Vendor: innotek GmbH
  Hardware Model: VirtualBox
Firmware Version: VirtualBox
   Firmware Date: Fri 2006-12-01
    Firmware Age: 19y 3month 4d  
```

* Command `systemd-detect-virt`

```bash    
maks@maks-VirtualBox:~$ systemd-detect-virt
oracle
```

All of the tools used were useful, since the required information was obtained directly from terminal
