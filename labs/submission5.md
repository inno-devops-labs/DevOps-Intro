# Lab 5 — Virtualization & System Analysis

## Task 1 — VirtualBox Installation
- **Host OS:** Windows 11 Home Single Language 24H2
- **VirtualBox version:** 7.2.2 r170484
- **Issues:** Installation completed successfully, no errors encountered

## Task 2 — Ubuntu VM and System Analysis

### VM Specs
- RAM: 4 GB (4096 MB)  
- CPU: 2 cores  
- Storage: 25 GB

![VM OS](https://github.com/user-attachments/assets/97d95567-f9e5-47f7-9af1-b72e89d7a169)

---

### CPU Information
**Tools used:** `lscpu`, `cat /proc/cpuinfo`  

**Command:** `lscpu`

**Output:**
```
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             48 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      2
  On-line CPU(s) list:       0,1
Vendor ID:                   AuthenticAMD
  Model name:                AMD Ryzen 5 3500U with Radeon Vega Mobile Gfx
    CPU family:              23
    Model:                   24
    Thread(s) per core:      1
    Core(s) per socket:      2
    Socket(s):               1
    Stepping:                1
    BogoMIPS:                4192.00
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr ss
                             e sse2 ht syscall nx mmxext fxsr_opt rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid
                              extd_apicid tsc_known_freq pni pclmulqdq ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsa
                             ve avx f16c rdrand hypervisor lahf_lm cmp_legacy cr8_legacy abm sse4a misalignsse 3dnowpref
                             etch ssbd vmmcall fsgsbase bmi1 avx2 bmi2 rdseed adx clflushopt sha_ni arat
Virtualization features:     
  Hypervisor vendor:         KVM
  Virtualization type:       full
Caches (sum of all):         
  L1d:                       64 KiB (2 instances)
  L1i:                       128 KiB (2 instances)
  L2:                        1 MiB (2 instances)
  L3:                        8 MiB (2 instances)
NUMA:                        
  NUMA node(s):              1
  NUMA node0 CPU(s):         0,1
Vulnerabilities:             
  Gather data sampling:      Not affected
  Ghostwrite:                Not affected
  Indirect target selection: Not affected
  Itlb multihit:             Not affected
  L1tf:                      Not affected
  Mds:                       Not affected
  Meltdown:                  Not affected
  Mmio stale data:           Not affected
  Reg file data sampling:    Not affected
  Retbleed:                  Mitigation; untrained return thunk; SMT disabled
  Spec rstack overflow:      Vulnerable: Safe RET, no microcode
  Spec store bypass:         Not affected
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:                Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI Not affe
                             cted
  Srbds:                     Not affected
  Tsx async abort:           Not affected
```

**Command:** `cat /proc/cpuinfo | head -20`

**Output:**
```
processor	: 0
vendor_id	: AuthenticAMD
cpu family	: 23
model		: 24
model name	: AMD Ryzen 5 3500U with Radeon Vega Mobile Gfx
stepping	: 1
microcode	: 0xffffffff
cpu MHz		: 2096.000
cache size	: 512 KB
physical id	: 0
siblings	: 2
core id		: 0
cpu cores	: 2
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 13
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid tsc_known_freq pni pclmulqdq ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm cmp_legacy cr8_legacy abm sse4a misalignsse 3dnowprefetch ssbd vmmcall fsgsbase bmi1 avx2 bmi2 rdseed adx clflushopt sha_ni arat
```

---

### Memory Information
**Tools used:** `free`, `cat /proc/meminfo`  

**Command:** `free -h`  

**Output:**
```
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.0Gi       2.2Gi        33Mi       891Mi       2.8Gi
Swap:             0B          0B          0B
```

**Command:** `cat /proc/meminfo | head -10`

**Output:**
```
MemTotal:        4010568 kB
MemFree:         2268352 kB
MemAvailable:    2925380 kB
Buffers:           34320 kB
Cached:           841824 kB
SwapCached:            0 kB
Active:          1251196 kB
Inactive:         212280 kB
Active(anon):     622080 kB
Inactive(anon):        0 kB
```

---

### Network Configuration

**Tools used:** `ip`, `ifconfig`  

**Command:** `ip addr`

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:9a:98:28 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86229sec preferred_lft 86229sec
    inet6 fd17:625c:f037:2:7bad:163b:2e66:6662/64 scope global temporary dynamic 
       valid_lft 86231sec preferred_lft 14231sec
    inet6 fd17:625c:f037:2:a00:27ff:fe9a:9828/64 scope global dynamic mngtmpaddr 
       valid_lft 86231sec preferred_lft 14231sec
    inet6 fe80::a00:27ff:fe9a:9828/64 scope link 
       valid_lft forever preferred_lft forever
```


**Command:** `ifconfig`  

**Output:**

```
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fd17:625c:f037:2:7bad:163b:2e66:6662  prefixlen 64  scopeid 0x0<global>
        inet6 fd17:625c:f037:2:a00:27ff:fe9a:9828  prefixlen 64  scopeid 0x0<global>
        inet6 fe80::a00:27ff:fe9a:9828  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:9a:98:28  txqueuelen 1000  (Ethernet)
        RX packets 252  bytes 226398 (226.3 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 234  bytes 28071 (28.0 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 55  bytes 5962 (5.9 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 55  bytes 5962 (5.9 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

---

### Storage Information

**Tools used:** `lsblk`, `df`  

**Command:** `lsblk`  

**Output:**
```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0  73.9M  1 loop /snap/core22/2045
loop1    7:1    0     4K  1 loop /snap/bare/5
loop2    7:2    0 245.1M  1 loop /snap/firefox/6565
loop3    7:3    0  11.1M  1 loop /snap/firmware-updater/167
loop4    7:4    0  91.7M  1 loop /snap/gtk-common-themes/1535
loop5    7:5    0   516M  1 loop /snap/gnome-42-2204/202
loop6    7:6    0  10.8M  1 loop /snap/snap-store/1270
loop7    7:7    0  49.3M  1 loop /snap/snapd/24792
loop8    7:8    0   576K  1 loop /snap/snapd-desktop-integration/315
sda      8:0    0    25G  0 disk 
├─sda1   8:1    0     1M  0 part 
└─sda2   8:2    0    25G  0 part /
sr0     11:0    1  50.7M  0 rom  /media/vboxuser/VBox_GAs_7.2.2
```


**Command:** `df -h`  

**Output:**
```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.5M  391M   1% /run
/dev/sda2        25G  5.6G   18G  24% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           392M  120K  392M   1% /run/user/1000
/dev/sr0         51M   51M     0 100% /media/vboxuser/VBox_GAs_7.2.2
```

---

### Operating System

**Tools used:** `lsb_release`, `uname`  

**Command:** `lsb_release -a`  

**Output:**
```
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 24.04.3 LTS
Release:	24.04
Codename:	noble
```
**Command:** `uname -a`

**Output:**
```
Linux Ubuntu-VM 6.14.0-33-generic #33~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Fri Sep 19 17:02:30 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```


---

### Virtualization Detection

**Tool used:** `systemd-detect-virt` 

**Command:** `systemd-detect-virt`

**Output:**
``` 
oracle
```

---

### Reflection
- The most useful commands:  
  - `lscpu` — clear summary of CPU info.  
  - `free -h` — easy way to check RAM usage.  
  - `ip addr` — modern tool for checking network interfaces and IPs.  
- `lsblk` and `df -h` complement each other well for analyzing disk devices and usage.  
- `systemd-detect-virt` confirms that the system is running inside a VM, which is essential for validation.  

---

## Conclusion
- VirtualBox installed and verified.  
- Ubuntu 24.04.3 LTS successfully deployed in VM.  
- Comprehensive system information collected and documented.  
