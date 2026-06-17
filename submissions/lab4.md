# Lab 4 submission
 
# Lab 4

## Task 1 — Trace a Request End-to-End

### 1.1 Start QuickNotes and capture network traffic

I launched QuickNotes locally and verified that the application was healthy.

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ curl http://localhost:8080/health
{"notes":5,"status":"ok"}
```

I then started a packet capture on the loopback interface and generated a single HTTP request.

Packet capture:

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap
[sudo] password for p4in: 
tcpdump: listening on lo, link-type EN10MB (Ethernet), snapshot length 262144 bytes
^C10 packets captured
20 packets received by filter
0 packets dropped by kernel
```

Request:

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ curl -v -X POST http://localhost:8080/notes \
-H 'Content-Type: application/json' \
-d '{"title":"trace me","body":"in flight"}'
```

Response:
```text
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Established connection to localhost (::1 port 8080) from ::1 port 49206 
* using HTTP/1.x
> POST /notes HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.19.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 39
* upload completely sent off: 39 bytes
< HTTP/1.1 201 Created
< Content-Type: application/json
< Date: Wed, 17 Jun 2026 05:15:24 GMT
< Content-Length: 93
{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-17T05:15:24.332417621Z"}
* Connection #0 to host localhost:8080 left intact

```

The request successfully created a new note.
The packet capture was stopped manually and saved for further analysis.

---

## 1.2 Decode the capture

I decoded the capture using:

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt
```

### TCP three-way handshake

The connection was established using the standard TCP handshake.
```text
reading from file lab4-trace.pcap, link-type EN10MB (Ethernet), snapshot length 262144
01:15:24.331603 IP6 ::1.49206 > ::1.8080: Flags [S], seq 3223026168, win 65476, options [mss 65476,sackOK,TS val 2925136795 ecr 0,nop,wscale 10], length 0

01:15:24.331627 IP6 ::1.8080 > ::1.49206: Flags [S.], seq 2434689196, ack 3223026169, win 65464, options [mss 65476,sackOK,TS val 1962955010 ecr 2925136795,nop,wscale 10], length 0

01:15:24.331637 IP6 ::1.49206 > ::1.8080: Flags [.], ack 1, win 64, options [nop,nop,TS val 2925136795 ecr 1962955010], length 0
```

Corresponding sequence:
```text
SYN
SYN/ACK
ACK
```

### HTTP request

The capture contains the HTTP request line:
```text
POST /notes HTTP/1.1
```

Request body:
```json
{"title":"trace me","body":"in flight"}
```

### HTTP response

The application returned:
```text
HTTP/1.1 201 Created
```

Response body:
```json
{"id":6,"title":"trace me","body":"in flight",...}
```

### Connection close

The TCP connection was gracefully closed by both sides.
```text
01:15:24.338533 IP6 ::1.49206 > ::1.8080: Flags [F.], seq 176, ack 207, win 64, options [nop,nop,TS val 2925136802 ecr 1962955011], length 0

01:15:24.338969 IP6 ::1.8080 > ::1.49206: Flags [F.], seq 207, ack 177, win 64, options [nop,nop,TS val 1962955018 ecr 2925136802], length 0

01:15:24.338996 IP6 ::1.49206 > ::1.8080: Flags [.], ack 208, win 64, options [nop,nop,TS val 2925136803 ecr 1962955018], length 0
```
An interesting observation is that localhost resolved to the IPv6 loopback address `::1` instead of `127.0.0.1`.
---

## 1.3 Debugging commands

### 1.3.1 What is listening?

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ ss -tlnp | grep :8080
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=6124,fd=3))
```
This confirms that the QuickNotes process is listening on port 8080.

### 1.3.2 Routes from the host

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ ip route show
default via 192.168.50.1 dev eth1 proto dhcp src 192.168.50.167 metric 100 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
192.168.50.0/24 dev eth1 proto kernel scope link src 192.168.50.167 metric 100 
```
This shows the default gateway and local network routes configured on the host.

### 1.3.3 Reachability

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ mtr -rwc 5 localhost
Start: 2026-06-17T01:24:27-0400
HOST: kali      Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.0   0.0   0.0   0.1   0.0
```
The localhost endpoint is reachable without any packet loss.

### 1.3.4 DNS

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ dig +short example.com @1.1.1.1
8.6.112.0
8.47.69.0
```
This confirms that DNS resolution works correctly.

### 1.3.5 Logs

```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ journalctl --user -u quicknotes -n 20 || true
-- No entries --
```
QuickNotes was started manually rather than as a systemd service, therefore no journal entries were available.
---

## 1.4 Reflection — What would I check first if QuickNotes returned 502?

If QuickNotes returned a 502 error, I would follow an outside-in debugging approach.
First, I would verify whether the application process is running. 
Then I would check whether port 8080 is listening and whether the `/health` endpoint is reachable locally. 
After that, I would inspect firewall rules and finally verify DNS resolution. 
This approach starts from the visible symptom and gradually moves deeper into the networking stack until the root cause is identified.
