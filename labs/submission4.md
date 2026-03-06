
# Lab 4 — Operating Systems & Networking

**Student:** Kamilya Shakirova
**Date:** 27-02-2026

---

## Task 1 — Operating System Analysis

- [x] All command outputs for sections 1.1-1.5.
- [x] Key observations for each analysis section.
- [x] Answer: "What is the top memory-consuming process?"
- [x] Note any resource utilization patterns you observe.

### 1.1 Boot Performance Analysis

1. **Analyze System Boot Time:**

```sh
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ systemd-analyze
Startup finished in 2.565s (userspace) 
graphical.target reached after 2.530s in userspace

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ systemd-analyze blame
1.932s snapd.seeded.service
1.799s snapd.service
 363ms dev-sdd.device
 345ms networkd-dispatcher.service
 244ms systemd-resolved.service
 118ms user@1000.service
 112ms systemd-logind.service
  77ms apport.service
  71ms systemd-journal-flush.service
  63ms systemd-udev-trigger.service
  60ms e2scrub_reap.service
  54ms keyboard-setup.service
  50ms systemd-udevd.service
  43ms dev-hugepages.mount
  ...
```

2. **Check System Load:**

```sh
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ uptime
 18:44:13 up 5 min,  1 user,  load average: 0.00, 0.05, 0.03

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ w
 18:44:26 up 5 min,  1 user,  load average: 0.00, 0.05, 0.03
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
kamilya  pts/1    -                18:38    5:52   0.02s  0.01s -bash
```

- Total boot time is **2.565 seconds**
- Snap services dominate boot time, with `snapd.seeded.service` taking **1.932s** and `snapd.service` taking **1.799s`
- Only one user session is active, logged in at 18:38


### 1.2 Process Forensics

1. **Identify Resource-Intensive Processes:**

```sh
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
    348     270 /snap/ubuntu-desktop-instal  0.8  0.8
    201       1 /usr/lib/snapd/snapd         0.4  0.1
    523     348 python3 /snap/ubuntu-deskto  0.4  1.0
    280       1 /usr/bin/python3 /usr/share  0.2  0.0
    192       1 /usr/bin/python3 /usr/bin/n  0.2  0.0

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
      1       0 /sbin/init                   0.1  1.2
    523     348 python3 /snap/ubuntu-deskto  0.4  1.0
    348     270 /snap/ubuntu-desktop-instal  0.8  0.8
    100       1 snapfuse /var/lib/snapd/sna  0.1  0.7
    108       1 snapfuse /var/lib/snapd/sna  0.1  0.2
```

- **Top memory-consuming process:** PID 348 (ubuntu-desktop-installer) with **0.8%** memory usage
- **Top CPU-consuming process:** PID 1 (init/systemd) with **1.2%** CPU usage
- Snap-related processes appear frequently

**Resource Utilization Patterns:**

Snap packages are the primary resource consumers (both memory and CPU). Process hierarchy shows snap processes are often parented by other snap processes. System processes (PID 1) maintain consistent but low CPU usage


### 1.3 Service Dependencies

1. **Map Service Relationships:**

```sh
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ systemctl list-dependencies
default.target
● ├─apport.service
○ ├─display-manager.service
○ ├─systemd-update-utmp-runlevel.service
○ ├─wslg.service
● └─multi-user.target
●   ├─apport.service
●   ├─console-setup.service
●   ├─cron.service
●   ├─dbus.service
○   ├─dmesg.service
○   ├─e2scrub_reap.service
○   ├─irqbalance.service
●   ├─networkd-dispatcher.service
●   ├─plymouth-quit-wait.service
●   ├─plymouth-quit.service
●   ├─rsyslog.service
●   ├─snap-bare-5.mount
●   ├─snap-core22-2139.mount
●   ├─snap-core22-2163.mount
●   ├─snap-gtk\x2dcommon\x2dthemes-1535.mount
●   ├─snap-snapd-25202.moun
...

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ systemctl list-dependencies multi-user.target
multi-user.target
● ├─apport.service
● ├─console-setup.service
● ├─cron.service
● ├─dbus.service
○ ├─dmesg.service
○ ├─e2scrub_reap.service
○ ├─irqbalance.service
● ├─networkd-dispatcher.service
● ├─plymouth-quit-wait.service
● ├─plymouth-quit.service
● ├─rsyslog.service
● ├─snap-bare-5.mount
● ├─snap-core22-2139.mount
● ├─snap-core22-2163.mount
● ├─snap-gtk\x2dcommon\x2dthemes-1535.mount
● ├─snap-snapd-25202.mount
● ├─snap-snapd-25577.mount
● ├─snap-ubuntu\x2ddesktop\x2dinstaller-1276.mount
● ├─snap-ubuntu\x2ddesktop\x2dinstaller-1286.mount
● ├─snap.ubuntu-desktop-installer.subiquity-server.service
○ ├─snapd.aa-prompt-listener.service
...
```

- The system uses a hierarchical service structure with `default.target` at the top
- Snap services are deeply integrated into the boot process


### 1.4 User Sessions

1. **Audit Login Activity:**

```sh
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ who -a
           system boot  2026-03-06 18:38
           run-level 5  2026-03-06 18:38
LOGIN      tty1         2026-03-06 18:38               290 id=tty1
LOGIN      console      2026-03-06 18:38               288 id=cons
kamilya  - pts/1        2026-03-06 18:38 00:11         461

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ last -n 5
kamilya  pts/1                         Fri Mar  6 18:38   still logged in
reboot   system boot  6.6.87.2-microso Fri Mar  6 18:38   still running
kamilya  pts/1                         Wed Nov 26 06:14 - crash (100+12:24)
reboot   system boot  6.6.87.2-microso Wed Nov 26 06:13   still running
kamilya  pts/1                         Sun Nov 23 22:31 - crash (2+07:42)

wtmp begins Tue Sep 10 11:23:23 2024
```

- Current session started at 18:38 on March 6, 2026
- Only one active user session currently (kamilya on pts/1)
- System boot history shows multiple reboots


### 1.5 Memory Analysis

**Inspect Memory Allocation:**

```sh
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.6Gi       514Mi       6.9Gi       3.0Mi       224Mi       7.0Gi       
Swap:          2.0Gi          0B       2.0Gi

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:        7990440 kB
MemAvailable:    7306628 kB
SwapTotal:       2097152 kB
```
- **Total memory:** 7.6 GB
- **Currently used:** 514 MB
- **Available memory:** 7.0 GB
- **Swap usage:** 0 bytes - system hasn't needed to use swap yet
- Memory utilization is very low

**What is the top memory-consuming process?**  
The top memory-consuming process is PID 348 (ubuntu-desktop-installer) using 61 MB (0.8%) of total memory.

---





## Task 2 — Networking Analysis

- [x] All command outputs for sections 2.1-2.3.
- [x] Insights on network paths discovered.
- [x] Analysis of DNS query/response patterns.
- [x] Comparison of reverse lookup results.
- [x] One example DNS query from packet capture (sanitize IPs if needed).


### 2.1 Network Path Tracing

1. **Traceroute Execution:**

```sh
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ traceroute github.com
Command 'traceroute' not found, but can be installed with:
sudo apt install inetutils-traceroute  # version 2:2.2-2ubuntu0.1, or
sudo apt install traceroute            # version 1:2.1.0-2
```

2. **DNS Resolution Check:**

```
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ dig github.com

; <<>> DiG 9.18.39-0ubuntu0.22.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 54374
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             52      IN      A       140.82.121.3

;; Query time: 39 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Fri Mar 06 19:08:38 MSK 2026
;; MSG SIZE  rcvd: 55

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
[sudo] password for kamilya: 
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes 

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

- Traceroute utility is not installed
- GitHub resolves to IP **140.82.121.3**
- DNS server is at **10.255.255.254**
- Query took 39ms with a TTL of 52 seconds
- DNS uses UDP on port 53 as expected

### 2.2 Packet Capture

1. **Capture DNS Traffic:**

```sh
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes 

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

No DNS traffic was captured during the 10-second window

**Example DNS Query (sanitized):**  
No packets were captured, but based on the dig output above, a typical DNS query would show:
- Source port: Random high port (>1024)
- Destination port: 53 (DNS)
- Protocol: UDP
- Query: github.com A record
- Response: 140.82.121.3

### 2.3 Reverse DNS

**Perform PTR Lookups:**

```
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ dig -x 8.8.4.4

; <<>> DiG 9.18.39-0ubuntu0.22.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 25394
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   6370    IN      PTR     dns.google.

;; Query time: 31 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Fri Mar 06 19:12:13 MSK 2026
;; MSG SIZE  rcvd: 73

kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ dig -x 1.1.2.2

; <<>> DiG 9.18.39-0ubuntu0.22.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 3610
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         2304    IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23601 7200 1800 604800 3600

;; Query time: 135 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Fri Mar 06 19:12:19 MSK 2026
;; MSG SIZE  rcvd: 137
```

- **8.8.4.4** resolves to **dns.google**
- **1.1.2.2** returns **NXDOMAIN**
- Both queries used the same DNS server (10.255.255.254)

**Comparison of Reverse Lookup Results:**
| IP Address | Result | Query Time | Status |
|------------|--------|------------|--------|
| 8.8.4.4 | dns.google | 31ms | Success |
| 1.1.2.2 | No record | 135ms | NXDOMAIN |

Well-known public IPs (like Google DNS) typically have proper reverse DNS configured. Many IP addresses, especially in certain ranges, lack PTR records. The difference in query times shows that NXDOMAIN responses take longer (DNS has to check authoritative servers). The authority section for 1.1.2.2 points to APNIC (Asia-Pacific Network Information Centre), indicating this IP is from the APNIC region

The system shows healthy resource utilization with plenty of available memory and minimal load. Network diagnostics revealed expected behavior with proper DNS resolution for known services and appropriate NXDOMAIN responses for unconfigured reverse lookups.
