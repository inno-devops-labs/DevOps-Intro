## Task 1 — VirtualBox Installation

**Host OS:** Windows 11   
**VirtualBox version:** 7.2.4 r170995 (Qt6.8.0 on windows) 
**Installation issues:** None



## Task 2

```
ubuntu@ubuntu:~$ lscpu
Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          39 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   2
  On-line CPU(s) list:    0,1
Vendor ID:                GenuineIntel
  Model name:             11th Gen Intel(R) Core(TM) i5-1155G7 @ 2.50GHz
    CPU family:           6
    Model:                140
    Thread(s) per core:   1
    Core(s) per socket:   2
    Socket(s):            1
    Stepping:             2
    BogoMIPS:             4992.02
    Flags:                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge m
                          ca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall
                           nx rdtscp lm constant_tsc rep_good nopl xtopology non
                          stop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 fma 
                          cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16
                          c rdrand hypervisor lahf_lm abm 3dnowprefetch ibrs_enh
                          anced fsgsbase bmi1 avx2 bmi2 invpcid rdseed adx clflu
                          shopt sha_ni arat md_clear flush_l1d arch_capabilities
Virtualization features:  
  Hypervisor vendor:      KVM
  Virtualization type:    full
Caches (sum of all):      
  L1d:                    96 KiB (2 instances)
  L1i:                    64 KiB (2 instances)
  L2:                     2.5 MiB (2 instances)
  L3:                     16 MiB (2 instances)
NUMA:                     
  NUMA node(s):           1
  NUMA node0 CPU(s):      0,1
Vulnerabilities:          
  Gather data sampling:   Unknown: Dependent on hypervisor status
  Ghostwrite:             Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Not affected
  Retbleed:               Mitigation; Enhanced IBRS
  Spec rstack overflow:   Not affected
  Spec store bypass:      Vulnerable
  Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointe
                          r sanitization
  Spectre v2:             Mitigation; Enhanced / Automatic IBRS; PBRSB-eIBRS SW 
                          sequence; BHI SW loop, KVM SW loop
  Srbds:                  Not affected
  Tsx async abort:        Not affected
ubuntu@ubuntu:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.2Gi       287Mi        68Mi       2.6Gi       2.6Gi
Swap:             0B          0B          0B
ubuntu@ubuntu:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:73:ac:ec brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86004sec preferred_lft 86004sec
    inet6 fd17:625c:f037:2:6186:258f:e477:914d/64 scope global temporary dynamic 
       valid_lft 86005sec preferred_lft 14005sec
    inet6 fd17:625c:f037:2:a00:27ff:fe73:acec/64 scope global dynamic mngtmpaddr 
       valid_lft 86005sec preferred_lft 14005sec
    inet6 fe80::a00:27ff:fe73:acec/64 scope link 
       valid_lft forever preferred_lft forever
ubuntu@ubuntu:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.8M  390M   1% /run
/dev/sr0        6.0G  6.0G     0 100% /cdrom
/cow            2.0G   57M  1.9G   3% /
tmpfs           2.0G  8.0K  2.0G   1% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           2.0G     0  2.0G   0% /tmp
tmpfs           392M  164K  392M   1% /run/user/1000
ubuntu@ubuntu:~$ lsblk
NAME   MAJ:MIN

RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0   1.7G  1 loop /rofs
loop1    7:1    0 523.3M  1 loop 
loop2    7:2    0 925.9M  1 loop 
loop3    7:3    0     4K  1 loop /snap/bare/5
loop4    7:4    0 245.1M  1 loop /snap/firefox/6565
loop5    7:5    0  11.1M  1 loop /snap/firmware-updater/167
loop6    7:6    0  73.9M  1 loop /snap/core22/2045
loop7    7:7    0   516M  1 loop /snap/gnome-42-2204/202
loop8    7:8    0  91.7M  1 loop /snap/gtk-common-themes/1535
loop9    7:9    0  10.8M  1 loop /snap/snap-store/1270
loop10   7:10   0  49.3M  1 loop /snap/snapd/24792
loop11   7:11   0   210M  1 loop /snap/thunderbird/769
loop12   7:12   0   576K  1 loop /snap/snapd-desktop-integration/315
loop13   7:13   0 112.6M  1 loop /snap/ubuntu-desktop-bootstrap/413
sda      8:0    0  27.4G  0 disk 
sr0     11:0    1   5.9G  0 rom  /cdrom
ubuntu@ubuntu:~$ uname -a
Linux ubuntu 6.14.0-27-generic #27~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Tue Jul 22 17:38:49 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
ubuntu@ubuntu:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.3 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
ubuntu@ubuntu:~$ systemd-detect-virt
oracle
ubuntu@ubuntu:~$ cat /proc/cpuinfo | grep hypervision
ubuntu@ubuntu:~$ cat /proc/cpuinfo | grep hypervisior
ubuntu@ubuntu:~$ cat /proc/cpuinfo | grep hypervisor
flags  : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch ibrs_enhanced fsgsbase bmi1 avx2 bmi2 invpcid rdseed adx clflushopt sha_ni arat md_clear flush_l1d arch_capabilities
flags  : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch ibrs_enhanced fsgsbase bmi1 avx2 bmi2 invpcid rdseed adx clflushopt sha_ni arat md_clear flush_l1d arch_capabilities

```
