# Lab 5 — Virtualization & System Analysis

## Task 1

- Windows 11 (64-bit)
- Version 7.2.6 (amd64)
- No installation issues

![VirtualBox screenshot](./vbox.png)

## Task 2

### Commands & Outputs

- CPU Details

![cpu details 1](./lscpu.png)

![cpu details 2](./proc_cpuinfo.png)

![cpu details 3](./uname_nproc.png)

- Memory Information

![mem info](./memory.png)

- Network Configuration

![ip info](./ip.png)

- Storage Information

![storage info](./filesystem.png)

- Operating System Information

![os info](./ubuntu.png)

- Virtualization Detection

![virt info](./virt.png)

## Summary  

From my point of view, the most useful tools were `lscpu`, `free -h`, `ip a`, `df -h`, `lsb_release -a`, and `systemd-detect-virt` as they provide clear and concise information. Also, most of them are pretty short and easy for use.
