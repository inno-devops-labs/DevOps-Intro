# Lab 4 Submssion

## Task 1

### Request sent using curl output

```bash
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
Note: Unnecessary use of -X or --request, POST is already inferred.
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> POST /notes HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.5.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 39
>
< HTTP/1.1 201 Created
< Content-Type: application/json
< Date: Tue, 16 Jun 2026 20:56:10 GMT
< Content-Length: 93
<
{"id":13,"title":"trace me","body":"in flight","created_at":"2026-06-16T20:56:10.22009407Z"}
* Connection #0 to host localhost left intact
```

### TCP Three-Way Handshake

#### SYN (Client → Server)

```text
23:56:10.219563 IP6 ::1.46764 > ::1.8080: Flags [S]
```

The client initiates a new TCP connection to QuickNotes on port 8080 by sending a SYN packet.

#### SYN/ACK (Server → Client)

```text
23:56:10.219591 IP6 ::1.8080 > ::1.46764: Flags [S.]
```

QuickNotes acknowledges the SYN and sends its own SYN to establish the connection.

#### ACK (Client → Server)

```text
23:56:10.219608 IP6 ::1.46764 > ::1.8080: Flags [.]
```

The client acknowledges the server's SYN/ACK, completing the TCP three-way handshake.

---

### HTTP Request

```text
23:56:10.219675 IP6 ::1.46764 > ::1.8080: Flags [P.]
```

Request line:

```http
POST /notes HTTP/1.1
```

Headers:

```http
Host: localhost:8080
User-Agent: curl/8.5.0
Accept: */*
Content-Type: application/json
Content-Length: 39
```

JSON request body:

```json
{"title":"trace me","body":"in flight"}
```

The client sends a POST request to create a new note in QuickNotes.

---

### HTTP Response

```text
23:56:10.225582 IP6 ::1.8080 > ::1.46764: Flags [P.]
```

Response line:

```http
HTTP/1.1 201 Created
```

Headers:

```http
Content-Type: application/json
Date: Tue, 16 Jun 2026 20:56:10 GMT
Content-Length: 93
```

Response body:

```json
{"id":13,"title":"trace me","body":"in flight","created_at":"2026-06-16T20:56:10.22009407Z"}
```

The server successfully created the note and returned its details.

---

### Connection Close

Client initiates connection termination:

```text
23:56:10.225771 IP6 ::1.46764 > ::1.8080: Flags [F.]
```

Server acknowledges and closes its side:

```text
23:56:10.225826 IP6 ::1.8080 > ::1.46764: Flags [F.]
```

Final acknowledgement:

```text
23:56:10.225840 IP6 ::1.46764 > ::1.8080: Flags [.]
```

This is a normal TCP connection shutdown using FIN packets.

---

### Task 1.3: Debugging Commands Outputs

#### 1. What is listening on port 8080?

```bash
LISTEN 0      4096                *:8080            *:*    users:(("quicknotes",pid=4490,fd=3))
````

QuickNotes is actively listening for incoming TCP connections on port 8080.

### 2. Routing Table

```bash
default via 172.20.96.1 dev eth0 proto kernel
172.20.96.0/20 dev eth0 proto kernel scope link src 172.20.99.213
```

The default route sends external traffic through the gateway 172.20.96.1 using interface eth0.

#### 3. Reachability Test

```bash
Start: 2026-06-16T23:59:48+0300
HOST: GhadeerPC Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.0   0.1   0.0   0.2   0.1
```

The localhost interface is reachable with zero packet loss and negligible latency.

#### 4. DNS Resolution

```bash
104.20.23.154
172.66.147.243
```

The DNS query successfully resolved example.com using Cloudflare's DNS server (1.1.1.1).

#### 5. Journal Logs

```bash
-- No entries --
```

No user systemd service named quicknotes is currently installed or generating logs.

---

### What would you check first if QuickNotes returned 502?

A 502 Bad Gateway error usually indicates that a reverse proxy (such as Nginx, Traefik, or a load balancer) cannot successfully communicate with the backend application. The first thing I would check is whether QuickNotes is actually running and listening on port 8080 using `ss -tlnp`. If the service is running, I would inspect the application logs using `journalctl` and verify connectivity by sending a direct request with `curl http://localhost:8080`. Finally, I would review the reverse proxy configuration to ensure it is forwarding traffic to the correct backend address and port.

---

## Task 2

### 2.1 Run a Broken Instance

First instance:

```bash
ADDR=:8080 go run . &
```

Output:

```text
2026/06/17 00:22:13 quicknotes listening on :8080 (notes loaded: 13)
```

Verification:

```bash
ss -tlnp | grep 8080
```

Output:

```text
LISTEN 0      4096                *:8080            *:*    users:(("quicknotes",pid=4798,fd=3))
```

Second instance:

```bash
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &
```

Output:

```text
2026/06/17 00:24:02 quicknotes listening on :8080 (notes loaded: 13)
2026/06/17 00:24:02 listen: listen tcp :8080: bind: address already in use
exit status 1
```

Captured log:

```bash
cat /tmp/qn-broken.log
```

Output:

```text
2026/06/17 00:24:02 quicknotes listening on :8080 (notes loaded: 13)
2026/06/17 00:24:02 listen: listen tcp :8080: bind: address already in use
exit status 1
```

The second QuickNotes instance failed because TCP port 8080 was already occupied by the first instance.

---

### 2.2 Outside-In Debugging Chain

#### Step 1 – Is it running?

Command:

```bash
ps -ef | grep quicknotes
```

Output:

```text
g-akleh     4798    4756  0 00:22 pts/4    00:00:00 /home/g-akleh/.cache/go-build/9b/9bbbd37722f22fffcda19af5517656fc0a2a84b1503acf25c0c91e18e44b337b-d/quicknotes
g-akleh     4860    4623  0 00:26 pts/4    00:00:00 grep --color=auto quicknotes
```

Decision:

A QuickNotes process is running, indicating that the service itself has not completely failed.

---

#### Step 2 – Is it listening?

Command:

```bash
ss -tlnp | grep 8080
```

Output:

```text
LISTEN 0      4096                *:8080            *:*    users:(("quicknotes",pid=4798,fd=3))
```

Decision:

QuickNotes is successfully listening on TCP port 8080.

---

#### Step 3 – Is it reachable?

Command:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
```

Output:

```text
200
```

Decision:

The application is reachable and responding successfully to requests.

---

#### Step 4 – Is a firewall blocking access?

Command:

```bash
sudo iptables -L -n -v 2>/dev/null || sudo nft list ruleset 2>/dev/null || true
```

Output:

```text
(no firewall rules affecting port 8080 were outputted)
```

Decision:

There is no evidence that a firewall is preventing access to the service. I'm assuming this is because I'm using WSL.

---

#### Step 5 – Does DNS work?

Command:

```bash
dig +short localhost
```

Output:

```text
127.0.0.1
```

Decision:

DNS resolution is functioning correctly and localhost resolves to the local machine.

---

### Root Cause Analysis

Error outputted:

```text
2026/06/17 00:24:02 listen: listen tcp :8080: bind: address already in use
exit status 1
```

The debugging process showed that:

- QuickNotes was already running.
- Port 8080 was already bound.
- The application was reachable.
- No firewall issues were present.
- DNS resolution was functioning normally.

Therefore, the root cause was a port conflict: the second QuickNotes instance attempted to bind to port 8080 while it was already being used by the first instance.

---

### 2.3 Repair and Re-Verification

The conflicting instance was terminated:

```bash
kill $PID1
```

After restarting QuickNotes, the application was verified using:

```bash
curl -s http://localhost:8080/health
```

Output:

```json
{"notes":13,"status":"ok"}
```

Verification confirmed that the application was running normally and responding successfully after the conflicting process was removed.

---

### Mini Postmortem

This incident was caused by a port conflict rather than a problem in the application itself. The second QuickNotes instance tried to bind to TCP port 8080 while that port was already in use by another running process. Failures of this type are common during deployments, service restarts, local development, and configuration changes. The issue is that multiple processes were configured to use the same network resource without coordination. To reduce the possibility of this failure, teams can use service managers such as systemd, container orchestration platforms, startup validation checks, monitoring systems, and deployment automation that verifies port availability before launching a new instance. These controls help detect configuration conflicts before they impact users.
