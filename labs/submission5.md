
## Task 1.

![[Pasted image 20260305150107.png]]

**Параллельно идет курс компарча, поэтому VirtualBox был предустановлен.**

	Версия VirtualBox: 7.2.4
	Версия ОС: Windows 11 Pro
	Проблем не возникло

---

## Task 2.

### 2.1 Конфигурация виртуальной машины

- **RAM:** 4 ГБ
- **Storage:** 25 ГБ
- **CPU cores:** 2

---
### 2.2 Системная информация

**lscpu** - показывает информацию о процессоре

	Architecture: x86_64  
	CPU(s): 2  
	Model name: 12th Gen Intel(R) Core(TM) i5-12450H  
	Core(s) per socket: 2  
	Hypervisor vendor: KVM  
	Virtualization type: full

**free -h** - показывает использование оперативной памяти

	total used free shared buff/cache available  
	Mem: 3.8Gi 1.1Gi 1.4Gi 32Mi 1.6Gi 2.7Gi  
	Swap: 0B 0B 0B

**ip a** - показывает сетевые интерфейсы и IP-адреса

	1: lo:  
	inet 127.0.0.1/8 scope host lo  
	2: enp0s3:  
	inet 10.0.2.15/24 scope global dynamic enp0s3  
	inet6 fe80::a00:27ff:fe28:f96e/64 scope link
	
**df -h** - показывает использование дискового пространства

	Filesystem Size Used Avail Use% Mounted on  
	/dev/sda2 25G 5.5G 18G 24% /  
	tmpfs 392M 1.7M 390M 1% /run
	
**lsblk** - показывает структуру дисков и разделов

	NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS  
	sda 8:0 0 25G 0 disk  
	├─sda1 8:1 0 1M 0 part  
	└─sda2 8:2 0 25G 0 part /

**lsb_release -a** - показывает информацию о версии Ubuntu

	Distributor ID: Ubuntu  
	Description: Ubuntu 24.04.4 LTS  
	Release: 24.04  
	Codename: noble

**uname -a** - показывает информацию о ядре системы

	Linux Intro-DevOps 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC x86_64 GNU/Linux

**systemd-detect-virt** - определяет тип виртуализации

	oracle
---
