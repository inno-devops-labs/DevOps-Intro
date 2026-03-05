\## Задание 1 ##

* Операционная система и версия хоста : Windows 11 25H2
* Номер версии Virtual Box : 7.2.4 r170995
* Проблем при установке не возникло 
  

\## Задание 2 ##



* Характеристики конфигурации виртуальной машины : 
* ОЗУ - 8735 МБ (~8.5 ГБ) ;
* &nbsp;Хранилище - 35 ГБ ;
* &nbsp;Ядра - 4 шт ;
* &nbsp;Виртуализация - Oracle VirtualBox.





1\) Процессор 



Инструменты: lscpu, /proc/cpuinfo  



Использованная команда: lscpu  



Полный вывод:



Архитектура: x86\_64

CPU op-mode(s): 32-bit, 64-bit

Address sizes: 48 bits physical, 48 bits virtual

Порядок байт: Little Endian

CPU(s): 4

On-line CPU(s) list: 0-3

ID прроизводителя: AuthenticAMD

Имя модели: AMD Ryzen 7 3700U with Radeon Vega Mobile Gfx

Семейство ЦПУ: 23

Модель: 24

Потоков на ядро: 1

Ядер на сокет: 4

Сокетов: 1

Степпинг: 1

BogoMIPS: 4591,38

Флаги: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr\_opt rdtscp lm constant\_tsc rep\_good nopl nonstop\_tsc cpuid extd\_apicid tsc\_known\_freq pni pclmulqdq ssse3 fma cx16 sse4\_1 sse4\_2 x2apic movbe popcnt aes xsave avx f16c rdrand hypervisor lahf\_lm cmp\_legacy cr8\_legacy abm sse4a misalignsse 3dnowprefetch ssbd vmmcall fsgsbase bmi1 avx2 bmi2 rdseed adx clflushopt sha\_ni arat

Virtualization features:

Разработчик гипервизора: KVM

Тип виртуализации: полный

Caches (sum of all):

L1d: 128 KiB (4 instances)

L1i: 256 KiB (4 instances)

L2: 2 MiB (4 instances)

L3: 16 MiB (4 instances)

NUMA:

NUMA node(s): 1

NUMA node0 CPU(s): 0-3

Vulnerabilities:

Gather data sampling: Not affected

Ghostwrite: Not affected

Indirect target selection: Not affected

Itlb multihit: Not affected

L1tf: Not affected

Mds: Not affected

Meltdown: Not affected

Mmio stale data: Not affected

Old microcode: Not affected

Reg file data sampling: Not affected

Retbleed: Mitigation; untrained return thunk; SMT disabled

Spec rstack overflow: Mitigation; SMT disabled

Spec store bypass: Not affected

Spectre v1: Mitigation; usercopy/swapgs barriers and \_\_user pointer sanitization

Spectre v2: Mitigation; Retpolines; STIBP disabled; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected

Srbds: Not affected

Tsa: Not affected

Tsx async abort: Not affected

Vmscape: Not affected



Обзор: `lscpu` даёт сводку по процессору, включая архитектуру, количество ядер, модель и флаги. Это наиболее удобный инструмент для быстрого получения всей информации о CPU. 







2\)  Оперативная память 



Инструменты: free, /proc/meminfo  



Использованная команда: free -h  



Полный вывод:



всего занят своб общая буф/врем. доступно

Память: 8,3Gi 1,1Gi 5,8Gi 34Mi 1,6Gi 7,2Gi

Подкачка: 4,0Gi 0B 4,0Gi



Обзор: free -h отображает использование оперативной памяти и раздела подкачки . Позволяет быстро оценить общий объём, занятую и доступную память.



3\) Сетевая конфигурация



Инструменты: ip, ifconfig  



Использованная команда: ip addr  



Полный вывод:



1: lo: <LOOPBACK,UP,LOWER\_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000

link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00

inet 127.0.0.1/8 scope host lo

valid\_lft forever preferred\_lft forever

inet6 ::1/128 scope host noprefixroute

valid\_lft forever preferred\_lft forever

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER\_UP> mtu 1500 qdisc fq\_codel state UP group default qlen 1000

link/ether 08:00:27:1d:91:be brd ff:ff:ff:ff:ff:ff

inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3

valid\_lft 86229sec preferred\_lft 86229sec

inet6 fd17:625c:f037:2:1440:450f:a2b1:a42c/64 scope global temporary dynamic

valid\_lft 86231sec preferred\_lft 14231sec

inet6 fd17:625c:f037:2:a00:27ff:fe1d:91be/64 scope global dynamic mngtmpaddr

valid\_lft 86231sec preferred\_lft 14231sec

inet6 fe80::a00:27ff:fe1d:91be/64 scope link

valid\_lft forever preferred\_lft forever



Обзор: ip addr показывает все сетевые интерфейсы, их IP-адреса (IPv4 и IPv6) и состояние. Это современная замена ifconfig.



4\) Хранилище и файловые системы



Инструменты: df, lsblk, blkid  



Использованные команды: df -h, lsblk, blkid  



Полный вывод:



df -h:



Файл.система Размер Использовано Дост Использовано% Cмонтировано в

tmpfs 847M 1,7M 845M 1% /run

/dev/sda2 34G 9,5G 23G 30% /

tmpfs 4,2G 0 4,2G 0% /dev/shm

tmpfs 5,0M 8,0K 5,0M 1% /run/lock

tmpfs 847M 156K 846M 1% /run/user/1000



lsblk:



NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS

loop0 7:0 0 4K 1 loop /snap/bare/5

loop1 7:1 0 251,7M 1 loop /snap/firefox/7766

loop2 7:2 0 18,5M 1 loop /snap/firmware-updater/210

loop3 7:3 0 74M 1 loop /snap/core22/2292

loop4 7:4 0 531,4M 1 loop /snap/gnome-42-2204/247

loop5 7:5 0 91,7M 1 loop /snap/gtk-common-themes/1535

loop6 7:6 0 10,8M 1 loop /snap/snap-store/1270

loop7 7:7 0 48,1M 1 loop /snap/snapd/25935

loop8 7:8 0 576K 1 loop /snap/snapd-desktop-integration/343

sda 8:0 0 34G 0 disk

├─sda1 8:1 0 1M 0 part

└─sda2 8:2 0 34G 0 part /

sr0 11:0 1 1024M 0 rom



blkid:



/dev/sda2: UUID="ec185415-bbdc-4815-8b56-08b43b4dc65c" BLOCK\_SIZE="4096" TYPE="ext4" PARTUUID="0037adb5-4817-4f52-bceb-5108301ef784"





Обзор: 



\- df -h показывает занятое и свободное место на смонтированных файловых системах;

\- lsblk отображает древовидную структуру блочных устройств (диски, разделы) с размерами;

\- blkid выводит UUID и тип файловой системы для устройств.



6\) Обнаружение виртуализации



Инструменты: systemd-detect-virt, lspci, dmidecode  



Использованные команды: systemd-detect-virt, lspci  



Полный вывод:



systemd-detect-virt:



oracle



lscpi:



00:00.0 Host bridge: Intel Corporation 440FX - 82441FX PMC \[Natoma] (rev 02)

00:01.0 ISA bridge: Intel Corporation 82371SB PIIX3 ISA \[Natoma/Triton II]

00:01.1 IDE interface: Intel Corporation 82371AB/EB/MB PIIX4 IDE (rev 01)

00:02.0 VGA compatible controller: VMware SVGA II Adapter

00:03.0 Ethernet controller: Intel Corporation 82540EM Gigabit Ethernet Controller (rev 02)

00:04.0 System peripheral: InnoTek Systemberatung GmbH VirtualBox Guest Service

00:05.0 Multimedia audio controller: Intel Corporation 82801AA AC'97 Audio Controller (rev 01)

00:06.0 USB controller: Apple Inc. KeyLargo/Intrepid USB

00:07.0 Bridge: Intel Corporation 82371AB/EB/MB PIIX4 ACPI (rev 08)

00:0b.0 USB controller: Intel Corporation 82801FB/FBM/FR/FW/FRW (ICH6 Family) USB2 EHCI Controller

00:0d.0 SATA controller: Intel Corporation 82801HM/HEM (ICH8M/ICH8M-E) SATA Controller \[AHCI mode] (rev 02)



Краткий обзор: 

* systemd-detect-virt быстро и надёжно определяет тип гипервизора ; 
* lspci показывает устройства PCI, среди которых присутствуют типичные для VirtualBox , что  подтверждает виртуализацию.





