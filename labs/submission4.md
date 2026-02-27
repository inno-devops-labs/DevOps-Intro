**Note: i used macOS so some command aren't exactly as in the lab, but adapted to macOS.**

## Task 1
- Command: `sysctl -n kern.boottime`
- Output: `{ sec = 1771478757, usec = 123070 } Thu Feb 19 08:25:57 2026`

- Command: `w`
- Output:
```
21:52  up 8 days, 13:27, 1 user, load averages: 3.10 3.12 3.44
USER       TTY      FROM    LOGIN@  IDLE WHAT
vladpaskal console  -      19Feb26 8days -
```
	
- Command: `ps -aceo pid,ppid,command,%mem,%cpu -r | head -n 6` and `ps -aceo pid,ppid,command,%mem,%cpu -r | head -n 6`(output the same)
- Output: 
```
  PID  PPID COMMAND          %MEM  %CPU
83617     1 idea             14.6 203.7
 1417     1 git               0.3 132.4
  852   789 osqueryd          0.2  77.2
  651     1 WindowServer      0.4  14.0
 1601  1506 Note Helper (R  1.2  11.4
```

- Command: `launchctl list | head -n 10 `
- Output: 
```
PID     Status  Label
-       0       com.apple.SafariHistoryServiceAgent
-       0       com.apple.progressd
-       0       com.apple.enhancedloggingd
1595    0       com.apple.cloudphotod
1116    0       com.apple.MENotificationService
942     0       com.apple.Finder
1073    0       com.apple.homed
1540    0       com.apple.dataaccess.dataaccessd
-       0       com.apple.quicklook
```

- Command: `who -a last -n 5`
- Output: 
```
                 system boot  Feb 19 08:25 
vladpaskal       console      Feb 19 08:58 
vladpaskal       ttys000      Feb 19 08:58      term=0 exit=0
vladpaskal       ttys001      Feb 19 23:42      term=0 exit=0
vladpaskal       ttys002      Feb 20 14:13      term=0 exit=0
   .       run-level 3
vladpaskal ttys002                         Fri Feb 20 14:13 - 14:13  (00:00)
vladpaskal ttys001                         Thu Feb 19 23:42 - 23:42  (00:00)
vladpaskal ttys001                         Thu Feb 19 23:38 - 23:38  (00:00)
vladpaskal ttys000                         Thu Feb 19 08:58 - 08:58  (00:00)
vladpaskal console                         Thu Feb 19 08:58   still logged in
```

- Command: `top -l 1 | grep PhysMem`
- Output: 
```
PhysMem: 35G used (3384M wired, 9391M compressor), 578M unused.
```

- Command: `sysctl hw.memsize`
- Output: `hw.memsize: 38654705664`

These are very basic commands to inspect your system info.
The most memory-consuming process is the IntelliJ IDEA(not suprizing)

## Task 2

- Command: ` traceroute github.com`
- Output: 
```
 1  192.168.121.219 (192.168.121.219)  5.884 ms  4.671 ms  4.673 ms
 2  10.241.246.66 (10.241.246.66)  43.637 ms *
    10.241.247.66 (10.241.247.66)  35.677 ms
 3  * * *
 4  10.241.255.51 (10.241.255.51)  33.637 ms  34.812 ms  66.087 ms
 5  * * *
 6  * * *
 7  * 172.25.242.32 (172.25.242.32)  1626.106 ms  203.374 ms
 8  172.25.129.175 (172.25.129.175)  85.614 ms
    172.25.129.173 (172.25.129.173)  46.277 ms  25.986 ms
 9  188.170.162.14 (188.170.162.14)  44.499 ms  56.395 ms
    telia.msk.cloud-ix.net (31.28.19.184)  31.580 ms
10  83.169.204.65 (83.169.204.65)  59.676 ms
    sto-bb1-link.ip.twelve99.net (62.115.143.24)  91.488 ms
    83.169.204.65 (83.169.204.65)  64.548 ms
....
```

- Command: `dig github.com`
- Output: 
```
; <<>> DiG 9.10.6 <<>> github.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49048
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             44      IN      A       140.82.121.4

;; Query time: 34 msec
;; SERVER: 192.168.121.219#53(192.168.121.219)
```

- Command: ` sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn`
- Output: 
```
 sudo timeout 10 tcpdump -c 5 -i any 'port 53' -nn
Password:
tcpdump: data link type PKTAP
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type PKTAP (Apple DLT_PKTAP), snapshot length 524288 bytes
22:07:32.893952 IP 192.168.121.17.59299 > 192.168.121.219.53: 38375+ AAAA? google.com. (40)
22:07:32.894054 IP 192.168.121.17.59299 > 192.168.121.219.53: 49030+ A? google.com. (40)
22:07:32.913046 IP 192.168.121.219.53 > 192.168.121.17.59299: 38375 1/0/0 AAAA 1b03:2b9:0:3400:0:c72:5:0 (68)
22:07:32.913050 IP 192.168.121.219.53 > 192.168.121.17.59299: 49030 1/0/0 A 212.90.105.117 (56)
22:07:33.926307 IP 192.168.121.17.52773 > 192.168.121.219.53: 1126+ AAAA? google.com. (40)
5 packets captured
469 packets received by filter
```

- Command: `dig -x 8.8.4.4 dig -x 1.1.2.2`
- Output: 
```
dig -x 1.1.2.2

; <<>> DiG 9.10.6 <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 50297
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   38430   IN      PTR     dns.google.

;; Query time: 55 msec
;; SERVER: 192.168.121.219#53(192.168.121.219)
;; WHEN: Fri Feb 27 22:09:19 MSK 2026
;; MSG SIZE  rcvd: 73


; <<>> DiG 9.10.6 <<>> -x 1.1.2.2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 43905
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;2.2.1.1.in-addr.arpa.          IN      PTR

;; AUTHORITY SECTION:
1.in-addr.arpa.         3400    IN      SOA     ns.apnic.net. read-txt-record-of-zone-first-dns-admin.apnic.net. 23597 7200 1800 604800 3600

;; Query time: 227 msec
;; SERVER: 192.168.121.219#53(192.168.121.219)
;; WHEN: Fri Feb 27 22:09:19 MSK 2026
;; MSG SIZE  rcvd: 137
```
The traceroute output shows the sequence of routers (hops) between my local machine and GitHub's servers. As the hop count increases, the time (ms) generally increases as the physical distance to the server grows..

The dig command queried my configured nameserver. The ANSWER SECTION returns the A record (IPv4), resolving github.com to the specific IP addres.

Both lookups query the in-addr.arpa domain, which is the standard DNS namespace for mapping IPs back to hostnames (PTR records).

