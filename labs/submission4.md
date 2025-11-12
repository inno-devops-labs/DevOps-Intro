# Lab 4 — Operating Systems & Networking — Submission

> Generated on: 
  - Mon, 29 Sep 2025 23:56:46 +0300

## Task 1 — Operating System Analysis

### 1.1 Boot Performance & Load
**Commands**
```
systemd-analyze
systemd-analyze blame
uptime
w
```
**Output**
```
bash: systemd-analyze: command not found

bash: systemd-analyze: command not found

./collect_lab4.sh: line 18: uptime: command not found

./collect_lab4.sh: line 18: w: command not found
```

### 1.2 Process Forensics
**Commands**
```
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
```
**Output**
```
ps: unknown option -- o
Try `ps --help' for more information.

ps: unknown option -- o
Try `ps --help' for more information.
```

**Top memory-consuming process:** (not available)

### 1.3 Service Dependencies
**Commands**
```
systemctl list-dependencies
systemctl list-dependencies multi-user.target
```
**Output**
```
bash: systemctl: command not found

bash: systemctl: command not found
```

### 1.4 User Sessions
**Commands**
```
who -a
last -n 5
```
**Output**
```

bash: last: command not found
```

### 1.5 Memory Analysis
**Commands**
```
free -h
grep -E 'MemTotal|SwapTotal|MemAvailable' /proc/meminfo
```
**Output**
```
bash: free: command not found

MemTotal:       16110760 kB
SwapTotal:      15204352 kB
```

**Observations (add brief notes):**
- Boot time hotspots:
- Users logged in:
- Resource utilization patterns:

---

## Task 2 — Networking Analysis

### 2.1 Path Tracing & DNS Resolution
**Commands**
```
traceroute github.com
dig github.com
```
**Output**
```
traceroute not found; skipping.

dig not found; skipping.
```

### 2.2 Packet Capture (DNS)
**Command**
```
sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
```
**Output (sanitized)**  
```
tcpdump not found; skipping capture.
```

**One example DNS query from capture:** (no DNS query captured)

### 2.3 Reverse DNS (PTR)
**Commands**
```
dig -x 8.8.4.4
dig -x 1.1.2.2
```
**Output**
```
dig not found; skipping reverse lookups.

dig not found; skipping reverse lookups.
```

**Comparison / Notes:**  
- PTR for 8.8.4.4:  
- PTR for 1.1.2.2:  

---

## Security Notes
1. IPs in packet capture sanitized (last octet `XXX`).
2. Avoided sensitive process names in analysis text.
