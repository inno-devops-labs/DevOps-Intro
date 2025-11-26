# Lab 4 Submission - Operating Systems & Networking

## Task 1 — Operating System Analysis

### 1.1: Boot Performance Analysis

#### System Boot Time Analysis

**Note:** Running on macOS (Darwin), systemd commands not available. Using macOS equivalents.

**Command:** `system_profiler SPSoftwareDataType | grep "Boot Volume\|System Version\|Time since boot"`

```
System Version: macOS 15.6.1 (24G90)
Boot Volume: Macintosh HD
Time since boot: 16 days, 7 hours
```

**Analysis:** System has been running for 16 days without restart, indicating stable operation.

#### System Load Check

**Command:** `uptime`

```
0:59  up 16 days, 7 hrs, 1 user, load averages: 5.31 4.67 4.10
```

**Command:** `w`

```
0:59  up 16 days, 7 hrs, 1 user, load averages: 5.21 4.66 4.10
USER       TTY      FROM    LOGIN@  IDLE WHAT
theother_a console  -      21Sep25 16days -
```

**Analysis:** High load averages (5.31, 4.67, 4.10) indicate system under heavy load. Single user logged in via console since September 21st.

### 1.2: Process Forensics

#### Memory-Intensive Processes

**Command:** `ps -eo pid,ppid,comm,%mem,%cpu | sort -k4 -nr | head -n 6`

```
45156     1 /Applications/Te  5.2  14.6
45462 45451 /Applications/Cu  4.2  37.9
  803     1 /Applications/Go  2.2   0.3
51819   803 /Applications/Go  1.8   0.0
51764   803 /Applications/Go  1.5   1.5
45099   803 /Applications/Go  1.5   0.1
```

#### CPU-Intensive Processes

**Command:** `ps -eo pid,ppid,comm,%mem,%cpu | sort -k5 -nr | head -n 6`

```
45462 45451 /Applications/Cu  4.2 191.9
30819     1 /System/Library/  0.3  65.2
  168     1 /System/Library/  1.4  46.1
45459 45451 /Applications/Cu  0.6  38.9
45156     1 /Applications/Te  5.2  17.7
  805     1 /System/Library/  0.5   7.3
```

**Analysis:**

- Top memory consumer: Process 45156 (Application) using 5.2% memory
- Top CPU consumer: Process 45462 (Application) using 191.9% CPU (multi-core usage)
- Several system processes and applications are actively running

### 1.3: Service Dependencies

#### System Dependencies

**Note:** macOS uses launchd instead of systemd. Using launchctl to list services.

**Command:** `launchctl list | head -10`

```
PID	Status	Label
-	0	com.apple.SafariHistoryServiceAgent
-	-9	com.apple.progressd
-	-9	com.apple.cloudphotod
65769	-9	com.apple.MENotificationService
869	0	com.apple.Finder
83519	-9	com.apple.homed
73669	-9	com.apple.dataaccess.dataaccessd
-	0	com.apple.quicklook
-	0	com.apple.parentalcontrols.check
```

#### Apple System Services

**Command:** `launchctl list | grep -E "com.apple" | head -8`

```
-	0	com.apple.SafariHistoryServiceAgent
-	-9	com.apple.progressd
-	-9	com.apple.cloudphotod
65769	-9	com.apple.MENotificationService
869	0	com.apple.Finder
83519	-9	com.apple.homed
73669	-9	com.apple.dataaccess.dataaccessd
-	0	com.apple.quicklook
```

**Analysis:**

- Status -9 indicates services that have exited
- Status 0 indicates successfully running services
- PID shows process ID for running services
- Various Apple system services are managed by launchd

### 1.4: User Sessions

#### Current Login Activity

**Command:** `who -a`

```
                 system boot  Sep 21 17:59 
theother_archee  console      Sep 21 18:00 
theother_archee  ttys015      Sep 23 23:08 	term=0 exit=0
   .       run-level 3
```

#### Recent Login History

**Command:** `last -n 5`

```
theother_archee ttys015                         Tue Sep 23 23:08 - 23:08  (00:00)
theother_archee console                         Sun Sep 21 18:00   still logged in
reboot time                                Sun Sep 21 17:59
theother_archee console                         Wed Sep 17 00:27 - 17:59 (4+17:32)
reboot time                                Wed Sep 17 00:25
```

**Analysis:**

- User theother_archee logged in via console since Sep 21 18:00 (still active)
- Brief terminal session on Sep 23 23:08 (lasted 0 minutes)
- System rebooted on Sep 21 17:59
- Previous session lasted over 4 days before reboot

### 1.5: Memory Analysis

#### Memory Allocation Overview

**Note:** macOS doesn't have `free` command. Using `vm_stat` and `system_profiler` instead.

**Command:** `system_profiler SPHardwareDataType | grep "Memory:"`

```
Memory: 16 GB
```

#### Detailed Memory Information

**Command:** `vm_stat`

```
Mach Virtual Memory Statistics: (page size of 16384 bytes)
Pages free:                                8401.
Pages active:                            279841.
Pages inactive:                          276594.
Pages speculative:                         3164.
Pages throttled:                              0.
Pages wired down:                        173043.
Pages purgeable:                           3279.
"Translation faults":                3655954495.
Pages copy-on-write:                  112203228.
Pages zero filled:                   1502194173.
Pages reactivated:                    666925788.
Pages purged:                          79590776.
File-backed pages:                       163066.
Anonymous pages:                         396533.
Pages stored in compressor:              982146.
Pages occupied by compressor:            266330.
Decompressions:                      1866502411.
Compressions:                        2056482764.
Pageins:                              122005821.
Pageouts:                               1775048.
Swapins:                              142043743.
Swapouts:                             154221794.
```

**Memory Analysis:**

- Total Memory: 16 GB
- Page size: 16,384 bytes (16 KB)
- Free pages: 8,401 (≈ 137.6 MB free)
- Active pages: 279,841 (≈ 4.6 GB active)
- Inactive pages: 276,594 (≈ 4.5 GB inactive)
- Wired pages: 173,043 (≈ 2.8 GB wired/kernel)
- Memory pressure indicated by high compression/decompression activity

## Task 2 — Networking Analysis

### 2.1: Network Path Tracing

#### Traceroute to GitHub

**Command:** `traceroute github.com`

```
traceroute to github.com (140.82.121.3), 64 hops max, 40 byte packets
 1  * * *
 2  * * *
 3  * * *
 4  * * *
 5  * * *
 6  * * *
 7  * * *
 8  * * *
 9  * * *
10  * * *
11  * * *
12  * * *
13  * * *
14  * * *
15  * * *
16  * * *
17  * * *
18  * * *
[Truncated - all hops showed timeouts]
```

#### DNS Resolution Check

**Command:** `dig github.com`

```
; <<>> DiG 9.10.6 <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51290
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;github.com.			IN	A

;; ANSWER SECTION:
github.com.		47	IN	A	140.82.121.3

;; Query time: 134 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; WHEN: Wed Oct 08 01:08:07 MSK 2025
;; MSG SIZE  rcvd: 55
```

**Analysis:**

- Traceroute shows timeouts (*) at all hops - likely due to ICMP filtering by routers
- DNS resolution successful: github.com resolves to 140.82.121.3
- Using Cloudflare DNS server (1.1.1.1)
- Query time: 134ms (reasonable response time)
- TTL: 47 seconds for the A record

### 2.2: Packet Capture

#### DNS Traffic Capture

**Note:** tcpdump requires sudo privileges which are not available in this environment.

**Alternative approach - DNS query generation:**
**Command:** `dig google.com +short`

```
forcesafesearch.google.com.
216.239.38.XXX
```

**Analysis:** Generated DNS traffic by performing lookup. In a real tcpdump capture, we would see:

- UDP packets on port 53
- Query packets (client → DNS server)
- Response packets (DNS server → client)
- Packet structure with DNS headers and payload

### 2.3: Reverse DNS

#### PTR Lookup for 8.8.4.4

**Command:** `dig -x 8.8.4.4`

```
; <<>> DiG 9.10.6 <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 61687
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.		IN	PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.	5917	IN	PTR	dns.google.

;; Query time: 37 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; WHEN: Wed Oct 08 01:08:56 MSK 2025
;; MSG SIZE  rcvd: 73
```

#### PTR Lookup for 1.1.2.2

**Command:** `dig -x 1.1.2.2`

```
; <<>> DiG 9.10.6 <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 46941
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.		IN	PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.		1748	IN	SOA	ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 22966 7200 1800 604800 3600

;; Query time: 424 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; WHEN: Wed Oct 08 01:09:03 MSK 2025
;; MSG SIZE  rcvd: 137
```

**Reverse DNS Analysis:**

- 8.8.4.4 successfully resolves to dns.google. (Google's public DNS)
- 1.1.2.2 returns NXDOMAIN (no PTR record exists)
- Query times: 37ms vs 424ms (successful vs failed lookup)
- Different response sizes: 73 bytes vs 137 bytes

## Analysis and Observations

### Key Findings

- **Top Memory-Consuming Process:** Process 45156 (Application) using 5.2% memory
- **Boot Performance:** System uptime 16 days, 7 hours - excellent stability
- **Network Path Insights:** Traceroute blocked by firewalls, but DNS resolution working properly
- **DNS Patterns:** Using Cloudflare DNS (1.1.1.1), query times 37-424ms depending on record availability

### Resource Utilization Patterns

**System Load:

* CPU is basically on fire (averages: 5.31, 4.67, 4.10).
* Memory’s struggling — lots of compress/decompress going on.
* A bunch of apps are hogging resources like it’s their full-time job.

**Network Behavior:**

* DNS works fine, even with security rules in place.
* Reverse DNS is a bit hit-or-miss (some IPs answer, some don’t bother).
* Can’t run traceroute because security rejects (I guess it is because of VPN usage).

**Security Observations:**

- ICMP filtering prevents traceroute visibility
- System services properly managed by launchd
- Long-running stable system (16+ days uptime)

### Security Considerations

All sensitive information has been sanitized according to security best practices:

- IP addresses have last octet replaced with XXX where appropriate
- Sensitive process names have been generalized
- Internal network topology details have been omitted
