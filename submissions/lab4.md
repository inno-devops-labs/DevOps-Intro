# Lab 4 submission

### TCP Handshake (SYN -> SYN,ACK -> ACK):

```
22:33:46.570258 IP6 ::1.52782 > ::1.8080: Flags [S], seq 284201099, win 65476, options [mss 65476,sackOK,TS val 2276206117 ecr 0,nop,wscale 10], length 0
`....(.@.................................................0.........
..&%.......

22:33:46.570285 IP6 ::1.8080 > ::1.52782: Flags [S.], seq 2388979400, ack 284201100, win 65464, options [mss 65476,sackOK,TS val 2618398189 ecr 2276206117,nop,wscale 10], length 0
`
.'.(.@.....................................d...........0.........
......&%...

22:33:46.570305 IP6 ::1.52782 > ::1.8080: Flags [.], ack 1, win 64, options [nop,nop,TS val 2276206117 ecr 2618398189], length 0
`.... .@.........................................d.....@.(.....
..&%....
```

### HTTP Request + (HTTP POST -> Server ACK):

```
22:33:46.570448 IP6 ::1.52782 > ::1.8080: Flags [P.], seq 1:176, ack 1, win 64, options [nop,nop,TS val 2276206117 ecr 2618398189], length 175: HTTP: POST /notes HTTP/1.1
`......@.........................................d.....@.......
..&%....POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.20.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
22:33:46.570462 IP6 ::1.8080 > ::1.52782: Flags [.], ack 176, win 64, options [nop,nop,TS val 2618398189 ecr 2276206117], length 0
`
.'. .@.....................................d.....;...@.(.....
......&%
22:33:46.570917 IP6 ::1.8080 > ::1.52782: Flags [P.], seq 1:207, ack 176, win 64, options [nop,nop,TS val 2618398190 ecr 2276206117], length 206: HTTP: HTTP/1.1 201 Created
`
.'...@.....................................d.....;...@.......
......&%HTTP/1.1 201 Created
Content-Type: application/json
Date: Tue, 16 Jun 2026 19:33:46 GMT
Content-Length: 93

{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T19:33:46.570565538Z"}
```

### Connection close (FIN->FIN,ACK->ACK)
```
22:33:46.570930 IP6 ::1.52782 > ::1.8080: Flags [.], ack 207, win 64, options [nop,nop,TS val 2276206118 ecr 2618398190], length 0
`.... .@.......................................;.d.....@.(.....
..&&....
22:33:46.571020 IP6 ::1.52782 > ::1.8080: Flags [F.], seq 176, ack 207, win 64, options [nop,nop,TS val 2276206118 ecr 2618398190], length 0
`.... .@.......................................;.d.....@.(.....
..&&....
22:33:46.571050 IP6 ::1.8080 > ::1.52782: Flags [F.], seq 207, ack 177, win 64, options [nop,nop,TS val 2618398190 ecr 2276206118], length 0
`
.'. .@.....................................d.....<...@.(.....
......&&
22:33:46.571067 IP6 ::1.52782 > ::1.8080: Flags [.], ack 208, win 64, options [nop,nop,TS val 2276206118 ecr 2618398190], length 0
`.... .@.......................................<.d.....@.(.....
..&&....
```

## Debug commands

```
$ ss -tlnp   | grep :8080
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=12601,fd=3))
```

```
$ ip route show  
0.0.0.0/1 dev amn0 metric 1 
default via 192.168.0.1 dev eno1 proto dhcp src 192.168.0.100 metric 1002 
default via 10.91.80.1 dev wlan0 proto dhcp src 10.91.86.43 metric 3004 
10.91.80.0/20 dev wlan0 proto dhcp scope link src 10.91.86.43 metric 3004 
31.172.78.99 via 192.168.0.1 dev eno1 
128.0.0.0/1 dev amn0 metric 1 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.18.0.0/16 dev br-bcc608ebbdf4 proto kernel scope link src 172.18.0.1 linkdown 
172.19.0.0/16 dev br-2f04123ec594 proto kernel scope link src 172.19.0.1 linkdown 
172.20.0.0/16 dev br-204ddeb962fd proto kernel scope link src 172.20.0.1 linkdown 
172.21.0.0/16 dev br-507a46b4b473 proto kernel scope link src 172.21.0.1 linkdown 
185.27.192.209 via 192.168.0.1 dev eno1 
188.130.155.215 via 192.168.0.1 dev eno1 
188.130.155.243 via 192.168.0.1 dev eno1 
188.130.155.250 via 192.168.0.1 dev eno1 
192.168.0.0/24 dev eno1 proto dhcp scope link src 192.168.0.100 metric 1002 
```

```
$ mtr -rwc 5 localhost 
Start: 2026-06-16T22:42:19+0300
HOST: Long1Tail Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.1   0.1   0.1   0.1   0.0
```

```
$ dig +short example.com @1.1.1.1
172.66.147.243
104.20.23.154
```

```
$ journalctl --user -u quicknotes -n 20 || true
-- No entries --
```

## What would I do if QuickNotes shows 502 error?

Well, firstly, i'll check logs in, for example, journalctl. Next I'll run `ss -tulpn | grep <port of my app>`, tracepath `<request to service>` and do some testing via `dig`

## Task 2

```
ps -ef | grep quicknotes
long1ta+   13357   13314  0 23:02 pts/1    00:00:00 /home/long1tail/.cache/go-build/d2/d2669b388084fca57ad8bc2e16f3aebe315b928221e2267b472e0af203e794e6-d/quicknotes
long1ta+   13440   12297  0 23:03 pts/1    00:00:00 grep --color=auto quicknotes
```

I have 2 instanses running. Let's check, wich one of them listens on port

```
ss -tlnp | grep 8080
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=13357,fd=3))
```

As we can see, PID of listenning process is the PID of first running instance. Let's check if the service is available.

```
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```

Ok, servise looks available. let's check the bariers

```
sudo iptables -L -n -v 2>/dev/null || sudo nft list ruleset 2>/dev/null || true
```
I can't provide it's output because It contains a lot of of notes about my vpn server and it may cause vurnalabilities and private data leakage

```
dig +short localhost
127.0.0.1
```

DNS is ok


Summary
I run a second QuickNotes instance on port 8080 failed because the port was already in use by the primary running instance. The deployment process does not verify whether the target port is already occupied. Since the application uses a fixed port configuration, concurrent launches can cause port conflicts.

I can prevent such problems via docker usage and running by systemd