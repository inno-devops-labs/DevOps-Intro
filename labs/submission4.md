# Lab 4

## Task 1

### 1.1 Boot Performance Analysis

#### Analyzing System Boot Time

Since I work on macOS, there is no command **systemd-analyze** (systemd-analyze is a command—line utility built into the systemd initialization system on Linux. Its task is to collect and analyze data on the performance of the system boot process). Instead I used such equivalent commands:

```bash
system_profiler SPSoftwareDataType | grep "Boot Volume\|System Version\|Boot Mode" # system information
uptime # system work time
launchctl list | head -10 # equivalent to systemd-analyze blame
```

Output:

```bash
> grep "Boot Volume\|System Version\|Boot Mode"
      System Version: macOS 15.6.1 (24G90)
      Boot Volume: Macintosh HD
      Boot Mode: Normal
 > 1:23  up 4 days,  1:20, 1 user, load averages: 6.61 6.30 5.12
 > PID     Status  Label
-       0       com.apple.SafariHistoryServiceAgent
88283   -9      com.apple.progressd
65192   -9      com.apple.cloudphotod
79635   -9      com.apple.MENotificationService
585     0       com.apple.Finder
766     0       com.apple.homed
65134   -9      com.apple.dataaccess.dataaccessd
-       0       com.apple.quicklook
-       0       com.apple.parentalcontrols.check

```

#### Checking System Load

Commands used:

```bash
uptime
w
```

Output:

```bash
 1:26  up 4 days,  1:24, 1 user, load averages: 11.29 8.91 6.49
 1:26  up 4 days,  1:24, 1 user, load averages: 11.29 8.91 6.49
USER       TTY      FROM    LOGIN@  IDLE WHAT
rail       console  -      Fri00   4days -
```

#### Key Observations - Boot Performance

- **System Version**: macOS 15.6.1 running on Macintosh HD with normal boot mode
- **Uptime**: System has been running for 4 days, 1 hour
- **Load Averages**: Extremely high (11.29, 8.91, 6.49) suggesting heavy system utilization
- **Service Status**: Mix of active (status 0) and terminated (status -9) services
- **Boot Services**: Key services like Finder (PID 585) and homed (PID 766) are running properly
- **macOS uses launchd** instead of systemd for service management

### 1.2: Process Forensics

#### Identifying Resource-Intensive Processes

Again there is commands in lab4.md, that i can not run in macOS, so i used equivalent:

```bash
ps -eo pid,ppid,command,%mem,%cpu -r | head -n 6
ps -eo pid,ppid,command,%mem,%cpu -c | head -n 6
```

Output:

```bash
>  PID  PPID COMMAND          %MEM  %CPU
 2270     1 /Applications/V2  0.7 224.1
74450     1 /Applications/Te  3.2 102.1
  383     1 /System/Library/  1.1  23.2
10996     1 /System/Library/  0.1   7.7
  861     1 /Applications/Ar  2.9   7.4
>   PID  PPID COMMAND          %MEM  %CPU
    1     0 launchd           0.1   0.7
  313     1 logd              0.2   0.2
  315     1 UserEventAgent    0.1   0.0
  317     1 fseventsd         0.0   1.2
  318     1 mediaremoted      0.1   0.0
```

#### Key Observations - Process Analysis

- **Extreme CPU Usage**: V2 application showing 224.1% CPU (likely multi-threaded)
- **Terminal Activity**: Terminal process consuming 102.1% CPU and 3.2% memory
- **System Graphics**: WindowServer using 23.2% CPU for display management
- **Memory Distribution**: Applications range from 0.1% to 3.2% memory usage
- **System Processes**: Core system processes (launchd, logd) show minimal resource usage
- **Resource Intensity**: Development/productivity applications dominating resource consumption

### 1.3: Service Dependencies

#### Map Service Relationships

Again, `systemctl` commands are not available on macOS (systemctl is Linux systemd-specific). Instead I used macOS equivalent commands:

```bash
launchctl list | head -10
launchctl print system 
```

Output:

```bash
> PID     Status  Label
-       0       com.apple.SafariHistoryServiceAgent
88283   -9      com.apple.progressd
65192   -9      com.apple.cloudphotod
79635   -9      com.apple.MENotificationService
585     0       com.apple.Finder
766     0       com.apple.homed
65134   -9      com.apple.dataaccess.dataaccessd
-       0       com.apple.quicklook
-       0       com.apple.parentalcontrols.check
> system = {
        type = system
        handle = 0
        active count = 1043
        service count = 408
        active service count = 185
        maximum allowed shutdown time = 65 s
        service stats = {
                com.apple.launchd.service-stats-default (4096 records)
        }
        trial factor reloads = 4
        trial factors = {
        }
        creator = launchd[1]
        creator euid = 0
        ... # there is a lot of lines
```

#### Key Observations - Service Dependencies

- **Service Scale**: System managing 1043 total services with 408 configured
- **Active Services**: 185 services currently active (45% of configured services)
- **Service Status Mix**: Combination of running (0), terminated (-9), and dormant (-) services
- **Cloud Integration**: Multiple Apple cloud services (cloudphotod, dataaccess) present
- **User Services**: GUI-related services (Finder, Safari agents) active
- **System Architecture**: Hierarchical service management through launchd

### 1.4: User Sessions

#### Audit Login Activity

```bash
who -a
last -n 5
```

Output:

```bash
>                  system boot  Sep 19 00:02 
rail             console      Sep 19 00:45 
   .       run-level 3
> rail       console                         Fri Sep 19 00:45   still logged in
reboot time                                Fri Sep 19 00:02
shutdown time                              Fri Sep 19 00:02
rail       console                         Tue Sep 16 01:59 - 00:02 (2+22:03)
reboot time                                Tue Sep 16 01:58
```

#### Key Observations - User Sessions

- **Single User Environment**: Only user 'rail' with console access
- **Long Session**: Current session started Sep 19, running for 4+ days
- **System Stability**: Clean boot sequence with no unexpected shutdowns
- **Login Pattern**: Consistent single-user usage pattern
- **Session Type**: Console login (GUI session) rather than remote/SSH access
- **Uptime Correlation**: Login time matches system boot time

### 1.5: Memory Analysis

#### Inspect Memory Allocation

Again, `free -h` and `/proc/meminfo` are not available on macOS (Linux-specific). Instead I used macOS equivalent commands:

```bash
vm_stat
sysctl hw.memsize hw.physmem  
sysctl vm.swapusage
top -l 1 | grep PhysMem
```

Output:

```bash
> Mach Virtual Memory Statistics: (page size of 16384 bytes)
Pages free:                                7390.
Pages active:                            270178.
Pages inactive:                          255437.
Pages speculative:                        14433.
Pages throttled:                              0.
Pages wired down:                        155419.
Pages purgeable:                          13941.
"Translation faults":                 781084725.
Pages copy-on-write:                   23768517.
Pages zero filled:                    487208668.
Pages reactivated:                     21923505.
Pages purged:                           5442528.
File-backed pages:                       184527.
Anonymous pages:                         355521.
Pages stored in compressor:              706227.
Pages occupied by compressor:            306259.
Decompressions:                        10896679.
Compressions:                          15372389.
Pageins:                                5158258.
Pageouts:                                117259.
Swapins:                                      0.
Swapouts:                                    36.
> hw.memsize: 17179869184
hw.physmem: 3669164032
> vm.swapusage: total = 1024.00M  used = 0.56M  free = 1023.44M  (encrypted)
> PhysMem: 15G used (2429M wired, 4652M compressor), 469M unused.
```

#### Key Observations - Memory Analysis

- **Total Memory**: 16GB physical RAM
- **Page Size**: 16KB pages (larger than typical 4KB on Intel systems)
- **Memory Pressure**: High usage with 15GB used, only 469MB unused
- **Compression Active**: 4.65GB in compressor, 306MB compressed pages occupied
- **Wired Memory**: 2.4GB wired
- **Swap Usage**: Minimal swap usage (0.56MB used of 1024MB available)
- **Memory Efficiency**: Heavy compression usage indicates memory pressure management

### Answer: "What is the top memory-consuming process?"

Based on the process forensics analysis, **Terminal application** is the top memory-consuming process with **3.2% memory usage** and **102.1% CPU usage**.

### Resource Utilization Patterns Observed

Most of them already provided above, but here is some more

#### Critical Patterns

**CPU Saturation**: Multiple processes exceeding 100% CPU (multi-core utilization)
**Long-term Stability**: 4+ day uptime despite heavy resource usage
**Development Workload**: High Terminal and development tool usage
**Background Services**: Multiple Apple services running but using minimal resources  
**Positive**: Minimal swap usage, system stability, clean service management
**Concerning**: Extremely high load averages, heavy memory pressure, CPU saturation
**Memory Compression**: macOS efficiently managing memory pressure through compression
**Service Management**: launchd effectively managing 1043 services
**Resource Allocation**: System maintaining stability despite resource constraints

## Task 2

### 2.1: Network Path Tracing

#### Traceroute Execution

Commands:

```bash
traceroute github.com
```

Output:

```bash
traceroute to github.com (140.82.121.3), 64 hops max, 40 byte packets
 1  10.91.48.1 (10.91.48.1)  3.814 ms  3.559 ms  3.541 ms
 2  10.252.6.1 (10.252.6.1)  3.843 ms  3.782 ms  3.677 ms
 3  1.123.18.84.in-addr.arpa (84.18.123.1)  13.361 ms  13.106 ms  12.784 ms
 4  178.176.191.24 (178.176.191.24)  8.812 ms  8.813 ms  8.769 ms
 5  * * *
 6  * * *
 7  * * *
 8  * * *
 9  83.169.204.78 (83.169.204.78)  46.477 ms
    83.169.204.82 (83.169.204.82)  50.695 ms
    83.169.204.78 (83.169.204.78)  49.503 ms
10  netnod-ix-ge-b-sth-1500.inter.link (194.68.128.180)  44.138 ms
    netnod-ix-ge-a-sth-1500.inter.link (194.68.123.180)  44.049 ms
    netnod-ix-ge-b-sth-1500.inter.link (194.68.128.180)  47.325 ms
11  r4-ber1-de.as5405.net (94.103.180.3)  60.473 ms  168.431 ms  112.063 ms
12  r3-ber1-de.as5405.net (94.103.180.2)  147.083 ms  125.743 ms  128.882 ms
13  * * *
14  * * *
...
```

#### DNS Resolution Check

Commands:

```bash
dig github.com
```

Output:

```bash
; <<>> DiG 9.10.6 <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 7178
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;github.com.			IN	A

;; ANSWER SECTION:
github.com.		27	IN	A	140.82.121.3

;; Query time: 7 msec
;; SERVER: 10.90.137.30#53(10.90.137.30)
;; WHEN: Tue Sep 23 02:17:08 MSK 2025
;; MSG SIZE  rcvd: 55
```

### 2.2: Packet Capture

#### Capture DNS Traffic

Commands (macOS doesn't have `timeout`, using alternatives):

```bash
sudo tcpdump -c 5 -i any 'port 53' -nn
```

Output:

```bash
tcpdump: data link type PKTAP
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type PKTAP (Apple DLT_PKTAP), snapshot length 524288 bytes
02:34:30.514304 IP 10.91.57.238.50988 > 10.90.137.30.53: 10576+ PTR? 18.235.33.3.in-addr.arpa. (42)
02:34:30.712793 IP 10.90.137.30.53 > 10.91.57.238.50988: 10576 1/0/0 PTR aa1ba9bef7b18c265.awsglobalaccelerator.com. (98)
02:34:35.518552 IP 10.91.57.238.51332 > 10.90.137.30.53: 5506+ PTR? 138.146.57.17.in-addr.arpa. (44)
02:34:35.676655 IP 10.90.137.30.53 > 10.91.57.238.51332: 5506 NXDomain 0/1/0 (122)
02:34:45.518434 IP 10.91.57.238.51456 > 10.90.137.30.53: 29446+ PTR? 100.192.105.91.in-addr.arpa. (45)
5 packets captured
972 packets received by filter
0 packets dropped by kernel
```

### 2.3: Reverse DNS

#### Perform PTR Lookups

Commands:

```bash
dig -x 8.8.4.4
dig -x 1.1.2.2
```

Output:

```bash
; <<>> DiG 9.10.6 <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29511
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.		IN	PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.	4036	IN	PTR	dns.google.

;; Query time: 36 msec
;; SERVER: 10.90.137.30#53(10.90.137.30)
;; WHEN: Tue Sep 23 02:35:13 MSK 2025
;; MSG SIZE  rcvd: 73


; <<>> DiG 9.10.6 <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 52105
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.		IN	PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.		899	IN	SOA	ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 22947 7200 1800 604800 3600

;; Query time: 395 msec
;; SERVER: 10.90.137.30#53(10.90.137.30)
;; WHEN: Tue Sep 23 02:35:13 MSK 2025
;; MSG SIZE  rcvd: 137
```

### Insights on Network Paths Discovered

#### Network Path Analysis (from traceroute github.com)

- **Target Resolution**: github.com resolves to 140.82.121.3 (GitHub's server)
- **Local Gateway**: First hop through 10.91.48.1 (local router) with ~3.5ms latency
- **ISP Infrastructure**: Second hop 10.252.6.1 (ISP internal routing) with ~3.7ms latency
- **Geographic Routing**: Path goes through European infrastructure:
  - Hop 3: 84.18.123.1 (reverse DNS shows in-addr.arpa domain) - 13ms
  - Hop 4: 178.176.191.24 (likely ISP backbone) - 8.8ms
  - Hops 5-8: Hidden routers (*** responses) - security filtering
  - Hop 9: 83.169.204.78/82 (load balancing between two routes) - 46-50ms
  - Hop 10: netnod-ix-ge-sth-1500.inter.link (Stockholm Internet Exchange) - 44-47ms
  - Hops 11-12: r4/r3-ber1-de.as5405.net (Berlin, Germany AS5405 network) - 60-168ms
- **Network Latency Pattern**: Progressive increase from 3ms (local) to 168ms (international)
- **Infrastructure**: Route passes through Stockholm Internet Exchange and Berlin before reaching GitHub
- **Load Balancing**: Multiple IP addresses at hop 9 and 10 show traffic distribution

### Analysis of DNS Query/Response Patterns

#### DNS Performance Analysis

- **Primary DNS Server**: 10.90.137.30 (local/corporate DNS server)
- **Query Response Time**: Fast resolution (7ms for github.com, 36ms for Google DNS reverse lookup)
- **DNS Caching**: TTL values show efficient caching (27 seconds for github.com, 4036 seconds for Google DNS)
- **Query Types**: Mix of A record lookups and PTR (reverse) queries captured

### Comparison of Reverse Lookup Results

#### Reverse DNS Analysis

**Successful Lookup (8.8.4.4)**:

- **Result**: dns.google. (Google's public DNS)
- **Response Time**: 36ms (reasonable response time)
- **TTL**: 4,036 seconds (~67 minutes) - moderate caching period
- **Status**: NOERROR - proper reverse DNS configuration

**Failed Lookup (1.1.2.2)**:

- **Result**: NXDOMAIN (no reverse record exists)
- **Response Time**: 395ms (much slower due to authoritative server query)
- **Authority**: ns.apnic.net (APNIC manages this IP range)
- **Status**: No PTR record configured for this IP
- **SOA Record**: Shows zone authority information

**Differences**:

- Google maintains proper reverse DNS records (dns.google.)
- IP 1.1.2.2 lacks reverse DNS configuration (NXDOMAIN)
- Response times vary dramatically (36ms vs 395ms)
- Failed lookups require querying authoritative servers (APNIC)
- Successful lookups cached much longer than failed ones

### One Example DNS Query from Packet Capture

#### Sample DNS Transaction

```bash
10.91.57.238.50988 > 10.90.137.30.53: 10576+ PTR? 18.235.33.3.in-addr.arpa. (42) # request
10.90.137.30.53 > 10.91.57.238.50988: 10576 1/0/0 PTR aa1ba9bef7b18c265.awsglobalaccelerator.com. (98) # response
```

**Details**:

- **Query ID**: 10576 (matches request/response)
- **Query Type**: PTR record (reverse DNS lookup)
- **Source Port**: 50988
- **Response**: AWS Global Accelerator hostname
- **Packet Sizes**: 42 bytes query, 98 bytes response
- **Resolution Time**: ~198ms (02:34:30.514304 to 02:34:30.712793)
- **Local DNS**: Using internal DNS server (10.90.137.30)
