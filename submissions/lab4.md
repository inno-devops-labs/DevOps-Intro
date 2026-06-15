# Lab 4 submission
### HTTP POST Trace
1) TCP Handshake (SYN -> SYN,ACK -> ACK):
```
17:52:49.575507 IP6 ::1.35770 > ::1.8080: Flags [S], seq 2010941407, win 65476, options [mss 65476,sackOK,TS val 1765851937 ecr 0,nop,wscale 7], length 0
`..7.(.@....................................w............0.........
i@.!........
17:52:49.575523 IP6 ::1.8080 > ::1.35770: Flags [S.], seq 4030657036, ack 2010941408, win 65464, options [mss 65476,sackOK,TS val 1765851937 ecr 1765851937,nop,wscale 7], length 0
`....(.@.....................................>..w........0.........
i@.!i@.!....
17:52:49.575533 IP6 ::1.35770 > ::1.8080: Flags [.], ack 1, win 512, options [nop,nop,TS val 1765851937 ecr 1765851937], length 0
`..7. .@....................................w....>.......(.....
i@.!i@.!
```
2) HTTP Request + (HTTP POST -> Server ACK):
```
17:52:49.575584 IP6 ::1.35770 > ::1.8080: Flags [P.], seq 1:176, ack 1, win 512, options [nop,nop,TS val 1765851937 ecr 1765851937], length 175: HTTP: POST /notes HTTP/1.1
`..7...@....................................w....>.............
i@.!i@.!POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.17.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
17:52:49.575588 IP6 ::1.8080 > ::1.35770: Flags [.], ack 176, win 511, options [nop,nop,TS val 1765851937 ecr 1765851937], length 0
`.... .@.....................................>..w........(.....
i@.!i@.!
```
3) HTTP Response (HTTP 201 -> Client ACK):
```
17:52:49.575953 IP6 ::1.8080 > ::1.35770: Flags [P.], seq 1:207, ack 176, win 512, options [nop,nop,TS val 1765851938 ecr 1765851937], length 206: HTTP: HTTP/1.1 201 Created
`......@.....................................>..w..............
i@."i@.!HTTP/1.1 201 Created
Content-Type: application/json
Date: Mon, 15 Jun 2026 14:52:49 GMT
Content-Length: 93

{"id":8,"title":"trace me","body":"in flight","created_at":"2026-06-15T14:52:49.575715863Z"}

17:52:49.575962 IP6 ::1.35770 > ::1.8080: Flags [.], ack 207, win 511, options [nop,nop,TS val 1765851938 ecr 1765851938], length 0
`..7. .@....................................w....>.......(.....
i@."i@."
```
4) Connection close (FIN->FIN,ACK->ACK)
```
17:52:49.576000 IP6 ::1.35770 > ::1.8080: Flags [F.], seq 176, ack 207, win 512, options [nop,nop,TS val 1765851938 ecr 1765851938], length 0
`..7. .@....................................w....>.......(.....
i@."i@."
17:52:49.576022 IP6 ::1.8080 > ::1.35770: Flags [F.], seq 207, ack 177, win 512, options [nop,nop,TS val 1765851938 ecr 1765851938], length 0
`.... .@.....................................>..w........(.....
i@."i@."
17:52:49.576040 IP6 ::1.35770 > ::1.8080: Flags [.], ack 208, win 512, options [nop,nop,TS val 1765851938 ecr 1765851938], length 0
`..7. .@....................................w....>.......(.....
i@."i@."
```

### Debugging commands outputs
```sh
$ ss -tlnp | grep :8080
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=107145,fd=3))
```
```sh
$ ip route show
default via 192.168.1.1 dev wlp9s0 proto dhcp src 192.168.1.4 metric 600
10.16.0.0/24 dev wg0 proto static scope link metric 50
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
172.18.0.0/16 dev br-e489b6d6a3db proto kernel scope link src 172.18.0.1 linkdown
192.168.1.0/24 dev wlp9s0 proto kernel scope link src 192.168.1.4 metric 600
```
```sh
$ mtr -rwc 5 localhost
Start: 2026-06-15T19:27:16+0300
HOST: workstation Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost    0.0%     5    0.1   0.1   0.0   0.1   0.0
```
```sh
$ dig +short example.com @1.1.1.1
8.6.112.0
8.47.69.0
```
```sh
$ journalctl --user -u quicknotes -n 20 || true
-- No entries --
```

### _What would you check first if QuickNotes returned 502?_
Since a 502 Bad Gateway error inherently indicates a communication failure between a gateway/proxy and an upstream application server, my first step would be to verify the architecture, as QuickNotes is not currently configured behind a reverse proxy or load balancer. However, assuming a proxy like Nginx were introduced, a 502 means the proxy cannot reach the application, prompting me to immediately check the Nginx error logs to isolate the root cause. If the logs show a DNS resolution failure, I would verify the container's existence and use `dig` to check service discovery; if it indicates Destination Host Unreachable, I would investigate VPN routing and `iptables` firewall rules; and if it registers a Connection Refused, I would use `ss -tlnp` (or inspect the container's network namespace) to ensure the QuickNotes process is actually running and listening on the correct port.