
## Задание 1
Windows 11 Домашняя для одного языка
VirtualBox: Version 7.2.4 r170995 (Qt6.8.0 on windows)
Устанавливала ещё в начале года для другого предмета, сложностей не было.

## Задание 2
Используемые параметры конфигурации виртуальной машины:
ОЗУ: 7.8 GiB
Хранилище: 25 GB
CPU: 6 ядер / 12 потоков
Среда виртуализации: VirtualBox

- Информация о процессоре

Инструмент: lscpu

Команда:
lscpu

Полный вывод команды:
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             48 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      12
  On-line CPU(s) list:       0-11
Vendor ID:                   AuthenticAMD
  Model name:                AMD Ryzen 5 5500U with Radeon Graphics
    CPU family:              25
    Model:                   68
    Thread(s) per core:      2
    Core(s) per socket:      6
    Socket(s):               1
    Stepping:                1
    BogoMIPS:                6587.43
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pg
                             e mca cmov pat pse36 clflush mmx fxsr sse sse2 ht s
                             yscall nx mmxext fxsr_opt rdtscp lm constant_tsc re
                             p_good nopl xtopology nonstop_tsc cpuid extd_apicid
                              tsc_known_freq pni pclmulqdq ssse3 fma cx16 sse4_1
                              sse4_2 movbe popcnt aes xsave avx f16c rdrand hype
                             rvisor lahf_lm cmp_legacy cr8_legacy abm sse4a misa
                             lignsse 3dnowprefetch vmmcall fsgsbase bmi1 avx2 bm
                             i2 invpcid rdseed adx clflushopt sha_ni arat debug_
                             swap
Virtualization features:     
  Hypervisor vendor:         KVM
  Virtualization type:       full
NUMA:                        
  NUMA node(s):              1
  NUMA node0 CPU(s):         0-11
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
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:                Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected
  Srbds:                     Not affected
  Tsa:                       Vulnerable: No microcode
  Tsx async abort:           Not affected
  Vmscape:                   Not affected

- Информация о памяти

Инструмент: free

Команда:
free -h

Полный вывод команды:
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       1.6Gi       4.1Gi        45Mi       2.3Gi       6.1Gi
Swap:             0B          0B          0B

- Информация о сети

Инструмент: ip

Команда:
ip a

Полный вывод команды:
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:64:8b:6f brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86146sec preferred_lft 86146sec
    inet6 fd17:625c:f037:2:9864:f483:dca:8a20/64 scope global temporary dynamic 
       valid_lft 86148sec preferred_lft 14148sec
    inet6 fd17:625c:f037:2:a00:27ff:fe64:8b6f/64 scope global dynamic mngtmpaddr 
       valid_lft 86148sec preferred_lft 14148sec
    inet6 fe80::a00:27ff:fe64:8b6f/64 scope link 
       valid_lft forever preferred_lft forever

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
link/ether 08:00:27:64:8b:6f
inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3

- Информация о хранилище

Инструмент: df

Команда:
df -h

Полный вывод команды:
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           795M  1.5M  793M   1% /run
/dev/sda2        25G  6.2G   18G  27% /
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
tmpfs           795M  124K  794M   1% /run/user/1000

- Информация об операционной системе

Инструмент: cat

Команда:
cat /etc/os-release

Полный вывод команды:
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

- Дополнительная информация о ядре

Инструмент: uname

Команда:
uname -a

Полный вывод команды:
Linux ksgo 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC 2 x86_64 x86_64 x86_64 GNU/Linux

- Обнаружение виртуализации

Инструмент: dmidecode

Команда:
sudo dmidecode -s system-product-name

Полный вывод команды:
[sudo] password for vboxuser:
VirtualBox


Наиболее полезными оказались команды lscpu, free, ip a и df -h. Они позволяют быстро получить основную информацию о системе: процессоре, памяти, сети и диске. Эти инструменты удобны тем, что уже встроены в Linux и дают понятный вывод без установки дополнительных программ. Также полезной оказалась команда dmidecode, с помощью которой можно определить, что система запущена в виртуальной машине VirtualBox.
