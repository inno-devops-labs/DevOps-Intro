# Lab 5 — Submission

## Task 1 — VirtualBox Installation

### Host OS
- OS: Windows 11 Pro
- Version: 25H2
- OS Build: 26200.7922

### VirtualBox
- VirtualBox version: 7.2.6 r172322 (Qt6.8.0 on Windows)

### Installation notes / issues
- VirtualBox was already installed on the host system.
- The installation was verified by checking the VirtualBox version through the graphical interface (Help → About VirtualBox).
- No issues were encountered during verification.

## Task 2 — Ubuntu VM and System Analysis

### VM Configuration

- OS: Ubuntu 24.04 LTS
- RAM: 4 GB
- CPU: 2 cores
- Storage: 25 GB
- Virtualization platform: VirtualBox


### CPU Information
Tool: `lscpu`

Command:
```sh
lscpu
```
Output:
![5_img_1.png](screenshots%2F5_img_1.png)
![5_img_2.png](screenshots%2F5_img_2.png)

### Memory Information
Tool: `free`

Command:
```sh
free -h
```
Output:
![5_img_3.png](screenshots%2F5_img_3.png)

### Network Configuration
Tool: `ip`

Command:
```sh
ip a
```
Output:
![5_img_4.png](screenshots%2F5_img_4.png)

### Storage Information
Tools: `df`, `lsblk`

Commands:
```sh
df -h
lsblk
```

Output:
![5_img_5.png](screenshots%2F5_img_5.png)
![5_img_6.png](screenshots%2F5_img_6.png)

### Operating System

Tools: `lsb_release`, `uname`

Commands:
```sh
lsb_release -a
uname -a
```
Output:
![5_img_7.png](screenshots%2F5_img_7.png)
![5_img_8.png](screenshots%2F5_img_8.png)

### Virtualization Detection

Tool: `systemd-detect-virt`

Command:
```sh
systemd-detect-virt
```
Output:

![5_img_9.png](screenshots%2F5_img_9.png)

### Reflection
The most useful tools were `lscpu`, `free`, `ip`, and `df` because they provide clear and structured information about the system hardware, memory, networking, and storage.

The command `systemd-detect-virt` was particularly useful because it confirmed that the system is running inside a virtual machine (VirtualBox).