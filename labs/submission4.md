# Lab 3 — Operating Systems & Networking

## Task 1 — Operating System Analysis

### 1.1: Boot Performance Analysis

1. Analyze System Boot Time

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ systemd-analyze
Startup finished in 6.432s (firmware) + 4.510s (loader) + 4.449s (kernel) + 10.869s (userspace) = 26.262s 
graphical.target reached after 10.682s in userspace.
```

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ systemd-analyze blame
5.799s NetworkManager-wait-online.service
4.789s plymouth-quit-wait.service
2.856s systemd-suspend.service
<...>
   3ms nvidia-persistenced.service
   3ms modprobe@dm_mod.service
   1ms setvtrgb.service
 537us snapd.socket
```

2. Check System Load

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ uptime
 20:18:15 up  5:38,  1 user,  load average: 0.65, 0.99, 0.78
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ w
 20:18:24 up  5:38,  1 user,  load average: 0.55, 0.96, 0.77
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
thallars tty2     -                14:40    5:38m 10:52   0.04s /usr/libexec/gnome-session-binary --session=
```

- Total boot time is 26.262 seconds, with userspace taking the longest (10.869s).

- The biggest boot bottleneck is NetworkManager-wait-online.service (5.799s), which is waiting for network connectivity before proceeding.

### 1.2: Process Forensics

1. Identify Resource-Intensive Processes

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
   9514    3306 /snap/telegram-desktop/6899  5.9  2.5
   4189    3306 /snap/firefox/7869/usr/lib/  4.7  3.6
   4598    4351 /snap/firefox/7869/usr/lib/  3.2  1.4
  10700   10615 /snap/code/225/usr/share/co  2.7  0.8
  10306    4351 /snap/firefox/7869/usr/lib/  2.6  0.2
```

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
   4189    3306 /snap/firefox/7869/usr/lib/  4.7  3.6
   3020    3018 /usr/lib/xorg/Xorg vt2 -dis  1.2  3.2
   9514    3306 /snap/telegram-desktop/6899  5.9  2.5
   3306    2867 /usr/bin/gnome-shell         2.2  1.9
   4598    4351 /snap/firefox/7869/usr/lib/  3.2  1.4
```

- Top memory-consuming process: telegram-desktop (PID 9514) using 5.9% of memory.

- Top CPU-consuming process: firefox (PID 4189) using 3.6% of CPU.

- Firefox spawns multiple child processes (PIDs 4189, 4598, 10306), collectively consuming significant resources.

### 1.3: Service Dependencies

1. Map Service Relationships

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ systemctl list-dependencies
default.target
● ├─accounts-daemon.service
● ├─gdm.service
● ├─gnome-remote-desktop.service
● ├─power-profiles-daemon.service
● ├─switcheroo-control.service
○ ├─systemd-update-utmp-runlevel.service
● ├─udisks2.service
● └─multi-user.target
●   ├─AmneziaVPN.service
○   ├─anacron.service
●   ├─apport.service
...
```

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ systemctl list-dependencies multi-user.target
multi-user.target
● ├─AmneziaVPN.service
○ ├─anacron.service
● ├─apport.service
● ├─avahi-daemon.service
● ├─console-setup.service
● ├─containerd.service
```

- `default.target` depends on both graphical (`gdm.service`) and multi-user services.

- `multi-user.target` shows third-party services like `AmneziaVPN` and `containerd` are configured to start at boot.

### 1.4: User Sessions

1. Audit Login Activity

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ who -a
           system boot  2026-02-27 14:40
           run-level 5  2026-02-27 14:40
thallars ? seat0        2026-02-27 14:40   ?          3018 (login screen)
thallars ? :1           2026-02-27 14:40   ?          3018 (:1)
```

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ last -n 5
thallars :1           :1               Fri Feb 27 14:40   still logged in
thallars seat0        login screen     Fri Feb 27 14:40   still logged in
reboot   system boot  6.17.0-14-generi Fri Feb 27 14:40   still running
thallars :1           :1               Tue Feb 24 19:59 - down   (00:37)
thallars seat0        login screen     Tue Feb 24 19:59 - down   (00:37)

wtmp begins Tue Mar 18 18:03:03 2025        2026-02-27 14:40   ?          3018 (:1)
```

- System boot occurred on February 27, 2026 at 14:40.

- Current session has been running for 5 hours 38 minutes with one active user (`thallars`).

### 1.5: Memory Analysis

1. Inspect Memory Allocation

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       6.0Gi       4.2Gi       926Mi       5.3Gi       9.2Gi
Swap:          4.0Gi          0B       4.0Gi
```

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:       15985668 kB
MemAvailable:    9680584 kB
SwapTotal:       4194300 kB
```

- Total RAM: 15 GiB with 6.0 GiB used (40% utilization).

- 9.2 GiB available memory, indicating no memory pressure.

- Swap is completely unused (0B used), suggesting adequate physical memory.

### What is the top memory-consuming process?
Telegram-desktop (PID 9514) using 5.9% of memory

### Resource utilization patterns

- Firefox processes appear multiple times in top CPU/memory lists, typical for modern workloads.

- Several top processes (Telegram, Firefox, Code) are Snap packages, showing their prevalence in the system.

- Current load (0.65) is well below CPU capacity, indicating an idle or lightly loaded system.

- High available memory and zero swap usage suggest the system isn't memory-constrained.

## Task 2 — Networking Analysis

### 2.1: Network Path Tracing

1. Traceroute Execution

```bash 
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ traceroute github.com
traceroute to github.com (140.82.121.4), 30 hops max, 60 byte packets
 1  10.100.20.2 (10.100.20.2)  2.447 ms  2.242 ms  2.154 ms
 2  10.252.6.1 (10.252.6.1)  2.132 ms  2.112 ms  2.089 ms
 3  1.123.18.84.in-addr.arpa (84.18.123.1)  16.912 ms  16.895 ms  13.258 ms
 4  178.176.191.24 (178.176.191.24)  8.855 ms  8.837 ms  8.818 ms
 5  * * *
```

2. DNS Resolution Check

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ dig github.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51276
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             23      IN      A       140.82.121.4

;; Query time: 6 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Feb 27 23:06:45 MSK 2026
;; MSG SIZE  rcvd: 55
```

### 2.2: Packet Capture

1. Capture DNS Traffic

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
23:07:19.336217 lo    In  IP 127.0.0.1.33484 > 127.0.0.53.53: 39834+ [1au] A? copilot-telemetry.githubusercontent.com. (68)
23:07:19.336231 lo    In  IP 127.0.0.1.33484 > 127.0.0.53.53: 58270+ [1au] AAAA? copilot-telemetry.githubusercontent.com. (68)
23:07:19.336494 wlo1  Out IP 10.100.20.29.58687 > 10.90.137.30.53: 6757+ [1au] A? glb-db52c2cf8be544.github.com. (58)
23:07:19.336628 wlo1  Out IP 10.100.20.29.42020 > 10.90.137.30.53: 57429+ [1au] AAAA? glb-db52c2cf8be544.github.com. (58)
23:07:19.340178 wlo1  In  IP 10.90.137.30.53 > 10.100.20.29.58687: 6757 1/0/1 A 140.82.113.21 (74)
5 packets captured
12 packets received by filter
0 packets dropped by kernel
```

### 2.3: Reverse DNS

1. Perform PTR Lookups

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ dig -x 8.8.4.4

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 26238
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   3964    IN      PTR     dns.google.

;; Query time: 27 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Feb 27 23:07:40 MSK 2026
;; MSG SIZE  rcvd: 73
```

```bash
thallars@ASUS-TUF:~/Documents/DevOps-Intro$ dig -x 1.1.2.2

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 14801
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         900     IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 353 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Feb 27 23:08:01 MSK 2026
;; MSG SIZE  rcvd: 137
```

### Key Observations

#### Network Path Insights:
- Traffic to GitHub passes through **internal corporate network** first (10.100.20.2 → 10.252.6.1)
- After 3 hops, traffic exits to **public internet** (84.18.123.1)
- **Packet loss** occurs at hop 5 (`* * *`), which is common—many routers don't respond to traceroute
- GitHub resolves to **140.82.121.4**, consistent with their global anycast infrastructure

#### DNS Query Patterns:
- All DNS queries go through **local resolver** (127.0.0.53) first
- Upstream DNS server is **10.90.137.30** (internal corporate DNS)
- Query time is excellent: **6ms** for github.com resolution
- Both **A (IPv4)** and **AAAA (IPv6)** queries are attempted simultaneously

#### Reverse DNS Comparison:
| IP | Result | Status |
|-----|--------|--------|
| 8.8.4.4 | **dns.google** | Success (PTR exists) |
| 1.1.2.2 | **NXDOMAIN** | Failed (no PTR record) |

#### Example DNS Query (from packet capture):
```
10.100.20.29.58687 > 10.90.137.30.53: A? glb-db52c2cf8be544.github.com.
```
*(Internal IP 10.100.20.29 queries corporate DNS 10.90.137.30 for GitHub subdomain)*
