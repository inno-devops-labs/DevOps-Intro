# Lab 4

## Task 1

### Outputs

```sh
(base) lexi@LEXI:~/personal/DevOps-Intro$ systemd-analyze
Startup finished in 4.310s (userspace)
graphical.target reached after 4.286s in userspace.
(base) lexi@LEXI:~/personal/DevOps-Intro$ systemd-analyze blame
11.618s apt-daily.service
 4.916s apt-daily-upgrade.service
 2.878s snapd.seeded.service
 2.773s snapd.service
 2.567s landscape-client.service
 2.433s logrotate.service
  682ms motd-news.service
  612ms dev-sdd.device
  509ms man-db.service
  450ms user@1000.service
  447ms wsl-pro.service
  225ms systemd-resolved.service
  168ms rsyslog.service
  164ms systemd-journal-flush.service
  142ms keyboard-setup.service
  138ms e2scrub_reap.service
lines 1-16

(base) lexi@LEXI:~/personal/DevOps-Intro$ uptime
 16:41:24 up  5:08,  1 user,  load average: 0.03, 0.07, 0.26

(base) lexi@LEXI:~/personal/DevOps-Intro$ w
 16:41:28 up  5:08,  1 user,  load average: 0.10, 0.09, 0.26
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
lexi     pts/1    -                11:05    5:35m  0.05s  0.04s -bash

(base) lexi@LEXI:~/personal/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
  16465   16313 /home/lexi/.cursor-server/b 10.8  1.7
  16313     483 /home/lexi/.cursor-server/b  5.2  2.0
  17730   17058 python run.py                2.3  0.3
  16320     483 /home/lexi/.cursor-server/b  0.8  0.2
    303     269 .venv/bin/python bot.py      0.7  0.0

(base) lexi@LEXI:~/personal/DevOps-Intro$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
  16313     483 /home/lexi/.cursor-server/b  5.2  2.0
  16465   16313 /home/lexi/.cursor-server/b 10.8  1.7
    483     475 /home/lexi/.cursor-server/b  0.6  0.6
  17730   17058 python run.py                2.3  0.3
  16320     483 /home/lexi/.cursor-server/b  0.8  0.2

(base) lexi@LEXI:~/personal/DevOps-Intro$ systemctl list-dependencies
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
●   ├─snap-core24-1267.mount
●   ├─snap-core24-1349.mount
lines 1-16

(base) lexi@LEXI:~/personal/DevOps-Intro$ systemctl list-dependencies multi-user.target
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
● ├─snap-core24-1267.mount
● ├─snap-core24-1349.mount
● ├─snap-ruff-1557.mount
● ├─snap-ruff-1569.mount
● ├─snap-snapd-25577.mount
● ├─snap-snapd-25935.mount

(base) lexi@LEXI:~/personal/DevOps-Intro$ who -a
           system boot  2026-02-25 11:05
           run-level 5  2026-02-25 11:05
LOGIN      console      2026-02-25 11:05               244 id=cons
LOGIN      tty1         2026-02-25 11:05               256 id=tty1
lexi     - pts/1        2026-02-25 11:05 05:36         519

(base) lexi@LEXI:~/personal/DevOps-Intro$ last -n 5
reboot   system boot  6.6.87.2-microso Wed Feb 25 11:05   still running
reboot   system boot  6.6.87.2-microso Wed Feb 18 18:24 - 17:50 (4+23:26)
reboot   system boot  6.6.87.2-microso Wed Feb 18 12:24 - 17:39  (05:14)
reboot   system boot  6.6.87.2-microso Tue Feb 17 18:04 - 11:16  (17:12)
reboot   system boot  6.6.87.2-microso Tue Feb 17 14:02 - 15:44  (01:42)

wtmp begins Fri Feb  6 08:33:52 2026

(base) lexi@LEXI:~/personal/DevOps-Intro$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       2.2Gi       5.4Gi       5.9Mi       426Mi       5.6Gi
Swap:          2.0Gi        42Mi       2.0Gi

(base) lexi@LEXI:~/personal/DevOps-Intro$ cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
MemTotal:        8133868 kB
MemAvailable:    5846400 kB
SwapTotal:       2097152 kB
```

### Analysis

- **Startup (`systemd-analyze`, `blame`)**: The system starts fast for userspace (about 4.3s). The longest services are `apt-daily.service` and `apt-daily-upgrade.service`.
- **Current load (`uptime`, `w`)**: Load average is low, so CPU pressure is small. Only one active user session is shown.
- **Processes by memory (`ps --sort=-%mem`)**: The biggest memory process is `/home/lexi/.cursor-server/b` (PID 16465), using **10.8% MEM**.
- **Processes by CPU (`ps --sort=-%cpu`)**: CPU use is also led by `.cursor-server` processes, but values are low (about 2.0% and 1.7%).
- **Service dependencies (`systemctl list-dependencies`)**: `multi-user.target` loads core services like `cron`, `dbus`, and `rsyslog`, plus several `snap` mounts.
- **User/login history (`who -a`, `last`)**: The system booted at 11:05 and has been running since then. Reboot records look regular.
- **Memory status (`free -h`, `/proc/meminfo`)**: Total RAM is 7.8 GiB; used is 2.2 GiB; available is 5.6 GiB. Swap use is very small (42 MiB).

### Resource utilization patterns

- CPU usage stays low and stable.
- Memory usage is moderate, with most RAM still available.
- Swap is almost not used, which means memory pressure is low.
- Background update services (`apt-daily*`) affect startup time more than interactive tasks.

## Task 2

### Outputs

```sh
(base) lexi@LEXI:~/personal/DevOps-Intro$ traceroute github.com
traceroute to github.com (140.82.121.3), 64 hops max
  1   172.28.208.1  1.069ms  1.386ms  0.731ms
  2   10.240.47.252  3.642ms  2.884ms  3.356ms
  3   12.0.74.124  3.160ms  7.962ms  7.198ms
  4   10.41.60.14  2.703ms  2.446ms  2.355ms
  5   10.41.160.227  2.868ms  3.181ms  2.767ms
  6   12.0.63.195  13.685ms  4.290ms  3.453ms
  7   12.0.63.201  3.095ms  2.635ms  2.209ms
  8   12.0.63.195  3.180ms  2.644ms  3.217ms
  9   *  *  *

(base) lexi@LEXI:~/personal/DevOps-Intro$ dig github.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 38151
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             13      IN      A       140.82.121.3

;; Query time: 7 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Wed Feb 25 16:53:04 MSK 2026
;; MSG SIZE  rcvd: 55

(base) lexi@LEXI:~/personal/DevOps-Intro$ sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel

(base) lexi@LEXI:~/personal/DevOps-Intro$ dig -x 8.8.4.4

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 50200
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   9182    IN      PTR     dns.google.

;; Query time: 29 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Wed Feb 25 17:23:51 MSK 2026
;; MSG SIZE  rcvd: 73

(base) lexi@LEXI:~/personal/DevOps-Intro$ dig -x 1.1.2.2

; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 33799
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         300     IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 51 msec
;; SERVER: 10.255.255.254#53(10.255.255.254) (UDP)
;; WHEN: Wed Feb 25 17:23:55 MSK 2026
;; MSG SIZE  rcvd: 137
```

### Analysis

- **Network path insights (`traceroute`)**: The route has many private/internal hops first, then goes outside. Latency is mostly low, with one higher hop. The last hop is hidden (`* * *`), which is common when a router does not answer.
- **DNS query/response patterns (`dig`)**: For `github.com`, DNS returns quickly with `NOERROR` and one A record. The resolver used is local (`10.255.255.254`), and response size is small.
- **Reverse lookup comparison (`dig -x`)**: `8.8.4.4` returns a valid PTR (`dns.google.`). `1.1.2.2` returns `NXDOMAIN`, so no reverse DNS name exists for that IP.
- **One DNS packet-capture example (sanitized)**: This run captured no packets, but a normal DNS line can look like:
  `IP 10.x.x.x.53012 > 10.x.x.x.53: 38151+ A? github.com. (28)`

### Resource utilization patterns

- Network and DNS tools responded fast in this test.
- DNS success and failure are both visible: one normal answer and one `NXDOMAIN`.
- Packet capture may show `0 packets` when there is no DNS traffic during the 10-second window.
