# Lab 5: Virtualization & System Analysis

## Task 1: VirtualBox Installation

- Основная операционная система: Windows 11 Home
- Версия VirtualBox: 7.2.4
- Проблемы при установке: VirtualBox уже был установлен на моем компьютере для курса по компарчу и ОСям, поэтому новая установка не потребовалась. Никаких проблем не возникло.

## Task 2: Ubuntu VM and System Analysis

### 2.1 VM Setup
- RAM: 4 ГБ
- Storage: 25 ГБ
- CPU: 2 ядра
- ОС: Ubuntu 24.04 LTS

### 2.2 System Information Discovery

#### 1. CPU Details
- Найденный инструмент: `lscpu`
- Использованная команда: `lscpu`
- Output:
```
    Architecture:                x86_64
      CPU op-mode(s):            32-bit, 64-bit
      Address sizes:             39 bits physical, 48 bits virtual
      Byte Order:                Little Endian
    CPU(s):                      2
      On-line CPU(s) list:       0,1
    Vendor ID:                   GenuineIntel
      Model name:                13th Gen Intel(R) Core(TM) i7-13700H
        CPU family:              6
        Model:                   186
        Thread(s) per core:      1
        Core(s) per socket:      2
        Socket(s):               1
        Stepping:                2
        BogoMIPS:                5836.83
        Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pg
                                 e mca cmov pat pse36 clflush mmx fxsr sse sse2 ht s
                                 yscall nx rdtscp lm constant_tsc rep_good nopl xtop
                                 ology nonstop_tsc cpuid tsc_known_freq pni pclmulqd
                                 q ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt ae
                                 s xsave avx f16c rdrand hypervisor lahf_lm abm 3dno
                                 wprefetch ibrs_enhanced fsgsbase bmi1 avx2 bmi2 inv
                                 pcid rdseed adx clflushopt sha_ni arat md_clear flu
                                 sh_l1d arch_capabilities
    Virtualization features:     
      Hypervisor vendor:         KVM
      Virtualization type:       full
    Caches (sum of all):         
      L1d:                       96 KiB (2 instances)
      L1i:                       64 KiB (2 instances)
      L2:                        2.5 MiB (2 instances)
      L3:                        48 MiB (2 instances)
    NUMA:                        
      NUMA node(s):              1
      NUMA node0 CPU(s):         0,1
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
      Reg file data sampling:    Vulnerable: No microcode
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

#### 2. Memory Information
- Найденный инструмент: `free`
- Использованная команда: `free -h`
- Output:
```
    total        used        free      shared  buff/cache   availableMem:           
    3.8Gi       1.9Gi       124Mi        88Mi       1.9Gi       1.9GiSwap:          
       0B          0B          0B
```

#### 3. Network Configuration
- Найденный инструмент: `ip`
- Использованная команда: `ip a`
- Output:
```
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host noprefixroute 
           valid_lft forever preferred_lft forever
    2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
        link/ether 08:00:27:8c:59:20 brd ff:ff:ff:ff:ff:ff
        inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
           valid_lft 84791sec preferred_lft 84791sec
        inet6 fd17:625c:f037:2:a4d9:2551:b662:1a4b/64 scope global temporary dynamic 
           valid_lft 86284sec preferred_lft 14284sec
        inet6 fd17:625c:f037:2:a00:27ff:fe8c:5920/64 scope global dynamic mngtmpaddr 
           valid_lft 86284sec preferred_lft 14284sec
        inet6 fe80::a00:27ff:fe8c:5920/64 scope link 
           valid_lft forever preferred_lft forever
```

#### 4. Storage Information
- Найденный инструмент: `df`
- Использованная команда: `df -h`
- Output:
```
    Filesystem      Size  Used Avail Use% Mounted on
    tmpfs           392M  1.5M  390M   1% /run
    /dev/sda2        25G  5.6G   18G  24% /
    tmpfs           2.0G     0  2.0G   0% /dev/shm
    tmpfs           5.0M  8.0K  5.0M   1% /run/lock
    tmpfs           392M  124K  392M   1% /run/user/1000
```

#### 5. Operating System Details
- Найденный инструмент: `cat`
- Использованная команда: `cat /etc/os-release`
- Output:
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

#### 6. Virtualization Detection
- Найденный инструмент: `systemd-detect-virt`
- Использованная команда: `systemd-detect-virt`
- Output:
```
    oracle
```

#### Рефлексия
Команды lscpu и free оказались наиболее полезными, так как они предоставили четкие, человекочитаемые сводки о характеристиках оборудования без необходимости использовать сложные флаги. Инструмент systemd-detect-virt оказался удобен именно для проверки виртуализированной среды одним словом -- кратко и понятно.
