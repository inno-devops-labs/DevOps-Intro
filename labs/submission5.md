# Lab 5 --- Virtualization and System Analysis

## Platform

Virtual Machine running **Ubuntu 24.04 LTS** inside **Oracle
VirtualBox**.

------------------------------------------------------------------------

# Task 2 --- System Analysis

## Operating System Information

### Command

    uname -a

### Output

    Linux andrey-VirtualBox 6.17.0-14-generic #14~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Jan 15 15:52:10 UTC x86_64 x86_64 x86_64 GNU/Linux

### Detailed OS information

Command

    cat /etc/os-release

Output

    PRETTY_NAME="Ubuntu 24.04.4 LTS"
    NAME="Ubuntu"
    VERSION_ID="24.04"
    VERSION="24.04.4 LTS (Noble Numbat)"
    VERSION_CODENAME=noble
    ID=ubuntu
    ID_LIKE=debian

### Conclusion

The system is running **Ubuntu 24.04.4 LTS (Noble Numbat)**.

------------------------------------------------------------------------

# CPU Information

### Command

    lscpu

### Key Information

-   Architecture: **x86_64**
-   CPU Model: **AMD Ryzen 5 3500U with Radeon Vega Mobile Gfx**
-   CPU cores allocated to VM: **2**
-   Virtualization type: **full**
-   Hypervisor vendor: **KVM**

### Conclusion

The virtual machine is using **2 virtual CPU cores provided by the host
machine**.

------------------------------------------------------------------------

# Memory Information

### Command

    free -h

### Output

    Mem:   3.8Gi total
    Used:  1.0Gi
    Free:  1.3Gi
    Swap:  3.8Gi

### Conclusion

The virtual machine has:

-   **3.8 GB RAM**
-   **3.8 GB swap memory**

Memory usage is relatively low.

------------------------------------------------------------------------

# Storage Information

### Command

    lsblk

### Output

    sda   25G disk
    └─sda2 25G mounted on /

### Disk Usage

Command

    df -h

Output

    Filesystem      Size  Used Avail Use%
    /dev/sda2        25G  9.5G   14G  41%

### Conclusion

The system uses a **25 GB virtual disk**, with **14 GB available free
space**.

------------------------------------------------------------------------

# Network Configuration

### Command

    ip a

### Key Information

Network interface:

    enp0s3

IP address:

    10.0.2.15

### Conclusion

The VM is connected to the network using **VirtualBox NAT networking**.

------------------------------------------------------------------------

# Virtualization Detection

### Command

    systemd-detect-virt

### Output

    oracle

### Conclusion

The operating system correctly detects that it is running inside
**Oracle VirtualBox virtualization environment**.

------------------------------------------------------------------------

# Final Summary

This lab demonstrated system inspection inside a virtual machine
environment.

The analyzed system has:

-   Ubuntu **24.04 LTS**
-   **2 virtual CPU cores**
-   **\~4 GB RAM**
-   **25 GB virtual disk**
-   NAT network configuration
-   Virtualization platform: **Oracle VirtualBox**

The system tools successfully detected the virtualization environment
and provided detailed information about system resources.
