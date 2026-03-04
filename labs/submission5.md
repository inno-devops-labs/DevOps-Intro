# Lab 5 submission

## Task 1

- Host operating system and version: Windows 11 Pro 25H2
- VirtualBox version number: 7.2.4 r170995
- Any installation issues encountered: I already had VirtualBox installed.

## Task 2

1. **CPU Details:** 
Commands used: `lscpu`, `cpu-info`
![5.1](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.1.jpg?raw=true)
![5.2](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.2.jpg?raw=true)
![5.3](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.3.jpg?raw=true)

`lscpu` was more useful because it gave more information than `cpu-info`.

2. **Memory Information**: 
Commands used: `free -h`, `cat /proc/meminfo`
![5.4](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.4.jpg?raw=true)
![5.5](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.5.jpg?raw=true)
![5.6](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.6.jpg?raw=true)

Both commands were useful because they gave different type of information about memory.

(I did not gave Ubuntu storage of 25GB because I did not have enough memory on my machine)

3. **Network Configuration**: 
Commands used: `ip addr show`, `ip link show`
![5.7](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.7.jpg?raw=true)

`ip addr show` was more useful because it gave more information than `ip link show`.

4. **Storage Information**: 
Commands used: `df -h`, `df -hT`
![5.8](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.8.jpg?raw=true)

`df -hT` was more useful because it gave a little bit more information than `df -h`.

5. **Operating System**: 
Commands used: `uname -a`, `lsb_release -a`
![5.9](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.9.jpg?raw=true)

`uname -a` was more useful because it gave a little bit more information than `lsb_release -a`.

6. **Virtualization Detection**: 
Commands used: `systemd-detect-virt`
![5.10](https://github.com/sarrtr/DevOps-Intro/blob/main/labs/assets/screenshots/lab5.10.jpg?raw=true)