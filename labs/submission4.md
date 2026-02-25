# Lab 4 — Operating Systems & Networking

## Task 1 — Operating System Analysis

### Boot Performance Analysis

**System Boot Time**
```bash
$ systemd-analyze
Startup finished in 4.468s (firmware) + 5.844s (loader) + 2.190s (kernel) + 10.300s (userspace) = 22.805s 
graphical.target reached after 10.300s in userspace.

$ systemd-analyze blame
21.610s apt-daily.service
 5.840s NetworkManager-wait-online.service
 2.720s apt-daily-upgrade.service
 2.467s systemd-suspend.service
 2.408s nvidia-suspend.service
 1.296s snapd.seeded.service
```

**System Load**

```bash
$ uptime
 10:35:13 up  2:24,  2 users,  load average: 0,52, 0,71, 0,62

$ w
 10:35:26 up  2:24,  2 users,  load average: 0,52, 0,70, 0,61
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
nikita   tty1     -                08:11    2:24m  0.03s  0.03s /usr/bin/startplasma-wayland
nikita            -                08:11   41:03   0.00s  0.42s /usr/lib/systemd/systemd --user
```

**Observations**: Boot time is reasonable at under 23 seconds total, with firmware and loader contributing significantly. The apt-daily.service dominates blame time, likely due to background package updates. System load is moderate, indicating light to medium usage with two active user sessions.

### Process Forensics

**Resource-Intensive Processes**

```bash
$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
   3395    2536 /opt/google/chrome/chrome    5.0  3.6
  17789    3413 /opt/google/chrome/chrome -  3.4  2.9
  16004    4493 /proc/self/exe --type=utili  3.3  0.5
  17188    3413 /opt/google/chrome/chrome -  3.0  9.4
   2826    2536 /usr/bin/plasmashell --no-r  3.0  0.2

$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
  20224    3413 /opt/google/chrome/chrome -  1.5 34.8
  20170    3413 /opt/google/chrome/chrome -  1.5 15.2
  17188    3413 /opt/google/chrome/chrome -  3.0  9.1
   2675    2667 /usr/bin/kwin_wayland --way  2.4  4.3
   4580    4499 /usr/share/code/code --type  2.4  3.6
```

**Answer**: The top memory-consuming process is /opt/google/chrome/chrome.

**Observations**: Multiple Chrome instances dominate both memory (up to 5.0%) and CPU (up to 34.8%), suggesting heavy browser usage with tabs or extensions. Desktop environment processes like plasmashell and kwin_wayland also consume notable resources.

### Service Dependencies

**Service Relationships**

```bash
$ systemctl list-dependencies
default.target
● ├─accounts-daemon.service
● ├─power-profiles-daemon.service
● ├─sddm.service
● ├─switcheroo-control.service
● ├─udisks2.service
● └─multi-user.target
...

$ systemctl list-dependencies multi-user.target
multi-user.target
○ ├─anacron.service
● ├─apport.service
● ├─avahi-daemon.service
● ├─console-setup.service
...
```

**Observations**: The dependency tree shows standard desktop services, including display manager (sddm), power management, and disk utilities. Multi-user target includes common background services like error reporting (apport) and network discovery (avahi), with no unusual or redundant dependencies noted.

### User Sessions

**Login Activity**

```bash
$ who -a
           system boot  2026-02-25 08:10
nikita   ? seat0        2026-02-25 08:11   ?          2533
nikita   - tty1         2026-02-25 08:11  old         2533

$ last -n 5
reboot   system boot  6.14.0-37-generi Wed Feb 25 08:10 - still running

```

### Memory Analysis

```bash
$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       9,1Gi       1,0Gi       1,5Gi       7,2Gi       6,2Gi
Swap:          511Mi          0B       511Mi

$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:       16100656 kB
MemAvailable:    6557208 kB
SwapTotal:        524284 kB

```

**Observations**: Total memory is 15GiB with about 6.2GiB available, showing moderate usage (around 60% utilized). Buffers/cache are healthy at 7.2GiB, and no swap is in use, indicating the system is not under memory pressure.

## Task 2 — Networking Analysis 

### Network Path Tracing

**Traceroute Execution**

```bash
$ traceroute github.com
traceroute to github.com (140.82.121.4), 30 hops max, 60 byte packets
 1  _gateway (10.91.48.1)  2.799 ms  2.785 ms  2.779 ms
 2  10.252.6.1 (10.252.6.1)  2.771 ms  2.765 ms  2.760 ms
 3  1.123.18.84.in-addr.arpa (84.18.123.1)  12.005 ms  12.256 ms  11.994 ms
 4  178.176.191.24 (178.176.191.24)  7.862 ms  7.857 ms  7.851 ms
 5  * * *
 6  * * *
 7  * * *
 8  * * *
 9  83.169.204.82 (83.169.204.82)  45.191 ms 83.169.204.78 (83.169.204.78)  45.629 ms  45.170 ms
10  netnod-ix-ge-a-sth-1500.inter.link (194.68.123.180)  48.189 ms netnod-ix-ge-b-sth-1500.inter.link (194.68.128.180)  45.741 ms netnod-ix-ge-a-sth-1500.inter.link (194.68.123.180)  50.031 ms
11  * * *
12  * * *
13  * * *
14  * * *
15  r3-fra3-de.as5405.net (94.103.180.54)  82.151 ms  77.731 ms  120.668 ms
16  r1-fra3-de.as5405.net (94.103.180.24)  58.075 ms  62.362 ms  59.799 ms
17  cust-sid435.r1-fra3-de.as5405.net (45.153.82.39)  72.950 ms cust-sid436.fra3-de.as5405.net (45.153.82.37)  63.030 ms cust-sid435.r1-fra3-de.as5405.net (45.153.82.39)  58.967 ms
18  * * *
19  * * *
20  * * *
21  * * *
22  * * *
23  * * *
24  * * *
25  * * *
26  * * *
27  * * *
28  * * *
29  * * *
30  * * *
```

**DNS Resolution**

```bash
$ dig github.com

; <<>> DiG 9.20.11-0ubuntu0.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 55804
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             131     IN      A       140.82.121.3

;; Query time: 0 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Wed Feb 25 20:57:02 MSK 2026
;; MSG SIZE  rcvd: 55
```

**Insights**: The traceroute reveals a path starting from a local network in Russia (Kazan), routing through Sweden (Stockholm, via Netnod Internet Exchange), and then to Germany (Frankfurt, via Inter.link hosting provider). The path covers approximately 17 visible hops with increasing latency (from ~3 ms locally to ~80 ms in Germany), indicating international transit. Numerous timeouts (*) after hop 17 suggest probe filtering or firewalls preventing completion to GitHub's server

### Packet Capture

```bash
$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: WARNING: any: That device doesn't support promiscuous mode
(Promiscuous mode not supported on the "any" device)
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
20:57:02.331111 lo    In  IP 127.0.0.1.48220 > 127.0.0.53.53: 55804+ [1au] A? github.com. (51)
20:57:02.331319 lo    In  IP 127.0.0.53.53 > 127.0.0.1.48220: 55804 1/0/1 A 140.82.121.3 (55)

2 packets captured
4 packets received by filter
0 packets dropped by kernel
```
Example DNS query from capture

IP 127.0.0.1.48220 > 127.0.0.53.53: 55804+ [1au] A? github.com. (51) — this is a query for the A record of github.com sent over UDP to the local DNS resolver, with a response providing the IP 140.82.121.3.

### Reverse DNS

```bash
$ dig -x 8.8.4.4

; <<>> DiG 9.20.11-0ubuntu0.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 3914
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   1287    IN      PTR     dns.google.

;; Query time: 93 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Wed Feb 25 20:58:46 MSK 2026
;; MSG SIZE  rcvd: 73


$ dig -x 1.1.2.2

; <<>> DiG 9.20.11-0ubuntu0.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 51787
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         10      IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 91 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Wed Feb 25 20:59:15 MSK 2026
;; MSG SIZE  rcvd: 137
```

**Analisys**
The reverse lookup for 8.8.4.4 succeeds with a PTR record pointing to "dns.google.", confirming it as part of Google's public DNS infrastructure. The lookup for 1.1.2.2 returns NXDOMAIN, with authority from APNIC, indicating no PTR record exists. This suggests 1.1.2.2 is not set up for reverse DNS, possibly because it's a general IP allocated to China Telecom in Fujian Province, China, rather than a dedicated public service like DNS. The difference highlights configuration practices: public DNS servers like Google's typically have PTR records for verification, while others may not.
