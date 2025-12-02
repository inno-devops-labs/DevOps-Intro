# Lab 4 Operating Systems and Networking Analysis

## Task 1: Operating System Analysis

### 1.1 Boot Performance Analysis
Startup finished in 3.411s (firmware) + 2.569s (loader) + 3.310s (kernel) + 38.531s (userspace) = 47.823s
graphical.target reached after 23.729s in userspace

#### Observations
Boot is mostly delayed in userspace (38.5s). Firmware, loader, kernel phases are comparatively fast.

### 1.2 System Load
 12:55:13 up 25 min,  1 user,  load average: 0,69, 0,75, 0,59

USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
haqunama :0       :0               15:30   ?xdm?  10:58   0.00s /usr/lib/gdm3/g

#### Observations
System load averages are low (<1), indicating low CPU load. Only one active user session.

### 1.3 Resource-Intensive Processes
    PID    PPID CMD                         %MEM %CPU
   4767    2981 /opt/google/chrome/chrome -  2.7 17.2
   1667    1223 /usr/bin/gnome-shell         2.2  5.4
   2956    1223 /opt/google/chrome/chrome    1.7  6.3
   3004    2972 /opt/google/chrome/chrome -  1.3  4.5
   6853    2981 /opt/google/chrome/chrome -  1.2  0.9

    PID    PPID CMD                         %MEM %CPU
   4767    2981 /opt/google/chrome/chrome -  2.9 17.2
   1245    1243 /usr/lib/xorg/Xorg vt2 -dis  1.0  6.5
   2956    1223 /opt/google/chrome/chrome    1.7  6.3
   1667    1223 /usr/bin/gnome-shell         2.2  5.4
   3004    2972 /opt/google/chrome/chrome -  1.3  4.5

#### Observations
- Top memory-consuming process: Google Chrome (multiple processes)
- Top CPU usage also by Chrome and Xorg
- GNOME shell relevant for desktop environment consumption

### 1.4 Service Dependencies
default.target
├─accounts-daemon.service
├─apport.service
├─e2scrub_reap.service
├─gdm.service
├─snap-bare-5.mount
├─snap-gtk\x2dcommon\x2dthemes-1535.mount
├─snap-notion\x2dsnap-16.mount
├─switcheroo-control.service
├─systemd-update-utmp-runlevel.service
├─udisks2.service
└─multi-user.target
    ├─anacron.service
    ├─apport.service
    ├─avahi-daemon.service
    ├─console-setup.service
    ├─cron.service
    ├─cups-browsed.service
    ├─cups.path
    ├─dbus.service
    ├─dmesg.service
    ... (truncated for brevity)

#### Observations
Default target depends on common system services like accounts, cron, dbus, network, snap mounts. Multi-user target manages core services for multi-user mode.

### 1.5 User Sessions and Login Activity
           system boot  2025-12-02 15:30
haqunamatata ? :0           2025-12-02 15:30   ?          1243 (:0)
           run-level 5  2025-12-02 15:30

#### Observations
Single user session logged in since boot. No multiple concurrent logins detected.

### 1.6 Memory Allocation
              total        used        free      shared  buff/cache   available
Mem:           14Gi       2,2Gi       9,4Gi        63Mi       3,4Gi        12Gi
Swap:         509Mi          0B       509Mi

MemTotal:       14647108 kB
SwapTotal:       521932 kB
MemAvailable:   12369144 kB

#### Observations
Low memory and swap usage indicating good free memory available. Swap is currently unused.

## Task 2: Networking Analysis

### 2.1 Network Path Tracing
traceroute to github.com (140.82.121.4), 64 hops max
  1   192.168.31.1  0,286ms  0,261ms  0,607ms 
  2   10.244.1.1  0,908ms  0,451ms  0,441ms 
  3   10.250.0.2  0,448ms  0,435ms  0,409ms 
  4   10.252.6.1  1,076ms  0,560ms  0,560ms 
  5   84.18.123.1  11,720ms  16,669ms  14,349ms 
  6   178.176.191.24  7,373ms  7,342ms  7,440ms 
  7   * * * 

#### Observations
6 hops to GitHub. Internal network (192.168.31.1, 10.x.x.x), then ISP routers. High latency jump at hop 5 (84.18.123.1). Traceroute stopped at hop 7.

### 2.2 DNS Resolution
; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49410
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;github.com.			IN	A

;; ANSWER SECTION:
github.com.		8	IN	A	140.82.121.4

;; Query time: 0 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Tue Dec 02 13:08:18 MSK 2025
;; MSG SIZE  rcvd: 55

#### Observations
Fast local resolution (0ms) via systemd-resolved (127.0.0.53). GitHub resolves to 140.82.121.4. Cache hit indicated by instant response.

### 2.3 Packet Capture
sudo timeout 10 tcpdump -c 5 -i any port 53 -nn
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked v1), capture size 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel

#### Observations
No DNS traffic on port 53. systemd-resolved handles queries locally (127.0.0.53 loopback), bypassing network DNS traffic.

### 2.4 Reverse DNS Lookups
dig -x 8.8.4.4:
; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> -x 8.8.4.4
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 25559
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.		IN	PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.	300	IN	PTR	dns.google.

;; Query time: 28 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)

dig -x 1.1.2.2:
; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> -x 1.1.2.2
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 41460
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.		IN	PTR

;; Query time: 156 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)

#### Observations
8.8.4.4 reverses to dns.google (Google DNS). 1.1.2.2 has no PTR record (NXDOMAIN). Local resolver used for both queries.




