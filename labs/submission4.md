# Lab 4 Submission

## Task 1 — Operating System Analysis

---

## 1.1 Boot Performance

### Commands Used
```bash
systemd-analyze
systemd-analyze blame
```

### Output:

Startup finished in 1.845s (userspace)
graphical.target reached after 1.835s in userspace.

991ms landscape-client.service
345ms dev-sdc.device
311ms snapd.seeded.service
242ms snapd.service
197ms wsl-pro.service
189ms logrotate.service
154ms systemd-udev-trigger.service
140ms systemd-resolved.service
120ms user@1000.service
114ms systemd-journald.service
114ms rsyslog.service


Observations:
The system boot time is very fast (1.845 seconds).
The slowest service is landscape-client.service (991ms).
Most services start in less than 500ms.
The system looks stable and optimized.

## 1.2 Process Forensics

### Commands used:

ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6

### Output:

PID    PPID CMD                         %MEM %CPU
213       1 /usr/bin/python3             0.2  0.1
51        1 systemd-journald             0.2  0.2
178       1 wsl-pro-service              0.1  0.0
1         0 /sbin/init                   0.1  0.9
108       1 systemd-resolved              0.1  0.1

Observations:
The top memory-consuming process is /usr/bin/python3.
The top CPU-consuming process is /sbin/init.
CPU and memory usage are very low.
The system is not under heavy load.

## 1.3 Service Dependencies

### Commands used:

systemctl list-dependencies
systemctl list-dependencies multi-user.target

### Output (partial):

default.target
 ├─display-manager.service
 ├─systemd-update-utmp-runlevel.service
 ├─wsl-binfmt.service
 └─multi-user.target
     ├─cron.service
     ├─dbus.service
     ├─rsyslog.service
     ├─snapd.seeded.service
     ├─systemd-logind.service

Observations:
The system has many dependent services.
multi-user.target includes important services like cron, dbus and rsyslog.
These services are required for normal system operation.

## 1.4 User Sessions

### Commands used:

who -a
last -n 5

Observations:
The system shows normal user session activity.
There are no unusual login attempts.
Session management works correctly.

## 1.5 Memory Analysis

### Commands used:

free -h
cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable

### Output:

Mem:   7.7Gi total, 619Mi used, 6.9Gi free, 7.1Gi available
Swap:  2.0Gi total, 0B used
MemTotal: 8050708 kB
MemAvailable: 7416176 kB
SwapTotal: 2097152 kB

Observations:
Total memory is 7.7GB.
Available memory is 7.1GB, which is very high.
Swap memory is 2GB and currently not used.
Memory usage is low and stable.

Answer to Required Question

What is the top memory-consuming process?
The top memory-consuming process is /usr/bin/python3.

Resource Utilization Patterns

The system shows low CPU usage.
Memory usage is minimal and stable.
Swap memory is not used.
Boot time is very fast.
Overall, the system is running efficiently without heavy resource consumption.

---

# Task 2 — Networking Analysis

## 2.1 Path Tracing & DNS Resolution

### Commands Used
```bash
traceroute github.com
dig github.com
```

### Traceroute Output (Partial)

traceroute to github.com (20.205.243.166), 30 hops max
 1  172.18.144.1  0.336 ms
 2  192.168.1.1   6.209 ms
 3  27.71.110.4   6.226 ms
 ...
10  104.44.15.84  13.519 ms
11  104.44.53.235 46.227 ms
...
17  * * *

### DNS Lookup Output
github.com.  4  IN  A  20.205.243.166
Observations

Traceroute shows multiple network hops before reaching GitHub.

Some hops are hidden (* * *) which is normal.

DNS successfully resolves github.com to IP address 20.205.243.166.

Network latency is stable and acceptable.

## 2.2 Packet Capture (DNS Traffic)
### Command Used
sudo tcpdump -c 5 -i any 'port 53' -nn
Output (Sanitized)
IP 10.255.255.XXX.52639 > 10.255.255.XXX.53: SRV? _http._tcp.security.ubuntu.com.
IP 10.255.255.XXX.60629 > 10.255.255.XXX.53: SRV? _http._tcp.archive.ubuntu.com.
IP 10.255.255.XXX.53 > 10.255.255.XXX.52639: NXDomain
IP 10.255.255.XXX.53 > 10.255.255.XXX.60629
IP 10.255.255.XXX.38070 > 10.255.255.XXX.53: A? security.ubuntu.com.
Observations

DNS traffic was captured successfully.

The system sends DNS queries to the local DNS server.

Some requests returned NXDomain (domain not found).

Packet capture confirms active DNS resolution.

## 2.3 Reverse DNS Lookup
### Commands Used
dig -x 8.8.4.4
dig -x 1.1.2.2
Output
8.8.4.4 → dns.google.
1.1.2.2 → NXDOMAIN

### Observations
IP address 8.8.4.4 has a valid PTR record (dns.google).
IP address 1.1.2.2 does not have a reverse DNS record.
Reverse DNS lookup works correctly.

### Networking Summary
Network connectivity to GitHub is working.
DNS resolution is functioning correctly.
Reverse DNS works for valid IP addresses.
Packet capture confirms DNS activity.
The system network configuration is operating normally.
