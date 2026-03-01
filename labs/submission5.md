# Lab 5 — Virtualization & System Analysis


## Task 1 — VirtualBox Installation
### Host operating system
Windows 11 Pro 25H2 (26220.7872).

### VirtualBox version number
Version 7.2.4 r170995.

### Any installation issues encountered
No issues at all.


## Task 2 — Ubuntu VM and System Analysis
### VM configuration
- RAM: 7078 MB.
- Storage: 25 GB.
- CPU cores: 6.
- Video Memory: 256 MB.

### Command tools in Linux
- `lscpu` - for CPU details:
```sh
pixel4lex@pixel4lex-VirtualBox:~$ lscpu

Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             48 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      6
  On-line CPU(s) list:       0-5
Vendor ID:                   AuthenticAMD
  Model name:                AMD Ryzen 5 7640HS w/ Radeon 760M Graphics
    CPU family:              25
    Model:                   116
    Thread(s) per core:      1
    Core(s) per socket:      6
    Socket(s):               1
    Stepping:                1
    BogoMIPS:                8583.36
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pg
                             e mca cmov pat pse36 clflush mmx fxsr sse sse2 ht s
                             yscall nx mmxext fxsr_opt rdtscp lm constant_tsc re
                             p_good nopl xtopology nonstop_tsc cpuid extd_apicid
                              tsc_known_freq pni pclmulqdq ssse3 fma cx16 sse4_1
                              sse4_2 movbe popcnt aes xsave avx f16c rdrand hype
                             rvisor lahf_lm cmp_legacy cr8_legacy abm sse4a misa
                             lignsse 3dnowprefetch vmmcall fsgsbase bmi1 avx2 bm
                             i2 invpcid rdseed adx clflushopt sha_ni arat
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
  Retbleed:                  Not affected
  Spec rstack overflow:      Vulnerable: Safe RET, no microcode
  Spec store bypass:         Not affected
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user poi
                             nter sanitization
  Spectre v2:                Mitigation; Retpolines; STIBP disabled; RSB filling
                             ; PBRSB-eIBRS Not affected; BHI Not affected
  Srbds:                     Not affected
  Tsa:                       Vulnerable: No microcode
  Tsx async abort:           Not affected
  Vmscape:                   Not affected
```
- `free -h` - for RAM:
```sh
pixel4lex@pixel4lex-VirtualBox:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:           6.7Gi       1.1Gi       4.3Gi        34Mi       1.4Gi       5.5Gi
Swap:          4.0Gi          0B       4.0Gi
```
- `ip addr`, `ip link`, `ip route`- display network interfaces and protocol stats:
```sh
pixel4lex@pixel4lex-VirtualBox:~$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:82:f7:bf brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86153sec preferred_lft 86153sec
    inet6 fd17:625c:f037:2:6821:f779:dd5a:5e04/64 scope global temporary dynamic 
       valid_lft 86154sec preferred_lft 14154sec
    inet6 fd17:625c:f037:2:a00:27ff:fe82:f7bf/64 scope global dynamic mngtmpaddr 
       valid_lft 86154sec preferred_lft 14154sec
    inet6 fe80::a00:27ff:fe82:f7bf/64 scope link 
       valid_lft forever preferred_lft forever

pixel4lex@pixel4lex-VirtualBox:~$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:82:f7:bf brd ff:ff:ff:ff:ff:ff

pixel4lex@pixel4lex-VirtualBox:~$ ip route
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
```
- `df -h`, `du -sh *` - for filesystem space usage and directory consumption accordingly:
```sh
pixel4lex@pixel4lex-VirtualBox:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           685M  1.5M  683M   1% /run
/dev/sda2        25G  9.5G   14G  41% /
tmpfs           3.4G     0  3.4G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           685M  132K  685M   1% /run/user/1000
/dev/sr0         51M   51M     0 100% /media/pixel4lex/VBox_GAs_7.2.4

pixel4lex@pixel4lex-VirtualBox:~$ du -sh *
4.0K	Desktop
4.0K	Documents
4.0K	Downloads
4.0K	Music
4.0K	Pictures
4.0K	Public
232K	snap
4.0K	Templates
4.0K	Videos
```
- `uname -a` - kernel + system info:
```sh
pixel4lex@pixel4lex-VirtualBox:~$ uname -a
Linux pixel4lex-VirtualBox 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```
- `systemd-detect-virt` - for detecting VM:
```sh
pixel4lex@pixel4lex-VirtualBox:~$ systemd-detect-virt
oracle
```

### Reflection on which tools were most useful and why
| Category        | Most Effective Tool        | Reason                                      |
|-----------------|----------------------------|---------------------------------------------|
| CPU             | `lscpu`                    | Structured hardware summary + virtualization info |
| Memory          | `free -h`                  | Immediate operational insight               |
| Network         | `ip` commands              | Complete modern network stack visibility    |
| Storage         | `df -h` + `du -sh`         | Global vs local disk usage                  |
| OS              | `uname -a`                 | Fast kernel/system fingerprint              |