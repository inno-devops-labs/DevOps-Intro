# Submission 5 - Виртуализация и системный анализ

## Задание 1 - Установка VirtualBox

### Хостовая система
- ОС и версия: `Windows 10 Pro 10.0.19045 (build 19045)`
- Версия VirtualBox: `7.2.4r170995`

## Задание 2 - Ubuntu VM и системный анализ

### Конфигурация виртуальной машины
- Имя VM: `integration`
- Гостевая ОС: `Ubuntu 24.04 LTS (64-bit)`
- RAM: `6192 MB`
- CPU cores: `2`
- Диск: `30 GB VDI`
- Прошивка: `EFI enabled`
- Сеть: `NAT` (Intel PRO/1000 MT Desktop)


### 1) Информация о CPU
Инструмент: `lscpu`

Команда:
```bash
lscpu
```

Вывод:
```text
Architecture:                            x86_64
CPU op-mode(s):                          32-bit, 64-bit
Address sizes:                           48 bits physical, 48 bits virtual
Byte Order:                              Little Endian
CPU(s):                                  2
On-line CPU(s) list:                     0,1
Vendor ID:                               AuthenticAMD
Model name:                              AMD Ryzen 5 5600H with Radeon Graphics
CPU family:                              25
Model:                                   80
Thread(s) per core:                      1
Core(s) per socket:                      2
Socket(s):                               1
Stepping:                                0
BogoMIPS:                                6587.37
Flags:                                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid tsc_known_freq pni pclmulqdq ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm cmp_legacy cr8_legacy abm sse4a misalignsse 3dnowprefetch vmmcall fsgsbase bmi1 avx2 bmi2 rdseed adx clflushopt sha_ni arat
Hypervisor vendor:                       KVM
Virtualization type:                     full
NUMA node(s):                            1
NUMA node0 CPU(s):                       0,1
Vulnerability Gather data sampling:      Not affected
Vulnerability Ghostwrite:                Not affected
Vulnerability Indirect target selection: Not affected
Vulnerability Itlb multihit:             Not affected
Vulnerability L1tf:                      Not affected
Vulnerability Mds:                       Not affected
Vulnerability Meltdown:                  Not affected
Vulnerability Mmio stale data:           Not affected
Vulnerability Old microcode:             Not affected
Vulnerability Reg file data sampling:    Not affected
Vulnerability Retbleed:                  Not affected
Vulnerability Spec rstack overflow:      Vulnerable: Safe RET, no microcode
Vulnerability Spec store bypass:         Not affected
Vulnerability Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization
Vulnerability Spectre v2:                Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected
Vulnerability Srbds:                     Not affected
Vulnerability Tsa:                       Vulnerable: No microcode
Vulnerability Tsx async abort:           Not affected
Vulnerability Vmscape:                   Not affected
```

### 2) Информация о памяти
Инструмент: `free`

Команда:
```bash
free -h
```

Вывод:
```text
               total        used        free      shared  buff/cache   available
Mem:           5.8Gi       1.1Gi       3.8Gi        32Mi       1.2Gi       4.8Gi
Swap:          4.0Gi          0B       4.0Gi
```

### 3) Сетевая конфигурация
Инструменты: `ip`

Команды:
```bash
ip -br a
ip route
```

Вывод:
```text
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp0s3           UP             10.0.2.15/24 fd17:625c:f037:2:a0d7:bb04:604a:4bef/64 fd17:625c:f037:2:a00:27ff:fe09:3ad2/64 fe80::a00:27ff:fe09:3ad2/64

default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
```

### 4) Информация о хранилище
Инструменты: `df`, `lsblk`

Команды:
```bash
df -hT
lsblk -f
```

Вывод:
```text
Filesystem     Type     Size  Used Avail Use% Mounted on
tmpfs          tmpfs    598M  1.5M  596M   1% /run
/dev/sda2      ext4      30G  9.8G   19G  36% /
tmpfs          tmpfs    3.0G     0  3.0G   0% /dev/shm
tmpfs          tmpfs    5.0M  8.0K  5.0M   1% /run/lock
tmpfs          tmpfs    598M  128K  597M   1% /run/user/1000
/dev/sr0       iso9660   51M   51M     0 100% /media/david/VBox_GAs_7.2.4

NAME   FSTYPE   FSVER            LABEL          UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0  squashfs 4.0                                                                        0   100% /snap/core22/2292
loop1  squashfs 4.0                                                                        0   100% /snap/bare/5
loop2  squashfs 4.0                                                                        0   100% /snap/firmware-updater/210
loop3  squashfs 4.0                                                                        0   100% /snap/firefox/7766
loop4  squashfs 4.0                                                                        0   100% /snap/gnome-42-2204/247
loop5  squashfs 4.0                                                                        0   100% /snap/gtk-common-themes/1535
loop6  squashfs 4.0                                                                        0   100% /snap/snap-store/1270
loop7  squashfs 4.0                                                                        0   100% /snap/snapd/25935
loop8  squashfs 4.0                                                                        0   100% /snap/snapd-desktop-integration/343
sda
|-sda1
`-sda2 ext4     1.0                             f10b451e-81df-4020-aa08-32aa60f85298   18.1G    33% /
sr0    iso9660  Joliet Extension VBox_GAs_7.2.4 2025-10-17-10-20-48-34                     0   100% /media/david/VBox_GAs_7.2.4
```

### 5) Информация об операционной системе
Инструменты: `cat`, `uname`

Команды:
```bash
cat /etc/os-release
uname -a
```

Вывод:
```text
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

Linux david-VirtualBox 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```

### 6) Обнаружение виртуализации
Инструмент: `systemd-detect-virt`

Команда:
```bash
systemd-detect-virt
```

Вывод:
```text
oracle
```

## Рефлексия
- Наиболее полезные инструменты:
  - `lscpu` удобно показывает архитектуру, число ядер и признаки виртуализации в одной команде.
  - `ip` быстро дает состояние интерфейсов и таблицу маршрутизации.
  - `df -hT` и `lsblk -f` хорошо дополняют друг друга: занятость файловых систем и структура блочных устройств.

