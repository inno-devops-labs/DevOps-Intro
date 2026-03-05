# Task 1
Installed succes,  without any issues
Platfrom : Windows 11 Home
Version of VM box :  7.2.4 r17099
![alt text](image-39.png)

# Task 2
## VM config:
![alt text](image-40.png)

![alt text](image-41.png)

## CPU info: 
### tools:
lscpu
### used command:
lscpu
cat /proc/cpuinfo | grep -E "model name|cpu MHz|cpu cores|siblings"
### output
![alt text](image-42.png)

## Memory infomation
### tools:
free
### used command:
free -h
### output
![alt text](image-43.png)

## Network Configuration

used command
ip addr show
hostname -I
![alt text](image-44.png)

## Storage Information
### tools :
df
lsblk
fdisk
### used command:
df -h
lsblk
sudo fdisk -l
### output
![alt text](image-45.png)

![alt text](image-46.png)
![alt text](image-47.png)
## Operating System
### tools : 
lsb_release
uname
hostnamectl

### used commands :  
lsb_release -a
cat /etc/os-release
uname -a
hostnamectl
### output
![alt text](image-48.png)
![alt text](image-49.png)

## Virtualization Detection
tools: 
systemd-detect-virt
lscpu
dmesg
dmidecode
### command used: 
systemd-detect-virt
lscpu | grep Hypervisor
dmesg | grep -i virtual
dmidecode -s system-manufacturer  
### output
![alt text](image-50.png)


## Analyze
Most useful lscpu, shows a lot of useful info about cpu frequnecy nad hypervisor. And fdisk -l, showed whole segmentation of memory disk.