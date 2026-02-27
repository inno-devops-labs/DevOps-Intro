# Lab 4 — Submission

## Task 1 — Operating System Analysis

---

### 1.1 Boot Performance Analysis

```text
systemd-analyze
Startup finished in 3.212s (userspace)
graphical.target reached after 3.159s in userspace.
```

```text
systemd-analyze blame | head -n 10
6.849s apt-daily-upgrade.service
1.487s landscape-client.service
751ms dev-sdd.device
659ms snapd.seeded.service
513ms snapd.service
383ms wsl-pro.service
```

```text
uptime
16:43:28 up 9 min, 1 user, load average: 0.02, 0.06, 0.02
```

```text
w
USER     TTY      LOGIN@   IDLE   WHAT
krasand  pts/1    16:34    9:23   -bash
```

**Observations:**

- The system booted in approximately 3 seconds (userspace), which is expected for WSL.
- The longest starting service was `apt-daily-upgrade.service`.
- Load average values are very low, indicating the system is mostly idle.
- Only one active user session is present.

---

### 1.2 Process Forensics

```text
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
613   1   /usr/bin/python3 ...   0.9  0.0
217   1   /usr/bin/python3 ...   0.6  0.0
897   1   /usr/libexec/packagekitd 0.5 0.0
```

```text
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
1   0   /sbin/init   0.3  0.3
613 1   /usr/bin/python3 ... 0.9 0.0
```

**Top memory-consuming process:**  
`/usr/bin/python3` (system service process).

**Observations:**

- Memory and CPU usage are minimal.
- The system is not under load.
- Processes consuming memory are mostly background services.

---

### 1.3 Memory Analysis

```text
free -h
Mem: 3.3Gi total, 440Mi used, 2.8Gi free
Swap: 1.0Gi total, 0B used
```

```text
MemTotal: 3459304 kB
MemAvailable: 3008040 kB
SwapTotal: 1048576 kB
```

**Observations:**

- Most memory is available (~2.9Gi).
- Swap is configured but not used.
- The system has sufficient free memory.

---

### 1.4 User Sessions

```text
who -a
system boot 2026-02-27 16:34
krasand pts/1 2026-02-27 16:34
```

```text
last -n 5
reboot system boot 6.6.87.2-microsoft ...
```

**Observations:**

- Only one user session is active.
- Recent system activity shows WSL reboots.
- No unusual login activity detected.

---

## Task 2 — Networking Analysis

---

### 2.1 Network Path Tracing

```text
traceroute github.com
1  172.26.160.XXX
2  10.240.16.XXX
3  10.250.0.XXX
...
18 r1-fra3-de.as5405.net (94.103.180.24)
19 cust-sid436.fra3-de.as5405.net (45.153.82.37)
```

```text
dig github.com

ANSWER SECTION:
github.com.    IN  A  140.82.121.4
```

**Observations:**

- The route includes private internal network hops (10.x.x.x and 172.x.x.x) before reaching public internet routers.
- DNS resolution confirms `github.com` resolves to IP address `140.82.121.4`.

---

### 2.2 Packet Capture (DNS Traffic)

```text
sudo tcpdump -c 5 -i any 'port 53' -nn

Out IP 172.26.162.XXX.58057 > 172.26.160.XXX.53: A? google.com.
In  IP 172.26.160.XXX.53 > 172.26.162.XXX.58057: A 172.217.19.238
```

**Observations:**

- The packet capture shows a DNS query for `google.com`.
- The response contains the resolved IP address.
- Local IP addresses were partially masked for privacy.

---

### 2.3 Reverse DNS Lookup

```text
dig -x 8.8.4.4

ANSWER SECTION:
4.4.8.8.in-addr.arpa. PTR dns.google.
```

```text
dig -x 1.1.2.2

status: NXDOMAIN
```

**Observations:**

- The IP address `8.8.4.4` resolves to `dns.google`, confirming it belongs to Google DNS.
- The IP address `1.1.2.2` does not have a PTR record (NXDOMAIN).
- Reverse DNS depends on whether a PTR record is configured for the IP address.