# Lab 4 — Operating Systems & Networking  
**Course:** Intro to DevOps  
**Branch:** Feature/lab4  
**Student** Rodion Krainov

---

# Task 1 — Operating System Analysis

## 1.1 Boot Performance Analysis

### `systemd-analyze`

```bash
Startup finished in 8.052s (firmware) + 1.043s (loader) + 952ms (kernel) + 4.332s (initrd) + 13.594s (userspace) = 27.975s 
graphical.target reached after 13.594s in userspace.
````

📌 **Observation:**

* Total boot time: **~28 seconds**
* Userspace initialization: **13.594s**
* Firmware stage (8.052s) is the most time-consuming early phase.

---

### `systemd-analyze blame`

```bash
18.035s man-db.service
5.423s NetworkManager-wait-online.service
3.500s docker.service
...
```

📌 **Key Observations:**

* `man-db.service` is the slowest unit (18.035s).
* `NetworkManager-wait-online.service` adds ~5.4s delay.
* `docker.service` contributes ~3.5s.
* Many device units (~3.4s) correspond to disk initialization.

This indicates that documentation indexing and network readiness checks significantly impact boot duration.

---

### System Load — `uptime`

```bash
22:27:02 up 7:22, 1 user, load average: 1.30, 0.98, 0.56
```

### Active Users — `w`

```bash
USER     TTY   LOGIN@   IDLE   JCPU   PCPU WHAT
r3taker  tty2  15:05    7:22m  0.05s  0.03s /usr/lib/gnome-session-init-worker gnome
```

📌 **Analysis:**

* One active user session.
* Load average is moderate (1.30 current).
* System is not overloaded.

---

## 1.2 Process Forensics

### Top Memory Consumers

```bash
PID    CMD                             %MEM %CPU
23958  /tmp/.mount_Cursor...           5.7  15.6
5145   /usr/lib/firefox/firefox        5.5  10.9
8432   /usr/lib/firefox/firefox -c     3.9   2.2
24051  /proc/self/exe --type=...       3.3   1.8
5575   /usr/lib/firefox/firefox -c     3.1   1.2
```

### Top CPU Consumers

```bash
PID    CMD                             %MEM %CPU
75135  /usr/lib/localsearch-extrac     0.3  80.0
72166  /usr/lib/electron39/...         2.0  22.0
23958  /tmp/.mount_Cursor...           5.7  15.6
5145   /usr/lib/firefox/firefox        5.5  10.9
3698   /usr/bin/gnome-shell            1.9   6.8
```

📌 **Answer: What is the top memory-consuming process?**

**/tmp/.mount_Cursor...** (5.7% memory)

📌 **Observations:**

* Browser processes (Firefox) consume significant RAM.
* Electron-based applications contribute to CPU load.
* `localsearch-extractor` briefly spikes CPU to 80%.
* Desktop environment (`gnome-shell`) maintains consistent CPU usage.

---

## 1.3 Service Dependencies

### `systemctl list-dependencies`

Main target:

```bash
default.target
 ├─gdm.service
 └─multi-user.target
```

### `systemctl list-dependencies multi-user.target`

Key active services:

```bash
AmneziaVPN.service
avahi-daemon.service
docker.service
firewalld.service
NetworkManager.service
systemd-resolved.service
systemd-timesyncd.service
```

📌 **Observations:**

* Docker is enabled at multi-user level.
* VPN service is active at boot.
* Firewalld and NetworkManager are properly integrated.
* Systemd socket activation heavily used.

This reflects a development workstation with containerization and VPN enabled.

---

## 1.4 User Sessions

### `who -a`

```bash
system boot 2026-02-26 15:04
r3taker seat0 2026-02-26 15:05
r3taker tty2 2026-02-26 15:05
```

### `last -n 5`

```bash
reboot system boot 6.18.9-arch1-2 Thu Feb 26 15:04 still running
r3taker tty2 Thu Feb 26 15:05 still logged in
```

📌 **Analysis:**

* Single active login session.
* Recent reboot occurred on Feb 26.
* No suspicious login activity detected.

---

## 1.5 Memory Analysis

### `free -h`

```bash
Mem: 15Gi total
Used: 8.3Gi
Free: 433Mi
Available: 7.0Gi
Swap: 0B
```

### `/proc/meminfo`

```bash
MemTotal: 16067008 kB
MemAvailable: 7337344 kB
SwapTotal: 0 kB
```

📌 **Observations:**

* System has 16GB RAM.
* No swap configured.
* Despite low "free" memory, 7GB is available due to cache reclaim.
* Memory utilization is typical for Linux (aggressive caching).

---

# Task 2 — Networking Analysis

## 2.1 Network Path Tracing

### `traceroute github.com` 

```bash
1  192.168.1.1
2  100.125.0.1
3  78.107.11.6
4  79.104.242.216
5  mx01.Frankfurt.gldn.net
6  de-cix2.fra.github.com
7-30  * * *
```

📌 **Insights:**

* Traffic exits local gateway (192.168.1.1).
* ISP internal routing visible.
* Routed through Frankfurt exchange (DE-CIX).
* GitHub edge reached at hop 6.
* Subsequent hops hidden (likely ICMP blocked).

This indicates geographically optimized routing through Frankfurt IX.

---

### `dig github.com` 

```bash
github.com. 3155 IN A 140.82.121.4
Query time: 6 msec
SERVER: 192.168.1.1#53
```

📌 **Observations:**

* DNS resolved via local router (192.168.1.1).
* Very low query time (6 ms).
* Single A record returned.
* EDNS and DNS cookies enabled.

---

## 2.2 Packet Capture

### `tcpdump`

```bash
0 packets captured
```

📌 **Analysis:**

* No DNS packets observed during capture window.
* Likely DNS cached locally.
* Linux `any` interface does not support promiscuous mode.
* To capture traffic, cache must be cleared or new query generated.

Example DNS query (sanitized):

```
192.168.1.XXX → 192.168.1.1.53 A github.com
```

---

## 2.3 Reverse DNS Lookups

### `dig -x 8.8.4.4`

```bash
4.4.8.8.in-addr.arpa. PTR dns.google.
```

### `dig -x 1.1.2.2`

```bash
status: NXDOMAIN
```

📌 **Comparison:**

* 8.8.4.4 has valid PTR → `dns.google.`
* 1.1.2.2 returns NXDOMAIN (no reverse record).
* Not all public IPs maintain reverse DNS entries.
* PTR records are optional and primarily used for validation/logging.

---

# Overall Observations

### OS

* Boot time acceptable for development workstation.
* Heavy services: man-db, Docker, NetworkManager-wait-online.
* Electron and browser processes dominate RAM.
* No swap configured (acceptable with 16GB RAM).
* Single-user secure environment.

### Networking

* Efficient routing via Frankfurt IX.
* DNS resolution fast and local-cached.
* Reverse DNS partially configured depending on provider.
* No abnormal routing or latency detected.

---

# Conclusion

* System shows healthy boot performance with predictable service overhead.
* Memory usage pattern typical for desktop Linux with browser workloads.
* Network routing optimized through DE-CIX Frankfurt.
* DNS resolution functioning correctly.
* No anomalies in session activity or service dependency graph.
