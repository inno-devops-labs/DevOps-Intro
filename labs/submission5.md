
# Task 1 

### Host operating system
- OS: Windows 11 Home Single Language
- Version: 25H2 (OS Build 26200.7840)

### VirtualBox version
- VirtualBox: 7.2.4-170995

### Installation notes / issues
- VirtualBox had already been installed previously for coursework in Computer Architecture.
- Installation verification was completed by launching the application and checking the installed version through the GUI.
- Issues encountered: None
___
# Task 2 — Ubuntu VM and System Analysis

### VM configuration
- RAM: 4096 MB
- Storage: 25 GB dynamic virtual disk
- CPU: 2 cores

---

### CPU Information
Tool: lscpu

Command:
```
lscpu
```

Output:

```
Architecture: x86_64
CPU(s): 2
Model name: 12th Gen Intel(R) Core(TM) i5-12500H
Hypervisor vendor: KVM
Virtualization type: full
```
___
### Memory Information

Tool: free

Command:

```
free -h
```

Output:

```
Mem: 3.8Gi total, 1.0Gi used, 1.5Gi free, 2.8Gi available
Swap: 3.8Gi total
```
___

### Network Information

Tool: ip

Command:

```
ip a
```

Output:

```
Interface: enp0s3
IPv4 address: 10.0.2.15/24
State: UP
```
___

### Storage Information

Tools: lsblk, df

Command:

```
lsblk
df -h
```

Output:

```
Disk: /dev/sda 25G
Root partition: /dev/sda2 25G
Mounted root filesystem usage: 40%
```
___

### Operating System Information

Tools: uname, os-release

Command:

```
uname -a
cat /etc/os-release
``` 

Output:

```
Ubuntu 24.04.4 LTS
Kernel: 6.17.0-14-generic
Architecture: x86_64
```
___

### Virtualization Detection

Tool: systemd-detect-virt

Command:

```
systemd-detect-virt
``` 

Output:

```
oracle
```
___
### Brief reflection

The most useful tools during this task were `lscpu`, `free -h`, `ip a`, and `systemd-detect-virt`.

- `lscpu` was useful because it quickly showed processor architecture, CPU model, number of allocated cores, and virtualization details.
- `free -h` provided a clear overview of total, used, and available memory inside the virtual machine in human-readable format.
- `ip a` was important for identifying active network interfaces and assigned IP addresses, which confirms network connectivity inside the VM.
- `systemd-detect-virt` was especially useful because it directly confirmed that the system is running inside a virtualized environment managed by Oracle VirtualBox.

Among all commands, `lscpu` and `systemd-detect-virt` were the most informative because they immediately revealed both hardware abstraction and virtualization context.