# Lab 4 Submission

This lab was completed on a virtual machine (VirtualBox) running Lubuntu.
I used a VM because my main host system is Windows 🙃


## Task 1 - Operating System Analysis

### 1.1. Boot Performance Analysis

#### Analyze System Boot Time

I analyze system boot time using `systemd-analyze` to check kernel and userspace startup duration:

```bash
user@user-pc:~$ systemd-analyze
Startup finished in 6.546s (kernel) + 19.803s (userspace) = 26.349s 
graphical.target reached after 19.708s in userspace.
```
The total boot time is about 26 seconds.
Kernel startup takes around 6.5 seconds, and userspace takes about 20 seconds.
This is normal for a virtual machine environment.

I check which services take the longest time during startup:

```bash
user@user-pc:~$ systemd-analyze blame
8.723s systemd-udev-settle.service
8.321s snapd.seeded.service
8.002s snapd.service
7.295s dev-sda1.device
5.759s vboxadd.service
4.726s blueman-mechanism.service
...
```

The slowest services are related to `systemd-udev` and `snapd`.
The `vboxadd.service` is also visible because the system runs inside VirtualBox.
Snap services increase boot time noticeably.


#### Check System Load

I check system uptime and current load average:

```bash
user@user-pc:~$ uptime
w
 21:00:56 up 4 min,  1 user,  load average: 0.42, 0.60, 0.30
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
user     tty2     -                20:56    4:16   4.89s  0.04s /usr/lib/.../sddm-helper --soc
```

The system has been running for 4 minutes.
Load average values are below 1.0, which means the system is not overloaded.
There is one active user session.


### 1.2. Process Forensics

#### Identify Resource-Intensive Processes

I list processes sorted by memory and CPU usage:

```bash
user@user-pc:~$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
    PID    PPID CMD                         %MEM %CPU
   1492    1311 /usr/bin/pcmanfm-qt --deskt  2.9  0.4
   1495    1311 /usr/bin/lxqt-panel          2.9  0.3
   1697    1492 qterminal                    2.7  0.7
   1477    1311 /usr/bin/python3 /usr/bin/b  2.6  0.2
   1250    1240 /usr/lib/xorg/Xorg -noliste  2.5  2.0

user@user-pc:~$ ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
    PID    PPID CMD                         %MEM %CPU
   1250    1240 /usr/lib/xorg/Xorg -noliste  2.5  2.0
      1       0 /sbin/init splash            0.3  0.7
   1697    1492 qterminal                    2.7  0.7
   1805       1 /usr/libexec/fwupd/fwupd     1.0  0.6
    771       1 /usr/lib/snapd/snapd         1.0  0.4
```

The most memory-consuming processes are related to the LXQt desktop environment.
CPU usage is also low for all processes.
No process consumes a critical amount of resources.


### 1.3. Service Dependencies

#### Map Service Relationships

I inspect system service dependencies and targets:

```bash
user@user-pc:~$ systemctl list-dependencies
systemctl list-dependencies multi-user.target
default.target
● ├─accounts-daemon.service
● ├─sddm.service
● ├─switcheroo-control.service
○ ├─systemd-update-utmp-runlevel.service
● ├─udisks2.service
● └─multi-user.target
○   ├─anacron.service
●   ├─NetworkManager.service
●   ├─dbus.service
●   ├─snapd.service
●   ├─rsyslog.service
...

multi-user.target
○ ├─anacron.service
● ├─apport.service
● ├─avahi-daemon.service
○ ├─blueman-mechanism.service
● ├─console-setup.service
● ├─cron.service
● ├─cups-browsed.service
● ├─cups.path
...
```

The system uses `default.target` which depends on `multi-user.target`.
Core services like `NetworkManager`, `dbus`, and `snapd` are active.
This is a standard configuration for a desktop Linux system.


### 1.4. User Sessions

#### Audit Login Activity

I check current and previous login sessions:

```bash
user@user-pc:~$ who -a
last -n 5
           system boot  2026-02-18 20:56
           run-level 5  2026-02-18 20:56
user     + tty2         2026-02-18 20:56 00:18        1311 (:0)
user     tty2         :0               Wed Feb 18 20:56   still logged in
reboot   system boot  6.14.0-27-generi Wed Feb 18 20:56   still running
user     tty2         :0               Wed Feb 18 17:40 - 18:40  (00:59)
reboot   system boot  6.14.0-27-generi Wed Feb 18 17:40 - 18:40  (00:59)
user     tty2         :0               Wed Feb 11 17:45 - down   (01:09)

wtmp begins Tue Sep  2 22:32:25 2025
```

The system was booted recently.
There is one active user logged in on tty2.
Previous sessions and reboots are visible in the history.


### 1.5. Memory Analysis

#### Inspect Memory Allocation

I inspect total memory, available memory, and swap usage:

```bash
user@user-pc:~$ free -h
cat /proc/meminfo | grep -e MemTotal -e SwapTotal -e MemAvailable
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       738Mi       1.9Gi        11Mi       1.4Gi       3.1Gi
Swap:             0B          0B          0B
MemTotal:        4010944 kB
MemAvailable:    3254312 kB
SwapTotal:             0 kB
```

The system has 3.8 GiB of RAM.
Only about 738 MiB is used, and more than 3 GiB is available.
Swap is not configured, but current memory usage is low.


### What is the top memory-consuming process?

The top memory-consuming process is `/usr/bin/pcmanfm-qt` (about 2.9% of memory).
It is part of the LXQt desktop environment.
Other processes have similar but slightly lower memory usage.
No process consumes an unusually large amount of RAM.


### Resource utilization patterns

The system shows low overall resource usage.
Load average values are below 1.0, which indicates no CPU pressure.
Memory usage is moderate, and most RAM is available.
There is no swap usage.
The main resource consumption comes from graphical desktop services.

---

## Task 2 - Networking Analysis

### 2.1. Network Path Tracing

#### Traceroute Execution

I analyze the network path to `github.com` using traceroute:

```bash
user@user-pc:~$ traceroute github.com
traceroute to github.com (140.82.121.3), 30 hops max, 60 byte packets
 1  _gateway (10.0.2.2)  3.505 ms  3.449 ms  3.396 ms
 2  _gateway (10.0.2.2)  7.230 ms  5.875 ms  5.813 ms
```

The traceroute shows only the virtual gateway `10.0.2.2.`
This happens because the system runs inside a VirtualBox VM using NAT networking.
The internal router hides the full external routing path.

No further hops are visible from inside the VM (


#### DNS Resolution Check

I check DNS resolution using `dig`:

```bash
user@user-pc:~$ dig github.com
...
;; ANSWER SECTION:
github.com.             14      IN      A       140.82.xxx.x

;; Query time: 8 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Wed Feb 18 21:29:30 MSK 2026
;; MSG SIZE  rcvd: 55
```

The domain `github.com` resolves successfully to IP address `140.82.xxx.x`.
The DNS server used is `127.0.0.53`, which is the local system resolver (systemd-resolved).
The query time is 8 ms, which indicates fast DNS resolution.


### 2.2. Packet Capture

#### Capture DNS Traffic

I attempt to capture DNS traffic using `tcpdump`:

```bash
user@user-pc:~$ sudo tcpdump -c 5 -i any 'port 53' -nn
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
23:29:38.896307 lo    In  IP 127.0.0.1.59259 > 127.0.0.53.53: 13159+ [1au] A? content-signature-2.cdn.mozilla.net. (64)
23:29:38.897833 enp0s3 Out IP 10.0.2.15.49941 > 10.0.0.1.53: 24367+ [1au] A? content-signature-2.cdn.mozilla.net. (64)
23:29:38.898957 lo    In  IP 127.0.0.1.59259 > 127.0.0.53.53: 20836+ [1au] AAAA? content-signature-2.cdn.mozilla.net. (64)
23:29:38.899080 enp0s3 Out IP 10.0.2.15.38961 > 10.0.0.1.53: 16014+ [1au] AAAA? content-signature-2.cdn.mozilla.net. (64)
23:29:38.905194 enp0s3 In  IP 10.0.0.1.53 > 10.0.2.15.38961: 16014 1/0/1 AAAA 2600:1901:0:92a9:: (92)
5 packets captured
12 packets received by filter
0 packets dropped by kernel
```

The capture shows DNS traffic for the domain `content-signature-2.cdn.mozilla.net`. 

The traffic flow is as follows:

- The local application sends a request to the local resolver at `127.0.0.53` (systemd stub resolver).
- The resolver forwards the request from `10.0.2.15` (VM address) to `10.0.0.1` (NAT DNS server).
- The external DNS server responds with an IPv6 address: `2600:1901:0:92a9::`

This confirms:
- The VM uses NAT networking.
- DNS resolution works correctly.
- External communication occurs through the virtual gateway.

The line:
```bash
5 packets captured
12 packets received by filter
```
means that tcpdump stopped after capturing 5 packets, even though more matching packets were observed.


### 2.3. Reverse DNS

#### Perform PTR Lookups

I perform reverse DNS lookups for two IP addresses:

```bash
user@user-pc:~$ dig -x 8.8.4.4
...
;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   60438   IN      PTR     dns.google.
...

user@user-pc:~$ dig -x 1.1.2.2
...
status: NXDOMAIN
...
;; AUTHORITY SECTION:
1.in-addr.arpa.         900     IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23596 7200 1800 604800 3600
...
```

The IP address `8.8.4.4` resolves to `dns.google`.
This indicates a properly configured reverse DNS entry.

The IP address `1.1.2.2` does not have a PTR record.
The result `NXDOMAIN` means the reverse DNS entry does not exist.


### Insights on network paths discovered

The traceroute results show that the VM uses NAT networking.
Only the internal gateway is visible, and external routing hops are hidden.
This behavior is typical for virtualized environments.

Network latency appears low and stable.


### Analysis of DNS query/response patterns

All DNS queries return status `NOERROR` when successful.
The DNS server responds quickly (8–11 ms).
The system uses a local stub resolver at `127.0.0.53`.


### Comparison of reverse lookup results

The IP address `8.8.4.4` has a valid PTR record.
The IP address `1.1.2.2` does not.

This shows that reverse DNS configuration depends on the network operator.
Not all IP addresses have PTR records defined.


### Example DNS query from packet capture
```bash
user@user-pc:~$ dig google.com
...
;; ANSWER SECTION:
google.com.             7009    IN      CNAME   forcesafesearch.google.com.
forcesafesearch.google.com. 3252 IN     A       216.239.38.XXX
...
```