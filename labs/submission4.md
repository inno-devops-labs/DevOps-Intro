## 1.1 Boot Performance Analysis

### systemd-analyze
Startup finished in 1.718s (userspace)
graphical.target reached after 1.687s in userspace.

### systemd-analyze blame
823ms landscape-client.service
415ms snapd.seeded.service
399ms dev-sdd.device
306ms snapd.service
244ms wsl-pro.service
198ms logrotate.service
177ms systemd-udev-trigger.service
175ms user@0.service
159ms systemd-resolved.service
89ms rsyslog.service
72ms systemd-journald.service
68ms keyboard-setup.service
65ms systemd-journal-flush.service
63ms systemd-logind.service
55ms systemd-udevd.service
51ms systemd-timesyncd.service
48ms dpkg-db-backup.service
41ms e2scrub_reap.service
...

### Key observations
Boot to graphical.target ~1.7s. Top contributors: landscape-client.service and snapd-related services.

## 1.2 System Load

### uptime
06:12:21 up  1:11,  1 user,  load average: 0.00, 0.00, 0.00
### w
06:12:25 up  1:11,  1 user,  load average: 0.00, 0.00, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
root     pts/1    -                05:00    1:11m  0.02s  0.02s -bash

### Key observations
System load and active sessions observed at time of analysis.

## 1.3 Process Forensics

### Top memory-consuming processes
    PID    PPID CMD                         %MEM %CPU
    222       1 /usr/bin/python3 /usr/share  0.2  0.0
    155       1 /usr/lib/systemd/systemd-re  0.1  0.0
    192       1 /usr/libexec/wsl-pro-servic  0.1  0.0
      1       0 /sbin/init                   0.1  0.0
     52       1 /usr/lib/systemd/systemd-jo  0.1  0.0

### Top CPU-consuming processes
    PID    PPID CMD                         %MEM %CPU
    595     322 ps -eo pid,ppid,cmd,%mem,%c  0.0  100
      1       0 /sbin/init                   0.1  0.0
    100       1 /usr/lib/systemd/systemd-ud  0.0  0.0
     52       1 /usr/lib/systemd/systemd-jo  0.1  0.0
    192       1 /usr/libexec/wsl-pro-servic  0.1  0.0

Top memory-consuming process:     222   1 /usr/bin/python3 /usr/share  0.2  0.0

### Key observations
Top memory and CPU processes identified at analysis time.

## 1.4 Service Dependencies

### systemctl list-dependencies
default.target
● ├─display-manager.service
● ├─systemd-update-utmp-runlevel.service
● ├─wslg.service
● └─multi-user.target
●   ├─apport.service
●   ├─console-setup.service
●   ├─cron.service
●   ├─dbus.service
●   ├─dmesg.service
●   ├─e2scrub_reap.service
●   ├─landscape-client.service
●   ├─networkd-dispatcher.service
●   ├─rsyslog.service
●   ├─snapd.apparmor.service
●   ├─snapd.autoimport.service
●   ├─snapd.core-fixup.service
●   ├─snapd.seeded.service
●   ├─snapd.service
●   ├─systemd-logind.service
●   ├─systemd-user-sessions.service
●   ├─unattended-upgrades.service
●   ├─wsl-pro.service
●   └─basic.target
●     ├─paths.target
●     ├─slices.target
●     ├─sockets.target
●     └─sysinit.target

### systemctl list-dependencies multi-user.target
multi-user.target
● ├─apport.service
● ├─console-setup.service
● ├─cron.service
● ├─dbus.service
● ├─landscape-client.service
● ├─networkd-dispatcher.service
● ├─rsyslog.service
● ├─snapd.service
● ├─systemd-logind.service
● ├─systemd-user-sessions.service
● ├─unattended-upgrades.service
● ├─wsl-pro.service
● └─basic.target

### Key observations
System uses a standard systemd dependency hierarchy.  
multi-user.target aggregates core services such as cron, dbus, logging, and snapd.  
WSL-specific services (wslg, wsl-pro) appear as part of the boot chain.

## 1.5 User Sessions

### who -a
system boot  2026-02-27 05:00
run-level 5  2026-02-27 05:00
LOGIN console 2026-02-27 05:00 196 id=cons
LOGIN tty1    2026-02-27 05:00 210 id=tty1
root  pts/1   2026-02-27 05:00 (active session)

### last -n 5
reboot  system boot 6.6.87.2-microsoft  Fri Feb 27 05:00  still running
reboot  system boot 6.6.87.2-microsoft  Wed Dec 10 12:02  still running
reboot  system boot 6.6.87.2-microsoft  Sat Nov 15 00:13  still running
reboot  system boot 6.6.87.2-microsoft  Wed Sep 24 02:31  still running
reboot  system boot 6.6.87.2-microsoft  Thu Sep 18 17:40  still running

### Key observations
System currently running since Feb 27 05:00.  
Single active root session via pts.  
Multiple previous reboots recorded (WSL kernel).

## 1.6 Memory Analysis

### free -h
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       495Mi       7.2Gi       3.5Mi       159Mi       7.2Gi
Swap:          2.0Gi         0B       2.0Gi

### /proc/meminfo (filtered)
MemTotal:       8056016 kB
MemAvailable:   7548860 kB
SwapTotal:      2097152 kB

### Key observations
System has ~7.7 GiB RAM with very low usage (~495 MiB).
Most memory is available; no swap is currently used.

## 2.1 Network Path Tracing

### traceroute github.com
traceroute to github.com (140.82.121.4), 30 hops max, 60 byte packets
 1  DESKTOP-BNQOR3 (172.28.96.1)  1.644 ms  1.576 ms  1.526 ms
 2  * * *
 3  * * *
 4  * * *
 ...
30  * * *

### Key observations
First hop is the WSL virtual gateway (172.28.96.1).
All subsequent hops do not respond (likely ICMP blocked by upstream network or firewall).
Target IP resolved successfully to 140.82.121.4.

## 2.2 DNS Resolution Check

### dig github.com
;; ->>HEADER<<- opcode: QUERY, status: NOERROR
;; flags: qr rd ad; QUERY: 1, ANSWER: 1
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;github.com.            IN  A

;; ANSWER SECTION:
github.com.     0   IN  A   140.82.121.4

Query time: 173 msec
SERVER: 172.28.96.1#53 (WSL internal DNS)
MSG SIZE  rcvd: 54

### Key observations
DNS resolution successful.
github.com resolved to 140.82.121.4.
Query handled by WSL internal DNS resolver (172.28.96.1).

## 2.3 Packet Capture (DNS)

### tcpdump output
07:02:25.924924 eth0  Out IP 172.28.102.220.56434 > 172.28.96.1.53: 13348+ A? google.com. (51)
07:02:25.976466 eth0  In  IP 172.28.96.1.53 > 172.28.102.220.56434: 13348 1/0/0 A 142.251.38.78 (54)

2 packets captured

### One example DNS query (sanitized explanation)
Client (172.28.102.220) queried DNS server (172.28.96.1) for A record of google.com.  
DNS server responded with IP address 142.251.38.78.

### Key observations
DNS request sent from WSL instance to internal resolver.
Standard UDP port 53 traffic observed.
Query-response pattern clearly visible (A record lookup).

## 2.4 Reverse DNS (PTR Lookup)

### dig -x 8.8.4.4
;; status: NOERROR

;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.    IN  PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.  0  IN  PTR  dns.google.

Query time: 77 msec
SERVER: 172.28.96.1#53 (WSL internal DNS)

### dig -x 1.1.2.2
;; status: NXDOMAIN

;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.    IN  PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.  1798  IN  SOA  ns.apnic.net. ...

Query time: 1281 msec
SERVER: 172.28.96.1#53 (WSL internal DNS)

### Comparison of results
8.8.4.4 successfully resolved to dns.google (valid PTR record).
1.1.2.2 returned NXDOMAIN, meaning no PTR record exists.
Reverse DNS availability depends on whether the IP owner configured PTR records.