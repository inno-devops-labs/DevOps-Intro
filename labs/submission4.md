# Task 1 — Operating System Analysis

## 1.1 Boot Performance Analysis

### Commands
```
systemd-analyze
systemd-analyze blame | head -n 10
```

### Output
```
Startup finished in 485ms (userspace)
graphical.target reached after 484ms in userspace.
331ms dev-sdd.device
213ms user@1000.service
 83ms systemd-logind.service
 61ms systemd-tmpfiles-clean.service
 58ms systemd-udev-trigger.service
 51ms dev-hugepages.mount
 49ms dev-mqueue.mount
 46ms sys-kernel-debug.mount
 45ms e2scrub_reap.service
 44ms sys-kernel-tracing.mount
```
### Observations
The system boot time is low and services start quickly. The slowest units include device initialization and user session services, which is normal in a WSL environment.
___
## 1.2 System Load

### Commands
```
uptime
w
```

### Output
```
 22:30:38 up  2:51,  1 user,  load average: 0.00, 0.00, 0.00
 22:30:38 up  2:51,  1 user,  load average: 0.00, 0.00, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
valeriia pts/1    -                19:39    2:51m  0.00s   ?    -bash
```
### Observations

System load averages are very low, indicating minimal CPU usage. Only a single local user session is active in the WSL environment.
___
## 1.3 Process Forensics
### Commands
```
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
```

### Output
```
    PID    PPID CMD                         %MEM %CPU
     37       1 /usr/lib/systemd/systemd-jo  0.1  0.0
      1       0 /sbin/init                   0.1  0.0
    201       1 /usr/lib/systemd/systemd --  0.1  0.0
     77       1 /usr/lib/systemd/systemd-ud  0.1  0.0
    158       1 /usr/lib/systemd/systemd-lo  0.1  0.0
    PID    PPID CMD                         %MEM %CPU
     77       1 /usr/lib/systemd/systemd-ud  0.1  0.0
      1       0 /sbin/init                   0.1  0.0
   1142    1135 -bash                        0.0  0.0
    143       1 /usr/bin/dbus-daemon --syst  0.0  0.0
     37       1 /usr/lib/systemd/systemd-jo  0.1  0.0
```
### Answer

Top memory-consuming process: systemd-journald (PID 37, 0.1% MEM)
### Observations

No abnormal or resource-intensive processes were observed. CPU and memory usage are minimal in the WSL environment.
___
## 1.4 Service Dependencies

### Commands
```
systemctl list-dependencies multi-user.target | head -n 40
```

### Output
```
multi-user.target
● ├─cron.service
● ├─dbus.service
○ ├─e2scrub_reap.service
● ├─networking.service
● ├─systemd-ask-password-wall.path
● ├─systemd-logind.service
● ├─systemd-user-sessions.service
● ├─basic.target
● │ ├─tmp.mount
● │ ├─paths.target
● │ ├─slices.target
● │ │ ├─-.slice
● │ │ └─system.slice
● │ ├─sockets.target
● │ │ ├─dbus.socket
● │ │ ├─systemd-creds.socket
● │ │ ├─systemd-hostnamed.socket
● │ │ ├─systemd-initctl.socket
● │ │ ├─systemd-journald-dev-log.socket
● │ │ ├─systemd-journald.socket
○ │ │ ├─systemd-pcrextend.socket
○ │ │ ├─systemd-pcrlock.socket
● │ │ ├─systemd-sysext.socket
● │ │ ├─systemd-udevd-control.socket
● │ │ └─systemd-udevd-kernel.socket
● │ ├─sysinit.target
● │ │ ├─dev-hugepages.mount
● │ │ ├─dev-mqueue.mount
● │ │ ├─kmod-static-nodes.service
○ │ │ ├─ldconfig.service
○ │ │ ├─proc-sys-fs-binfmt_misc.automount
● │ │ ├─sys-fs-fuse-connections.mount
● │ │ ├─sys-kernel-config.mount
● │ │ ├─sys-kernel-debug.mount
● │ │ ├─sys-kernel-tracing.mount
● │ │ ├─systemd-ask-password-console.path
○ │ │ ├─systemd-binfmt.service
○ │ │ ├─systemd-firstboot.service
○ │ │ ├─systemd-hibernate-clear.service
```
### Observations
The multi-user.target includes core system services such as cron, dbus, networking, and systemd-logind. This represents a standard multi-user Linux environment.
___
## 1.5 User Sessions

### Commands
who -a  
last -n 5  

### Output
system boot 2026-02-26 19:39  
valeriia67 pts/1 2026-02-26 19:39 03:08 189  
last: command not found  

### Observations
The system shows a single active local user session. The last command is not available in the minimal Debian WSL environment. No remote or suspicious logins detected.
___
## 1.6 Memory Analysis
### Commands
```
free -h
cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
```
 ### Output
 ```
                total        used        free      shared  buff/cache   available
Mem:           7.6Gi       473Mi       7.2Gi       3.5Mi        81Mi       7.2Gi
Swap:          2.0Gi          0B       2.0Gi
MemTotal:        7991484 kB
MemAvailable:    7506472 kB
SwapTotal:       2097152 kB
```
### Observations

The system has sufficient available memory with very low usage. Swap space is not utilized, indicating no memory pressure. Overall memory utilization is healthy.
___

# Task 2 — Networking Analysis

## 2.1 Network Path Tracing

### Command
```
traceroute github.com
```
### Output
```
(140.82.121.3), 30 hops max, 60 byte packets
 1  Matebook16.mshome.net (172.23.176.1)  0.853 ms  0.800 ms  0.768 ms
 2  192.168.0.1 (192.168.0.1)  5.859 ms  6.260 ms  5.802 ms
 3  10.242.1.1 (10.242.1.1)  6.976 ms  7.512 ms  7.391 ms
 4  10.250.0.2 (10.250.0.2)  7.302 ms  7.052 ms  7.057 ms
 5  10.252.6.1 (10.252.6.1)  7.307 ms  7.152 ms  7.197 ms
 6  1.123.18.84.in-addr.arpa (84.18.123.1)  18.693 ms  12.887 ms  12.840 ms
 7  178.176.191.24 (178.176.191.24)  7.864 ms  12.335 ms  12.304 ms
 8  * * *
 9  * * *
10  * * *
11  * * *
12  83.169.204.82 (83.169.204.82)  48.865 ms  46.807 ms  46.753 ms
13  netnod-ix-ge-a-sth-1500.inter.link (194.68.123.180)  46.522 ms  62.731 ms netnod-ix-ge-b-sth-1500.inter.link (194.68.128.180)  44.724 ms
14  * * *
15  r3-ber1-de.as5405.net (94.103.180.2)  65.383 ms  64.414 ms  62.552 ms
16  r4-fra1-de.as5405.net (94.103.180.7)  63.324 ms  62.271 ms  62.253 ms
17  * * *
18  r3-fra3-de.as5405.net (94.103.180.54)  59.351 ms  63.563 ms  67.479 ms
19  r1-fra3-de.as5405.net (94.103.180.24)  65.691 ms  59.801 ms  61.079 ms
20  cust-sid435.r1-fra3-de.as5405.net (45.153.82.39)  59.843 ms  58.966 ms  58.940 ms
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
### Insights

The traceroute to github.com resolves to 140.82.121.3 and shows the path starting from the WSL virtual gateway (172.23.176.1), then the local router (192.168.0.1), followed by several private-network hops (10.x.x.x) inside the ISP network. Multiple intermediate hops return "* * *", which is normal because many routers block ICMP/UDP traceroute probes. Latency increases after leaving the local network (up to ~60–70 ms), indicating long-distance routing through external transit/IX points. The trace does not reach the final host within 30 hops, likely due to filtering by upstream routers, but the early hops still reveal the local and ISP routing path.
____

## 2.2 DNS Resolution Check

### Command
```
dig github.com
```
### Output
```
; <<>> DiG 9.20.18-1~deb13u1-Debian <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64518
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             34      IN      A       140.82.121.3

;; Query time: 28 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Thu Feb 26 23:20:20 MSK 2026
;; MSG SIZE  rcvd: 55
```

### DNS Analysis

The DNS query for github.com succeeded with status NOERROR. The resolver returned one IPv4 A record: 140.82.121.3 with TTL 34 seconds, meaning the record is cached for a short time. The query was answered by the DNS server 10.255.255.254 over UDP/53, and the response time was 28 ms.
___
## 2.3 Packet Capture (DNS)

### Command
```
sudo timeout 10 tcpdump -c 5 -i any port 53 -nn
```

### Output
```
23:37:54.173362 lo In IP 10.255.255.254.40183 > 10.255.255.254.53: 60240+ [1au] A? google.com. (51)
23:37:54.193322 lo In IP 10.255.255.254.53 > 10.255.255.254.40183: 60240 2/0/1 CNAME forcesafesearch.google.com., A 216.239.38.120 (85)
```

### One example DNS query (sanitized)

IP client > DNS: A? google.com

### Packet Capture Analysis
The tcpdump capture shows a DNS query and response exchange.
The client sent an A record request for google.com to the DNS resolver on port 53.
The DNS server responded with a CNAME record (forcesafesearch.google.com) and the final IPv4 address 216.239.38.120.
This confirms that DNS resolution is functioning correctly in the WSL environment.
___
## 2.4 Reverse DNS (PTR lookups)

###Commands
```
dig -x 8.8.4.4
dig -x 1.1.2.2
```

### Output
```
; <<>> DiG 9.20.18-1~deb13u1-Debian <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35695
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   6992    IN      PTR     dns.google.

;; Query time: 44 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Thu Feb 26 23:41:39 MSK 2026
;; MSG SIZE  rcvd: 73


; <<>> DiG 9.20.18-1~deb13u1-Debian <<>> -x 1.1.1.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18893
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;2.1.1.1.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
2.1.1.1.in-addr.arpa.   1034    IN      PTR     security.cloudflare-dns.com.

;; Query time: 48 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Thu Feb 26 23:41:39 MSK 2026
;; MSG SIZE  rcvd: 90
```

### Comparison

The reverse DNS (PTR) lookup for 8.8.4.4 returned dns.google, confirming this IP belongs to Google's public DNS infrastructure.  
The reverse DNS lookup for 1.1.1.2 returned security.cloudflare-dns.com, indicating it is part of Cloudflare's DNS service.  
Both queries succeeded with status NOERROR and were answered by the local resolver (10.255.255.254) via UDP/53. Query times were ~44–48 ms, which is normal.