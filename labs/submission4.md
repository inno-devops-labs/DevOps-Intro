# Lab 4 — Submission

## Task 1 — Operating System Analysis

### 1.1: Boot Performance Analysis

**`systemd-analyze` / `uptime`:**
```
23:06  up 5 days, 2:23, 1 user, load averages: 3.27 3.98 3.65
```

**`systemd-analyze blame` / `last reboot | head -5`:**
```
reboot    Sun Feb 22 20:43
shutdown  Sun Feb 22 20:43
reboot    Thu Feb  5 17:30
reboot    Thu Jan 29 12:14
reboot    Fri Jan 23 00:51
```

**`w`:**
```
USER       TTY      FROM    LOGIN@  IDLE WHAT
ddsharafie console  -       Sun20   5days -
```

**Observations:**
- System has been running for 5 days since last reboot on Feb 22.
- Load averages (3.27 / 3.98 / 3.65) indicate sustained CPU activity across all cores.
- Only one active user session on the console.

---

### 1.2: Process Forensics

**`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6`:**
```
  PID  PPID CMD              %MEM  %CPU
  390     1 WindowServer      0.8  28.8
93435     1 mds_stores        5.5  15.2
  662     1 containerd        0.8  13.0
21737   662 containerd-shim   1.6  11.5
68729     1 Terminal          6.2   6.5
```

**`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6`:**
```
  PID  PPID CMD              %MEM  %CPU
68729     1 Terminal          6.2   5.8
93435     1 mds_stores        5.5  13.1
21822   662 containerd-shim   4.4   2.5
14205   674 Google Chrome     3.2   0.0
25476     1 Microsoft Office  2.8   0.9
```

**Observations:**
- Top memory-consuming process: **Terminal** at 6.2% of 32 GB (~2 GB).
- `WindowServer` (display compositor) leads CPU usage at 28.8%.
- `mds_stores` (Spotlight indexing) is active in both CPU and memory.
- `containerd` is running, indicating Docker is in use.

**Answer — top memory-consuming process:** `Terminal` (PID 68729) at 6.2% of 32 GB RAM.

---

### 1.3: Service Dependencies

**`systemctl list-dependencies` / `launchctl list | head -20`:**
```
PID     Status  Label
709     0       com.apple.Finder
779     0       com.apple.MENotificationService
2402    0       com.apple.cloudphotod
706     0       com.apple.homed
1771    0       com.apple.dataaccess.dataaccessd
761     0       com.apple.mediaremoteagent
713     0       com.apple.FontWorker
626     0       com.apple.bird
24942   0       com.apple.GameController.gamecontrolleragentd
```

**Total services:** 484 registered jobs.

**Observations:**
- 484 services are registered covering system daemons and user agents.
- Core services like Finder, cloudphotod, homed are active (PID assigned).
- Status `0` = idle/exited cleanly; PID present = actively running.

---

### 1.4: User Sessions

**`who -a`:**
```
         system boot  Feb 22 20:43
ddsharafiev  console  Feb 22 20:44
ddsharafiev  ttys001  Feb 22 20:46  term=0 exit=0
```

**`last -n 5`:**
```
ddsharafiev  ttys001   Sun Feb 22 20:46 - 20:46  (00:00)
ddsharafiev  ttys001   Sun Feb 22 20:45 - 20:45  (00:00)
ddsharafiev  console   Sun Feb 22 20:44   still logged in
reboot       ~         Sun Feb 22 20:43
shutdown     ~         Sun Feb 22 20:43
```

**Observations:**
- Single user logged in since Feb 22 via the console.
- Two short terminal sessions (ttys001) opened and closed on boot day.
- Last shutdown and reboot occurred at the same time — clean restart.

---

### 1.5: Memory Analysis

**`free -h` / `vm_stat`:**
```
Mach Virtual Memory Statistics: (page size of 16384 bytes)
Pages free:                    5129
Pages active:                797965
Pages inactive:              799750
Pages wired down:            173830
Pages stored in compressor:  520785
Swapins:                          0
Swapouts:                         0
```

**`cat /proc/meminfo` / `sysctl hw.memsize`:**
```
MemTotal:    34359738368  (32 GB)
physicalcpu: 10
```

**Interpreted:**
```
Total RAM:    32.0 GB
Active:       12.2 GB
Inactive:     12.2 GB
Wired:         2.7 GB
Free:          0.08 GB
Swap used:     0 GB
```

**Observations:**
- Total RAM: 32 GB. Only ~80 MB truly free — OS uses inactive memory as cache.
- No swap activity, meaning memory pressure is within limits.
- 520k pages are compressed in memory, saving physical RAM.
- Top memory-consuming process: **Terminal** at ~2 GB.

---

## Task 2 — Networking Analysis

### 2.1: Network Path Tracing

**`traceroute github.com`:**
```
traceroute to github.com (140.82.121.3), 15 hops max, 40 byte packets
 1  * * *
 2  * * *
 3  * * *
...
15  * * *
```

**`dig github.com`:**
```
; <<>> DiG 9.10.6 <<>> github.com
;; ANSWER SECTION:
github.com.   14   IN   A   140.82.121.3

;; Query time: 218 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; WHEN: Fri Feb 27 23:18:32 MSK 2026
;; MSG SIZE  rcvd: 55
```

**Observations:**
- `github.com` resolves to `140.82.121.3` — a GitHub datacenter IP.
- DNS resolver: `1.1.1.1` (Cloudflare public DNS).
- All traceroute hops show `* * *` — routers along the path block ICMP TTL-exceeded responses, which is common network behavior. Connectivity itself works fine, as DNS resolution succeeded.

---

### 2.2: Packet Capture

**`sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn`:**
```
tcpdump: listening on lo0, link-type NULL (BSD loopback), snapshot length 524288 bytes

23:14:41.269873 IP 127.0.0.1.49602 > 127.0.0.1.53: 8230+ [1au] A? apple.com. (38)
23:14:46.274669 IP 127.0.0.1.49602 > 127.0.0.1.53: 8230+ [1au] A? apple.com. (38)
```

**DNS query example (sanitized):**
```
127.0.0.XXX.XXXXX > 127.0.0.XXX.53: A? apple.com.
```
- Source: local DNS client
- Destination: port 53 (DNS)
- Query type: `A` (IPv4 address lookup)
- Domain: `apple.com`

---

### 2.3: Reverse DNS Lookups

**`dig -x 8.8.4.4`:**
```
;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   69689   IN   PTR   dns.google.

;; Query time: 134 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; STATUS: NOERROR
```

**`dig -x 1.1.2.2`:**
```
;; STATUS: NXDOMAIN
;; AUTHORITY SECTION:
1.in-addr.arpa.   3600   IN   SOA   ns.apnic.net. ...

;; Query time: 249 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
```

**Comparison:**

| IP      | PTR Record  | Status   | Owner              |
|---------|-------------|----------|--------------------|
| 8.8.4.4 | dns.google. | NOERROR  | Google             |
| 1.1.2.2 | (none)      | NXDOMAIN | APNIC (unassigned) |

**Observations:**
- `8.8.4.4` resolves to `dns.google.` — a properly configured public DNS server with a valid PTR record.
- `1.1.2.2` returns `NXDOMAIN` — the IP exists within APNIC's address space but has no PTR record assigned.
- The `ad` flag on the `1.1.2.2` response confirms DNSSEC validation was performed.
- Both queries used `1.1.1.1` (Cloudflare) as the upstream resolver.
