# Task 1 — Virtualization Software Installation

# Host Operating System: macOS

# Virtualization Software: UTM

# Version: UTM 4.7.5 (118)

# Installation Issues
# Проблем с установкой UTM не возникило, но установить Virtual Box не получилось, из-за операционной системы (ни один из вариантов не поддерживается)


# Task 2 

## Конфигурация виртуальной машины

RAM: 4 GB  
CPU: 2 ядра  
Диск: 25 GB  

## Информация о процессоре

Используемый инструмент: lscpu

Команда:
lscpu

Вывод:

Architecture:                    aarch64  
CPU op-mode(s):                  32-bit, 64-bit  
Byte Order:                      Little Endian  
CPU(s):                          2  
On-line CPU(s) list:             0-1  
Vendor ID:                       ARM  
Model name:                      Virtual CPU  
Thread(s) per core:              1  
Core(s) per socket:              2  
Socket(s):                       1  
Virtualization:                  full  
Hypervisor vendor:               KVM  

## Информация о памяти

Используемый инструмент: free

Команда:
free -h

Вывод:

total        used        free      shared  buff/cache   available  
Mem:           3.8Gi       1.1Gi       1.9Gi       120Mi       800Mi       2.5Gi  
Swap:          2.0Gi          0B       2.0Gi  

## Сетевая конфигурация

Используемый инструмент: ip

Команда:
ip a

Вывод:

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536  
    inet 127.0.0.1/8 scope host lo  

2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500  
    inet 192.168.64.5/24 brd 192.168.64.255 scope global eth0  

## Информация о дисках

Используемый инструмент: df

Команда:
df -h

Вывод:

Filesystem      Size  Used Avail Use% Mounted on  
/dev/vda1        25G  6.2G   18G  26% /  
tmpfs           1.9G  2.0M  1.9G   1% /run  
tmpfs           3.8G     0  3.8G   0% /dev/shm  

## Информация об операционной системе

Используемые инструменты: lsb_release, uname

Команды:

lsb_release -a  
uname -a  

Вывод:

Distributor ID: Ubuntu  
Description: Ubuntu 24.04 LTS  
Release: 24.04  
Codename: noble  

Linux ubuntu-vm 6.8.0-31-generic #31-Ubuntu SMP aarch64 GNU/Linux  

## Определение виртуализации

Используемый инструмент: systemd-detect-virt

Команда:
systemd-detect-virt

Вывод:

kvm

## Краткое размышление

Самыми полезными инструментами были `lscpu`, `free -h` и `df -h`, потому что они дают понятную информацию о процессоре, памяти и использовании диска. Эти команды помогают быстро понять конфигурацию системы и ресурсы, доступные внутри виртуальной машины.