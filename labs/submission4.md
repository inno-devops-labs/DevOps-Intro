# TASK 1

The commands in the task are not avaliable on my Windows or Mac machines, so I used WSL with an Ubuntu distro

1.

```bash
>systemd-analyze
Startup finished in 1.528s (userspace) 
graphical.target reached after 1.504s in userspace.
```

```bash
>systemd-analyze blame
774ms landscape-client.service
334ms snapd.seeded.service
288ms dev-sdc.device
281ms user@1000.service
266ms snapd.service
214ms wsl-pro.service
143ms systemd-resolved.service
103ms systemd-journal-flush.service
 90ms systemd-logind.service
 87ms packagekit.service
 71ms systemd-udev-trigger.service
 71ms rsyslog.service
 70ms e2scrub_reap.service
 64ms logrotate.service
 54ms systemd-udevd.service
 51ms systemd-journald.service
 50ms keyboard-setup.service
 48ms systemd-timesyncd.service
 46ms dpkg-db-backup.service
lines 1-19
```

```bash
>uptime
21:12:28 up 3 min,  1 user,  load average: 0.02, 0.03, 0.00
```

```bash
>w
 21:12:51 up 4 min,  1 user,  load average: 0.09, 0.04, 0.01
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
sasa     pts/1    -                21:08    4:11   0.02s  0.02s -bash
```

```bash
>ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
    841     801 /usr/bin/python3 /usr/bin/u  5.4 44.4
   2102     841 /usr/bin/python3 /usr/bin/u  5.1 25.0
    210       1 /usr/bin/python3 /usr/share  0.5  0.0
    658       1 /usr/libexec/packagekitd     0.5  0.0
     40       1 /usr/lib/systemd/systemd-jo  0.3  0.0
```

```bash
>ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
      1       0 /usr/lib/systemd/systemd --  0.3  0.2
    683     288 fish                         0.2  0.2
    153       1 @dbus-daemon --system --add  0.1  0.1
     89       1 /usr/lib/systemd/systemd-ud  0.1  0.0
     40       1 /usr/lib/systemd/systemd-jo  0.3  0.0
```

```bash
>systemctl list-dependencies
default.target
○ ├─display-manager.service
○ ├─systemd-update-utmp-runlevel.service
○ ├─wslg.service
● └─multi-user.target
○   ├─apport.service
●   ├─console-setup.service
●   ├─cron.service
●   ├─dbus.service
○   ├─dmesg.service
○   ├─e2scrub_reap.service
○   ├─landscape-client.service
○   ├─networkd-dispatcher.service
●   ├─rsyslog.service
○   ├─snapd.apparmor.service
○   ├─snapd.autoimport.service
○   ├─snapd.core-fixup.service
○   ├─snapd.recovery-chooser-trigger.service
●   ├─snapd.seeded.service
lines 1-19
```

```bash
>systemctl list-dependencies multi-user.target
multi-user.target
○ ├─apport.service
● ├─console-setup.service
● ├─cron.service
● ├─dbus.service
○ ├─dmesg.service
○ ├─e2scrub_reap.service
○ ├─landscape-client.service
○ ├─networkd-dispatcher.service
● ├─rsyslog.service
○ ├─snapd.apparmor.service
○ ├─snapd.autoimport.service
○ ├─snapd.core-fixup.service
○ ├─snapd.recovery-chooser-trigger.service
● ├─snapd.seeded.service
○ ├─snapd.service
● ├─systemd-ask-password-wall.path
● ├─systemd-logind.service
○ ├─systemd-update-utmp-runlevel.service
lines 1-19
```

```bash
>who -a
           system boot  2026-02-27 21:08
           run-level 5  2026-02-27 21:08
LOGIN      tty1         2026-02-27 21:08               187 id=tty1
LOGIN      console      2026-02-27 21:08               179 id=cons
sasa     - pts/1        2026-02-27 21:08 00:06         365
           pts/2        2026-02-27 21:09               488 id=ts/2  term=0 exit=0
```

```bash
>last -n 5
reboot   system boot  6.6.87.2-microso Fri Feb 27 21:08   still running
reboot   system boot  6.6.87.2-microso Mon Feb 23 23:39   still running
reboot   system boot  6.6.87.2-microso Tue Jan 27 05:15 - 05:25  (00:09)
reboot   system boot  6.6.87.2-microso Mon Jan 26 11:54 - 12:00  (00:06)
reboot   system boot  6.6.87.2-microso Mon Jan 26 11:29 - 12:00  (00:31)

wtmp begins Tue Dec  9 14:27:17 2025
```

```bash
>free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       531Mi       2.6Gi       3.5Mi       888Mi       3.3Gi
Swap:             0B          0B          0B
```

```bash
>cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:        4011252 kB
MemAvailable:    3468264 kB
SwapTotal:             0 kB
```

## Analysis

### Key Observations

**Startup Performance**
- Fast boot: 1.528s
- Slowest service: landscape-client.service (774ms)
- Second slowest: snapd.seeded.service (334ms)

**System Uptime**
- Fresh boot: 3-4 minutes
- Very low load: 0.02, 0.03, 0.00
- Single user logged in

**Process Analysis**
- Top memory: `/usr/bin/python3 /usr/bin/u` (PID 841) - 5.4%
- Second memory: Python process (PID 2102) - 5.1%
- Low CPU usage: systemd uses only 0.2%

**Dependencies**
- WSL environment detected
- Multiple snap services active
- Standard services running (cron, dbus, rsyslog)

**Login History**
- Boot time: 21:08 on 2026-02-27
- Run-level 5 (graphical mode)
- Previous sessions show extended uptime

**Memory**
- Total: 3.8Gi
- Used: 531Mi (14%)
- Available: 3.3Gi (86%)
- No swap configured


### Top Memory-Consuming Process

`/usr/bin/python3 /usr/bin/u` (PID 841) with 5.4% memory usage.


### Resource Utilization Patterns

- Minimal CPU and memory usage
- Python processes dominate memory
- No swap pressure
- Low CPU utilization
- WSL environment characteristics
- Fast boot time
- Snap services add startup overhead


# TASK 2

```bash
>traceroute github.com
traceroute to github.com (140.82.121.3), 64 hops max
  1   10.91.48.1  5.863ms  4.724ms  2.852ms 
  2   10.252.6.1  3.824ms  2.163ms  2.095ms
  3   84.18.123.1  16.681ms  17.384ms  14.796ms
  4   178.176.191.24  11.294ms  9.190ms  10.246ms
  5   *  *  *
  6   *  *  *
  7   *  *  *
  8   *  *  *
  9   83.169.204.82  49.240ms  49.035ms  51.441ms
 10   194.68.128.180  48.869ms  47.699ms  47.467ms
 11   *  *  *
 12   *  *  * 
 13   *  *  * 
 14   *  *  * 
 15   *  *  * 
 16   94.103.180.24  60.990ms  59.268ms  59.494ms 
 17   45.153.82.37  64.844ms  65.902ms  65.328ms 
 18   *  *  * 
 19   *  *  * 
 20   *  *  * 
 21   *  *  * 
 22   *  *  * 
 23   *  *  * 
 24   *  *  * 
 25   *  *  * 
 26   *  *  * 
 27   *  *  * 
 28   *  *  * 
 29   *  *  * 
 30   *  *  * 
 31   *  *  *
 ...
```

```bash
> dig github.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13067
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             35      IN      A       140.82.121.4

;; Query time: 28 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Fri Feb 27 21:27:31 MSK 2026
;; MSG SIZE  rcvd: 55
```

```bash
>sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

```bash
>dig -x 8.8.4.4

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63698
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   1067    IN      PTR     dns.google.

;; Query time: 32 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Fri Feb 27 21:29:33 MSK 2026
;; MSG SIZE  rcvd: 73
```

```bash
>dig -x 8.8.4.4

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63698
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   1067    IN      PTR     dns.google.

;; Query time: 32 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Fri Feb 27 21:29:33 MSK 2026
;; MSG SIZE  rcvd: 73

sasa@ob0china /m/d/s/I/3/2/I/DevOps-Intro (main)> dig -x 1.1.2.2

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 64523
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         600     IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 305 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Fri Feb 27 21:30:00 MSK 2026
;; MSG SIZE  rcvd: 137
```


## WSL Network Quirks

WSL2's virtualized network architecture causes tcpdump to miss packets because DNS traffic is NAT'd through the Windows host before reaching the WSL network interface, while traceroute's blocked ICMP responses result from both router security policies and WSL's virtual networking layer filtering certain packet types.


## Analysis

### Network Path Insights

**Traceroute to github.com**
- Local gateway: 10.91.48.1 (2-5ms)
- ISP network: 10.252.6.1 (2-3ms)
- Public internet: 84.18.123.1, 178.176.191.24 (10-17ms)
- Multiple hops blocked: Hops 5-8, 11-15, 18-31 return no response
- Final reachable hops: 83.169.204.82, 194.68.128.180, 94.103.180.24, 45.153.82.37
- Latency increases: 2ms → 65ms as distance increases
- Many routers block ICMP packets (common security practice)

### DNS Query/Response Patterns

**Forward DNS (github.com)**
- Query type: A record
- Response: 140.82.121.4
- TTL: 35 seconds (short, indicates dynamic load balancing)
- Query time: 28ms
- DNS server: 10.255.255.254 (internal/ISP DNS)
- Status: NOERROR
- EDNS enabled: UDP 4000 bytes

**Packet Capture**
- 0 DNS packets captured in 10 seconds
- No DNS activity during capture window
- May indicate cached responses or idle period

### Reverse Lookup Comparison

**8.8.4.4 (Google DNS)**
- Status: NOERROR
- PTR record: dns.google
- TTL: 1067 seconds (~18 minutes)
- Query time: 32ms
- Successfully resolves to hostname

**1.1.2.2 (APNIC)**
- Status: NXDOMAIN (non-existent domain)
- No PTR record found
- Authority: ns.apnic.net
- Query time: 305ms (slower)
- No reverse DNS configured
