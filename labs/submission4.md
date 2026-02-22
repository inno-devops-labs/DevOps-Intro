# Lab 4 Submission

## Task 1: Operating System Analysis

### 1.1 Boot Performance
**Command: `systemd-analyze`**
```
Startup finished in 2.422s (userspace)
graphical.target reached after 2.376s in userspace.
```


**Command: `system-analyze blame`**
```
1.752s snapd.seeded.service
 614ms landscape-client.service
 290ms dev-sdd.device
 234ms snapd.service
 131ms user@1000.service
 125ms systemd-udev-trigger.service
  87ms systemd-resolved.service
  80ms rsyslog.service
  62ms systemd-timesyncd.service
  56ms systemd-logind.service
  48ms polkit.service
  48ms systemd-sysctl.service
  47ms snapd.socket
  46ms systemd-tmpfiles-setup-dev-early.service
  44ms user-runtime-dir@1000.service
  44ms keyboard-setup.service
  42ms systemd-tmpfiles-clean.service
  42ms systemd-journald.service
  40ms dbus.service
  39ms systemd-udevd.service
  36ms e2scrub_reap.service
  28ms dev-hugepages.mount
  27ms dev-mqueue.mount
  27ms systemd-journal-flush.service
  27ms sys-kernel-debug.mount
  26ms sys-kernel-tracing.mount
  26ms systemd-tmpfiles-setup.service
  22ms kmod-static-nodes.service
  22ms modprobe@configfs.service
lines 1-29
```


**Command: `uptime`**
```
 14:01:07 up 24 min,  1 user,  load average: 0.00, 0.00, 0.00
 ```


 **Command: `w`**
```
 14:02:40 up 25 min,  1 user,  load average: 0.00, 0.00, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
mngtr    pts/1    -                13:39   23:39   0.02s  0.01s -bash
 ```


**Observations:**
```
The system boots in 2.422 seconds (userspace).
The main delay is caused by the snapd.seeded.service, which takes 1.752 seconds to start.
The current load average is 0.00, 0.00, 0.00, indicating the system is mostly idle with minimal activity.
```


### 1.2 Process Forensics


**Top Memory Processes:(command: `ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6`)**
```
    PID    PPID CMD                         %MEM %CPU
    231       1 /usr/bin/python3 /usr/share  0.2  0.0
     52       1 /usr/lib/systemd/systemd-jo  0.2  0.0
      1       0 /sbin/init                   0.1  0.0
    120       1 /usr/lib/systemd/systemd-re  0.1  0.0
    527       1 /usr/lib/systemd/systemd --  0.1  0.0
```


```
The top memory-consuming process is: PID 231 (python3)
```


**Top CPU Processes:(command: `ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6`)**
```
    PID    PPID CMD                         %MEM %CPU
      1       0 /sbin/init                   0.1  0.0
    106       1 /usr/lib/systemd/systemd-ud  0.0  0.0
     52       1 /usr/lib/systemd/systemd-jo  0.2  0.0
    193       1 @dbus-daemon --system --add  0.0  0.0
    930       1 /usr/lib/polkit-1/polkitd -  0.1  0.0
```


```
The top cpu-consuming process is: PID 1 (init)
```


### 1.3: Service Dependencies

**Command: `systemctl list-dependencies`**

```
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
○   ├─snapd.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-logind.service
○   ├─systemd-update-utmp-runlevel.service
●   ├─systemd-user-sessions.service
○   ├─ua-reboot-cmds.service
○   ├─ubuntu-advantage.service
●   ├─unattended-upgrades.service
●   ├─wsl-pro.service
●   ├─basic.target
lines 1-29
```


**Command: `systemctl list-dependencies multi-user.target`**

```
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
● ├─systemd-user-sessions.service
○ ├─ua-reboot-cmds.service
○ ├─ubuntu-advantage.service
● ├─unattended-upgrades.service
● ├─wsl-pro.service
● ├─basic.target
○ │ ├─tmp.mount
● │ ├─paths.target
○ │ │ └─apport-autoreport.path
● │ ├─slices.target
lines 1-29
```


### 1.4: User Sessions

**Command: `who -a`**

```
           system boot  2026-02-22 13:38
           run-level 5  2026-02-22 13:38
LOGIN      console      2026-02-22 13:38               220 id=cons
LOGIN      tty1         2026-02-22 13:38               225 id=tty1
mngtr    - pts/1        2026-02-22 13:39 00:40         550
           pts/2        2026-02-22 13:41               968 id=ts/2  term=0 exit=0
```

**Command: `last -n 5`**

```
reboot   system boot  6.6.87.2-microso Sun Feb 22 13:38   still running

wtmp begins Sun Feb 22 13:38:39 2026
```

### 1.5: Memory Analysis

**Command: `free -h`**

```
               total        used        free      shared  buff/cache   available
Mem:           7.4Gi       537Mi       6.8Gi       3.6Mi       185Mi       6.8Gi
Swap:          2.0Gi          0B       2.0Gi
```


**Command: `cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable`**

```
MemTotal:        7712956 kB
MemAvailable:    7162332 kB
SwapTotal:       2097152 kB
```

**Observations:**

```
Total memory: 7.4 GiB (7,712,956 kB).
Available memory: 6.8 GiB (7,162,332 kB).
Swap: 2.0 GiB total, currently not used (0 B used).
```


**Resource Utilization Patterns:**
```
CPU: System is mostly idle with load average of 0.00, indicating no significant CPU contention
Memory: Only ~7% of total memory is used (537 MiB out of 7.4 GiB), with 6.8 GiB freely available
Swap: Currently unused (0 B), suggesting physical memory is sufficient for current workload
Processes: No single process consumes significant resources - top memory users use only 0.2% MEM each, top CPU users show 0.0% CPU usage
```

## Task 2: Networking Analysis

### 2.1: Network Path Tracing

**Command: `traceroute github.com`**

```
traceroute to github.com (140.82.121.3), 30 hops max, 60 byte packets
 1  MM.mshome.net (172.xx.xx.x)  0.580 ms  0.499 ms  0.465 ms
 2  xxx.xxx.xxx.xxx (xxx.xxx.xxx.xxx)  26.854 ms  26.842 ms  26.830 ms
 3  xxx.xxx.x.x (xxx.xxx.x.x)  28.125 ms  28.109 ms  28.082 ms
 4  xxx.xx.xxx.xxx (xxx.xx.xxx.xxx)  28.068 ms  28.056 ms  28.042 ms
 5  xx.x.xxx.x (xx.x.xxx.x)  28.196 ms  28.184 ms  28.143 ms
 6  ae1-1.rt.irx.vie.at.retn.net (xx.xxx.xxx.x)  48.545 ms  51.666 ms  51.647 ms
 7  ae11-61.cr3-vie2.ip4.gtt.net (xxx.xx.xx.xxx)  51.631 ms  47.207 ms  46.911 ms
 8  ae33.cr1-fra6.ip4.gtt.net (xxx.xxx.xxx.xxx)  55.640 ms  58.974 ms  58.946 ms
 9  ip4.gtt.net (xx.xxx.xx.xxx)  58.148 ms  58.130 ms  58.112 ms
10  * * *
11  * * *
12  * * *
13  * * *
14  * * *
15  * * *
16  * * *
17  * * *
18  * * *
19  * * *
20  * * *
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


**Command: `dig github.com`**

```
; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 59133
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             60      IN      A       140.82.121.3

;; Query time: 79 msec
;; SERVER: xxx.xxx.xxx.xxx#xx(xxx.xxx.xxx.xxx) (UDP)
;; WHEN: Sun Feb 22 14:42:35 MSK 2026
;; MSG SIZE  rcvd: 55
```


**Observations:**
```
The route to GitHub took 9 hops before timing out (asterisks appear after hop 9)
DNS query successfully returned an A-record with IP address 140.82.121.3 in 79 ms
```

### 2.2 Packet Capture

**Command: `sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn`**

```
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
14:53:26.357533 lo    In  IP 10.2xx.xxx.xxx.xxxxx > 10.2xx.xxx.xxx.xx: 9313+ A? google.com. (28)
14:53:26.357575 lo    In  IP 10.2xx.xxx.xxx.xxxxx > 10.2xx.xxx.xxx.xx: 43366+ AAAA? google.com. (28)
14:53:26.411053 lo    In  IP 10.2xx.xxx.xxx.xx > 10.2xx.xxx.xxx.xxxxx: 43366 1/0/0 AAAA 2a00:1450:4005:X (56)
14:53:26.426360 lo    In  IP 10.2xx.xxx.xxx.xx > 10.2xx.xxx.xxx.xxxxx: 9313 1/0/0 A 142.xxxxxx (44)
14:53:26.493231 lo    In  IP 10.2xx.xxx.xxx.xxxxx > 10.2xx.xxx.xxx.xx: 22108+ PTR? 238.39.xxxx.in-addr.arpa. (45)
5 packets captured
12 packets received by filter
0 packets dropped by kernel
```

**Observation:**
```
I observed a DNS query for: google.com.
The packet shows a request from IP X.X.X.X to port 53.
Note: IPs have been sanitized.
```

### 2.3 Reverse DNS


**Command: `dig -x 8.8.4.4`**
```
; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 26201
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   12785   IN      PTR     dns.google.

;; Query time: 56 msec
;; SERVER: 10.2xx.xxx.xxx#xx(10.2xx.xxx.xxx) (UDP)
;; WHEN: Sun Feb 22 15:12:10 MSK 2026
;; MSG SIZE  rcvd: 73
```


**Command: `dig -x 1.1.2.2`**

```
; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 28703
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         1072    IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 xxx800 3600

;; Query time: 294 msec
;; SERVER: 10.2xx.xxx.xxx#xx(10.2xx.xxx.xxx) (UDP)
;; WHEN: Sun Feb 22 15:17:04 MSK 2026
;; MSG SIZE  rcvd: 137
```

**Comparison:**
```
IP 8.8.4.4 resolves to dns.google.
IP 1.1.2.2 has no PTR record (NXDOMAIN response).
```