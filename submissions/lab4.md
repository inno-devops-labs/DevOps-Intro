# Lab 4 Submission — OS & Networking

## Task 1 — Trace a Request End-to-End

### Annotated Packet Capture (lab4-trace.txt)

**TCP Three-Way Handshake:**
15:56:22.941885 IP6 ::1.57714 > ::1.8080: Flags [S] - SYN (Client -> Server)
15:56:22.941913 IP6 ::1.8080 > ::1.57714: Flags [S.] - SYN-ACK (Server -> Client)
15:56:22.941931 IP6 ::1.57714 > ::1.8080: Flags [.] - ACK (Client -> Server)

**HTTP Request (Line + JSON Body):**
15:56:22.942066 IP6 ::1.57714 > ::1.8080: Flags [P.], length 175: HTTP: POST /notes HTTP/1.1

POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.19.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}

**HTTP Response (Line + JSON Body):**
15:56:22.943777 IP6 ::1.8080 > ::1.57714: Flags [P.], length 206: HTTP: HTTP/1.1 201 Created

HTTP/1.1 201 Created
Content-Type: application/json
Date: Thu, 11 Jun 2026 12:56:22 GMT
Content-Length: 93

{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-11T12:56:22.943276588Z"}

**Connection Close (FIN packets):**
15:56:22.944001 IP6 ::1.57714 > ::1.8080: Flags [F.] - FIN from client
15:56:22.944146 IP6 ::1.8080 > ::1.57714: Flags [F.] - FIN from server
15:56:22.944182 IP6 ::1.57714 > ::1.8080: Flags [.] - Final ACK

### Five Debugging Commands Output

#### Command 1: `ss -tlnp | grep :8080`
```bash
LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=198320,fd=3))
Interpretation: quicknotes process (PID 198320) is listening on port 8080 on all interfaces (*).

#### Command 2: `ip route show`
default via 10.128.0.1 dev wlo1 proto static metric 600 
10.128.0.0/24 dev wlo1 proto kernel scope link src 10.128.0.77 metric 600 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.18.0.0/16 dev br-2a47d25b8db2 proto kernel scope link src 172.18.0.1 linkdown
Interpretation: Default route goes through 10.128.0.1 on wlo1 interface. Docker networks present but linkdown.

#### Command 3: `mtr -rwc 5 localhost`
Start: 2026-06-11T16:00:14+0300
HOST: ksu       Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.1   0.1   0.1   0.1   0.0
Interpretation: localhost reachable with 0% packet loss, 0.1ms average latency.

#### Command 4: `dig +short example.com @1.1.1.1`
8.6.112.0
8.47.69.0
Interpretation: DNS resolution works. example.com resolves to IP addresses via Cloudflare DNS (1.1.1.1).

#### Command 5: `journalctl --user -u quicknotes -n 20 || true`

```bash
journalctl: command not found 
Interpretation: journalctl not available on this system. QuickNotes not installed as systemd service.

####502 Error Debugging Reflection

What would I check first if QuickNotes returned 502?

The first thing I would check is whether the QuickNotes process is actually running and listening on port 8080 using ss -tlnp | grep 8080.

A 502 Bad Gateway error indicates that a reverse proxy (like nginx, Caddy, or a load balancer) received an invalid response from the upstream server (QuickNotes). Unlike a 504 timeout, a 502 means the proxy could connect to the upstream server, but the response was malformed, empty, or an error.
	
My debugging chain would be:

1. ss -tlnp | grep 8080 - Is anything listening on port 8080?

2. ps aux | grep quicknotes - Is the process still running?

3. curl http://localhost:8080/health - Can I reach it directly?

4.  Check QuickNotes application logs for crashes or panics

5.  Check reverse proxy error logs

The most common cause of 502 in development is that the application crashed or was never started. The ss command immediately tells me if the port is open and which process owns it.




## Task 2 — Outside-In Debugging on a Broken Deploy

### Full Outside-In Chain

**Step 1: Check if process is running**
```bash
$ ps -ef | grep quicknotes | grep -v grep
ksu       243640  243594  0 16:17 pts/1    00:00:00 /home/ksu/.cache/go-build/.../quicknotes
Result: Process found. PID 243640 is running.

**Result: Process found. PID 243640 is running.
$ ss -tlnp | grep 8080
LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=243640,fd=3))
Result: Port 8080 is LISTENING. Process PID 243640 owns it.

**Step 3: Check if service is reachable
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
Result: Service returns HTTP 200 OK.

**Step 4: Check firewall
$ sudo iptables -L -n
iptables not available
Result: No firewall blocking.

**Step 5: Check DNS resolution
$ dig +short localhost
127.0.0.1
Result: localhost resolves to 127.0.0.1 correctly.


Root Cause
bind: address already in use
Two instances tried to use port 8080 at the same time. First instance got the port. Second instance failed to bind.

### Mini-Postmortem

Two QuickNotes processes tried to bind to port 8080 at the same time. The first process got the port and started normally. The second process crashed with error "bind: >

The systemic issue is lack of coordination between processes for port allocation. Each process assumes port 8080 is free and tries to bind immediately without checking >

Tooling that could prevent this failure: a process supervisor like systemd would run only one instance of the service. A pre-flight check using `lsof -i :8080` would de>

This failure is not the operator's fault. Starting two processes should not crash. The system should handle port conflicts in a graceful way.



## Bonus Task — TLS Handshake Decode

### ClientHello
From curl output:
TLSv1.3 (OUT), TLS handshake, Client hello (1):

ALPN: curl offers h2,http/1.1

### ServerHello
TLSv1.3 (IN), TLS handshake, Server hello (2):

TLSv1.3 (IN), TLS handshake, Certificate (11):

SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256

### Certificate Chain
openssl s_client -connect localhost:8443 -showcerts

Certificate level 0: Public key EC/prime256v1
Certificate level 1: CN=Caddy Local Authority - ECC Intermediate

### Which negotiation step kills TLS 1.0/1.1 in 2026?

The ServerHello step kills TLS 1.0 and 1.1. Client sends ClientHello with supported versions including old ones. Server checks its configuration, sees TLS 1.0/1.1 disabled, and responds with ServerHello using TLS 1.2 or 1.3. If client only supports old versions, server sends fatal alert "protocol_version". Caddy with tls internal uses TLS 1.3 by default, so older versions never appear in handshake.
