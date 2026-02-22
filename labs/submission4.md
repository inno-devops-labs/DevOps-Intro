# Lab 4 Submission

## Task 1 — Operating System Analysis

### 1.1: Boot Performance Analysis

Analyze System Boot Time:

```bash
$ systemd-analyze
Startup finished in 1.530s (kernel) + 8.257s (userspace) = 9.788s 
graphical.target reached after 8.232s in userspace
```

```bash
$ systemd-analyze blame
6.355s apt-daily-upgrade.service           
3.992s ifupdown-pre.service                
3.137s dev-vda2.device                     
2.273s postgresql@12-main.service          
2.013s logrotate.service                   
1.969s docker.service                      
1.965s man-db.service                      
1.918s systemd-random-seed.service         
1.433s apt-daily.service                   
1.259s apparmor.service                    
1.108s certbot.service                     
 979ms fstrim.service                      
 870ms networkd-dispatcher.service         
 740ms exim4-base.service                  
 739ms systemd-resolved.service            
 582ms keyboard-setup.service              
 581ms containerd.service                  
 483ms systemd-udev-trigger.service        
 455ms systemd-journald.service            
 443ms resolvconf-pull-resolved.service    
 434ms systemd-logind.service              
 327ms ua-timer.service                    
 313ms swap.swap                           
 304ms systemd-timesyncd.service           
 255ms e2scrub_reap.service                
 242ms grub-common.service                 
 192ms modprobe@ramoops.service            
 185ms named.service                       
 184ms user@0.service                      
 177ms modprobe@efi_pstore.service         
 169ms modprobe@chromeos_pstore.service    
 166ms rsyslog.service                     
 159ms modprobe@pstore_blk.service         
 155ms modprobe@pstore_zone.service        
 104ms apache2.service                     
 103ms systemd-journal-flush.service       
 101ms systemd-udevd.service               
  99ms networking.service                  
  96ms atd.service                         
  85ms systemd-tmpfiles-setup.service      
  80ms systemd-tmpfiles-clean.service      
  74ms systemd-remount-fs.service          
  71ms sysstat.service                     
  66ms systemd-sysctl.service              
  56ms sys-kernel-tracing.mount            
  52ms dev-hugepages.mount                 
  51ms dev-mqueue.mount                    
  50ms sys-kernel-debug.mount              
  48ms ssh.service                         
  44ms systemd-sysusers.service            
  44ms systemd-modules-load.service        
  42ms plymouth-read-write.service         
  41ms systemd-user-sessions.service
```

Check System Load:

```bash
$ uptime
09:16:55 up 957 days, 20:29, 2 users, load average: 0.08, 0.06, 0.00
```

```bash
$ w
09:17:05 up 957 days, 20:29, 2 users, load average: 0.07, 0.05, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     tty1     -                10Jul23  229days  0.17s  0.17s -bash
root     pts/0    83.149.21.XXX    09:16    0.00s  0.02s  0.00s w
```

Key Observations:
- Total boot time is 9.788s with kernel initialization taking 1.530s and userspace taking 8.257s
- The slowest services during boot are `apt-daily-upgrade.service` (6.355s) and `ifupdown-pre.service` (3.992s)
- System has been up for 957 days, indicating high stability
- Current system load is very low (0.07, 0.05, 0.00), showing minimal resource usage


### 1.2: Process Forensics

Identify Resource-Intensive Processes:

```bash
$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
2487560 2487558 java -Xmx1536M -Xms1024M -X 29.3  9.3
    227       1 /lib/systemd/systemd-journa  4.6  0.0
2464459       1 bin/core core                3.8  0.0
    312       1 /usr/bin/dotnet /srv/publis  1.5  0.0
    545       1 /usr/bin/dockerd -H fd:// -  0.9  0.0
```

```bash
$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
2487560 2487558 java -Xmx1536M -Xms1024M -X 29.3  9.3
3781489 1998485 sshd: root [priv]            0.3  1.0
    508       1 /usr/bin/containerd          0.4  0.1
 131969  131936 /usr/local/bin/python src/b  0.6  0.1
      1       0 /sbin/init                   0.2  0.0
```

Key Observations:
- The Java process (PID 2487560) is both the top memory consumer (29.3%) and CPU consumer (9.3%)
- `systemd-journald` uses 4.6% memory for logging operations
- Active SSH session is using 1.0% CPU
- Docker daemon and containerd are running in the background

Answer: What is the top memory-consuming process?
The top memory-consuming process is a Java application with PID 2487560, consuming 29.3% of system memory. It's configured with heap settings `-Xmx1536M -Xms1024M`, indicating it's a Java application with allocated memory between 1GB and 1.5GB.

### 1.3: Service Dependencies

Map Service Relationships:

```bash
$ systemctl list-dependencies
default.target
● ├─accounts-daemon.service
● ├─display-manager.service
● ├─e2scrub_reap.service
● ├─systemd-update-utmp-runlevel.service
● └─multi-user.target
●   ├─apache2.service
●   ├─atd.service
●   ├─console-setup.service
●   ├─containerd.service
●   ├─cron.service
●   ├─dbus.service
●   ├─dmesg.service
●   ├─docker.service
●   ├─dotnet-app.service
●   ├─grub-common.service
●   ├─grub-initrd-fallback.service
●   ├─irqbalance.service
●   ├─mariadb.service
●   ├─named.service
●   ├─networkd-dispatcher.service
●   ├─networking.service
●   ├─ondemand.service
●   ├─plymouth-quit-wait.service
●   ├─plymouth-quit.service
●   ├─postgresql.service
●   ├─rsync.service
●   ├─rsyslog.service
●   ├─ssh.service
●   ├─sysstat.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-logind.service
●   ├─systemd-resolved.service
●   ├─systemd-update-utmp-runlevel.service
●   ├─systemd-user-sessions.service
●   ├─ua-reboot-cmds.service
●   ├─ubuntu-advantage.service
●   ├─ufw.service
●   ├─unattended-upgrades.service
●   ├─basic.target
●   │ ├─-.mount
●   │ ├─tmp.mount
●   │ ├─paths.target
●   │ ├─slices.target
●   │ │ ├─-.slice
●   │ │ └─system.slice
●   │ ├─sockets.target
●   │ │ ├─dbus.socket
●   │ │ ├─docker.socket
●   │ │ ├─systemd-initctl.socket
●   │ │ ├─systemd-journald-audit.socket
●   │ │ ├─systemd-journald-dev-log.socket
●   │ │ ├─systemd-journald.socket
●   │ │ ├─systemd-udevd-control.socket
```

```bash
$ systemctl list-dependencies multi-user.target
multi-user.target
● ├─apache2.service
● ├─atd.service
● ├─console-setup.service
● ├─containerd.service
● ├─cron.service
● ├─dbus.service
● ├─dmesg.service
● ├─docker.service
● ├─dotnet-app.service
● ├─grub-common.service
● ├─grub-initrd-fallback.service
● ├─irqbalance.service
● ├─mariadb.service
● ├─named.service
● ├─networkd-dispatcher.service
● ├─networking.service
● ├─ondemand.service
● ├─plymouth-quit-wait.service
● ├─plymouth-quit.service
● ├─postgresql.service
● ├─rsync.service
● ├─rsyslog.service
● ├─ssh.service
● ├─sysstat.service
● ├─systemd-ask-password-wall.path
● ├─systemd-logind.service
● ├─systemd-resolved.service
● ├─systemd-update-utmp-runlevel.service
● ├─systemd-user-sessions.service
● ├─ua-reboot-cmds.service
● ├─ubuntu-advantage.service
● ├─ufw.service
● ├─unattended-upgrades.service
● ├─basic.target
● │ ├─-.mount
● │ ├─tmp.mount
● │ ├─paths.target
● │ ├─slices.target
● │ │ ├─-.slice
● │ │ └─system.slice
● │ ├─sockets.target
● │ │ ├─dbus.socket
● │ │ ├─docker.socket
● │ │ ├─systemd-initctl.socket
● │ │ ├─systemd-journald-audit.socket
● │ │ ├─systemd-journald-dev-log.socket
● │ │ ├─systemd-journald.socket
● │ │ ├─systemd-udevd-control.socket
● │ │ ├─systemd-udevd-kernel.socket
● │ │ └─uuidd.socket
● │ ├─sysinit.target
● │ │ ├─apparmor.service
```

Key Observations:
- The system uses systemd with hierarchical target dependencies
- `default.target` depends on `multi-user.target`, which is the main operational target
- Multiple services are running: web servers (apache2), databases (mariadb, postgresql), containerization (docker, containerd), DNS (named), and system utilities
- Basic infrastructure services are organized under `basic.target` including mounts, sockets, and slices


### 1.4: User Sessions

Audit Login Activity:

```bash
$ who -a
           system boot  2023-07-10 12:47
root     - tty1         2023-07-10 17:10  old         3501
           run-level 5  2023-07-10 12:47
root     - pts/0        2026-02-22 09:16   .       3781446 (83.149.21.XXX)
           pts/1        2025-11-03 21:29           1169840 id=ts/1  term=0 exit=0
           pts/2        2025-06-22 18:33           1712372 id=ts/2  term=0 exit=0
           pts/5        2025-06-12 21:58           1515959 id=ts/5  term=0 exit=0
           pts/4        2025-07-07 21:28           2052116 id=ts/4  term=0 exit=0
           pts/6        2024-09-09 22:01           2220568 id=ts/6  term=0 exit=0
           pts/3        2025-07-07 23:54           2054583 id=ts/3  term=0 exit=0
           pts/9        2025-07-05 09:04           1998609 id=ts/9  term=0 exit=0
```

```bash
$ last -n 5
root     pts/0        83.149.21.XXX    Sun Feb 22 09:16   still logged in
root     pts/0        83.149.21.XXX    Sun Feb 22 09:15 - 09:15  (00:00)
root     pts/0        217.113.117.XXX  Thu Feb  5 08:18 - 08:19  (00:00)
root     pts/0        83.229.82.XXX    Fri Dec 19 15:08 - 17:59  (02:50)
root     pts/0        83.229.82.XXX    Mon Nov 24 21:51 - 22:31  (00:40)

wtmp begins Thu Jul  6 22:04:57 2023
```

Key Observations:
- System has been running since July 10, 2023 (boot time)
- One active session on tty1 from the initial boot
- Current active SSH session on pts/0 established on Feb 22, 2026
- Multiple terminated pseudo-terminal sessions (pts/1-9) from various dates
- Recent login activity shows connections from different IP addresses
- Login records are available since July 6, 2023



### 1.5: Memory Analysis

Inspect Memory Allocation:

```bash
$ free -h
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       849Mi       114Mi       2.0Mi       1.0Gi       948Mi
Swap:         8.0Gi       1.0Gi       7.0Gi
```

```bash
$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:        2018756 kB
MemAvailable:     973436 kB
SwapTotal:       8388600 kB
```

Key Observations:
- System has approximately 2GB of total RAM (1.9GiB)
- Currently using 849MiB of RAM with 948MiB available for allocation
- Buffer/cache using 1.0GiB, which is healthy for system performance
- Swap space of 8GB is configured with 1GB currently in use
- Memory pressure is moderate with swap being utilized, suggesting the system occasionally needs more memory than physically available



### Resource Utilization Patterns

Based on the analysis, several key patterns emerge:

1. Boot Performance: The system boots efficiently in under 10 seconds, with most time spent in userspace initialization, particularly package management services.

2. Memory Pressure: With only 2GB of RAM, the system shows signs of memory pressure with 1GB of swap in use. The Java application consuming 29.3% of RAM is the primary memory consumer.

3. Service Complexity: The system runs a comprehensive stack including web servers, databases, containerization platforms, and various system services, which explains the memory utilization.

4. System Stability: The 957-day uptime demonstrates excellent system stability and reliability.

5. Active Workload: Low CPU load (0.07) but active services suggest the system is configured for server workloads with burst capacity available.

## Task 2 — Networking Analysis

### 2.1: Network Path Tracing

Traceroute Execution:

```bash
$ traceroute github.com
traceroute to github.com (4.225.11.194), 64 hops max
  1   185.179.191.XXX  0.473ms  12.220ms  0.783ms 
  2   10.255.200.XXX   0.507ms  0.490ms  0.473ms 
  3   62.115.196.XXX   21.434ms  21.445ms  21.567ms 
  4   62.115.9.XXX     22.785ms  22.866ms  22.915ms 
  5   104.44.43.XXX    23.989ms  23.918ms  24.234ms 
  6   104.44.22.XXX    25.146ms  25.031ms  25.705ms 
  7   51.10.15.XXX     27.466ms  26.469ms  26.109ms 
  8   51.10.36.XXX     28.464ms  28.425ms  28.531ms 
  9   *  *  * 
 10   *  *  * 
 11   *  *  * 
 (12-64 hops are * * *)
```

DNS Resolution Check:

```bash
$ dig github.com

; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 58142
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             34      IN      A       4.225.11.194

;; Query time: 23 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sun Feb 22 09:31:03 MSK 2026
;; MSG SIZE  rcvd: 55
```

Key Observations:
- Network Path: The traceroute shows 8 visible hops to reach GitHub's infrastructure before packets are filtered
- Latency Profile: 
  - First hop (local gateway): ~0.5ms - excellent local network performance
  - Hops 3-4 (~22ms): Likely ISP backbone within the region
  - Hops 5-8 (~24-28ms): Microsoft Azure network (104.44.x.x and 51.10.x.x ranges)
  - Hops 9-64: No response (*), indicating firewall/security filtering at destination
- DNS Resolution: GitHub's domain resolves to 4.225.11.194 (part of Microsoft Azure's IP range)
- Response Time: DNS query completed in 23ms, using local systemd-resolved cache (127.0.0.53)
- TTL: DNS record has a 34-second TTL, indicating frequent updates for load balancing

### 2.2: Packet Capture

Capture DNS Traffic:

```bash
$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked v1), capture size 262144 bytes

0 packets captured
3 packets received by filter
0 packets dropped by kernel
```

Key Observations:
- The packet capture was set to capture 5 DNS packets but captured 0 packets during the timeout period
- 3 packets were received by the filter but not captured, likely due to the `-c 5` limit and timing
- No packets were dropped by the kernel, indicating sufficient buffer space
- The lack of captured DNS traffic suggests:
  - DNS queries are being cached by systemd-resolved (127.0.0.53)
  - No active DNS lookups occurred during the 10-second capture window
  - Local DNS resolver is effectively caching queries, reducing external DNS traffic

### 2.3: Reverse DNS

Perform PTR Lookups:

```bash
$ dig -x 8.8.4.4

; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 45118
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   80252   IN      PTR     dns.google.

;; Query time: 19 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sun Feb 22 09:31:58 MSK 2026
;; MSG SIZE  rcvd: 73
```

```bash
$ dig -x 1.1.2.2

; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 47241
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; Query time: 43 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Sun Feb 22 09:32:08 MSK 2026
;; MSG SIZE  rcvd: 49
```

Key Observations:
- 8.8.4.4 (Google DNS):
  - Successfully resolved to `dns.google.`
  - PTR record has a high TTL (80252 seconds ≈ 22 hours), indicating stable, long-term DNS infrastructure
  - Query completed in 19ms
  - Google maintains proper reverse DNS records for their public DNS servers
  
- 1.1.2.2:
  - Reverse lookup failed with NXDOMAIN status (non-existent domain)
  - No PTR record exists for this IP address
  - Query took 43ms (longer than successful query, likely due to multiple retry attempts)
  - This IP does not have a configured reverse DNS entry

Comparison of Reverse Lookup Results:
- Configuration Quality: Google's DNS infrastructure (8.8.4.4) has properly configured PTR records, while 1.1.2.2 does not
- Response Time: Successful PTR lookup (19ms) was faster than failed lookup (43ms), as failures require timeout periods
- Infrastructure: The high TTL on Google's PTR record (22 hours) indicates enterprise-grade DNS infrastructure with stability priorities
- Best Practices: Google follows DNS best practices by maintaining reverse DNS records for their public-facing servers, which is important for email delivery and security verification


### Network Analysis Summary

1. Insights on Network Paths Discovered:
    - The connection to GitHub routes through Microsoft Azure's network infrastructure (hops 5-8)
    - Total observable latency is approximately 28ms to reach GitHub's edge network
    - The network path shows typical ISP → backbone → cloud provider routing
    - Packet filtering at destination (hops 9+) is a security best practice to prevent reconnaissance

2. Analysis of DNS Query/Response Patterns:
    - Local DNS caching via systemd-resolved (127.0.0.53) is effective, reducing external DNS queries
    - DNS response times are excellent (19-43ms), indicating good connectivity to DNS servers
    - Short TTL values for dynamic services (GitHub: 34s) enable quick failover and load balancing
    - Long TTL values for stable services (Google DNS: 22h) reduce DNS query load

3. DNS Packet Capture Analysis:
    - No DNS packets were captured during the monitoring window, demonstrating effective local DNS caching
    - The system's DNS resolver successfully caches queries, reducing network traffic and improving response times
    - This caching behavior is beneficial for performance and reduces load on upstream DNS servers