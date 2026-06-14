# Lab 4 Submission

## Task 1 — Trace a Request End-to-End

### 1.1 Request sent with curl

```bash
$ curl -v -X POST http://localhost:8080/notes \
    -H 'Content-Type: application/json' \
    -d '{"title":"trace me","body":"in flight"}'
```

#### Output

```bash
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
< Date: Sun, 14 Jun 2026 18:05:48 GMT
< Content-Length: 93
< 
{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-14T18:05:48.914358117Z"}
* Connection #0 to host localhost left intact
```

### 1.2 Decoded capture (lab4-trace.txt)
```bash
$ sudo tcpdump -r lab4-trace.pcap -nn -A
```

Below is the decoded `tcpdump` output of one complete HTTP request/response cycle.  
Each step is annotated with a comment describing the TCP and HTTP event.

```text
# ===== TCP THREE-WAY HANDSHAKE =====

21:05:48.909001 IP6 ::1.57020 > ::1.8080: Flags [S], ...
# SYN — client asks to open connection

21:05:48.910953 IP6 ::1.8080 > ::1.57020: Flags [S.], ...
# SYN-ACK — server agrees

21:05:48.911016 IP6 ::1.57020 > ::1.8080: Flags [.], ...
# ACK — handshake complete, connection established

# ===== HTTP REQUEST =====

21:05:48.913647 IP6 ::1.57020 > ::1.8080: Flags [P.], length 174: HTTP: POST /notes HTTP/1.1

POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.5.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
# Client sends HTTP POST request with JSON body

# ===== HTTP RESPONSE =====

21:05:48.934501 IP6 ::1.8080 > ::1.57020: Flags [P.], length 206: HTTP: HTTP/1.1 201 Created

HTTP/1.1 201 Created
Content-Type: application/json
Date: Sun, 14 Jun 2026 18:05:48 GMT
Content-Length: 93

{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-14T18:05:48.914358117Z"}
# Server responds with 201 Created and the created note

# ===== CONNECTION TEARDOWN =====

21:05:48.934931 IP6 ::1.57020 > ::1.8080: Flags [F.], ...
# FIN from client — client wants to close connection

21:05:48.935047 IP6 ::1.8080 > ::1.57020: Flags [F.], ...
# FIN from server — server agrees to close

21:05:48.935097 IP6 ::1.57020 > ::1.8080: Flags [.], ...
# Final ACK — connection fully closed
```
### 1.3 Five debugging commands
#### 1. What's listening on port 8080?
```bash
$ ss -tlnp | grep :8080
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=5232,fd=3))
```
QuickNotes process (PID 5232) is listening.

#### 2. Routes from host

```bash
$ ip route show
default via 172.19.144.1 dev eth0 proto kernel 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.18.0.0/16 dev br-b9c91fe00ac4 proto kernel scope link src 172.18.0.1 
172.19.144.0/20 dev eth0 proto kernel scope link src 172.19.152.206
```
Normal routing for WSL environment.

#### 3. Reachability (loopback)

```bash
$ mtr -rwc 5 localhost
Start: 2026-06-14T21:08:40+0300
HOST: DESKTOP-DPF5ULA Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost        0.0%     5    0.1   0.4   0.1   1.8   0.8
```
0% packet loss, average RTT ~0.4ms.

#### 4. DNS resolution
```bash
$ dig +short example.com @1.1.1.1
93.184.215.14
93.184.215.14
```
DNS works via Cloudflare resolver (1.1.1.1).

#### 5. Logs (if installed as service)
```bash
$ journalctl --user -u quicknotes -n 20 2>/dev/null || echo "Service not installed"
-- No entries --
```
QuickNotes is not installed as a systemd service — normal for this lab.

### 1.4 What would you check first if QuickNotes returned 502?
```text
If QuickNotes returned 502 Bad Gateway, I would follow this outside-in debugging chain:

Is the process running? — ps aux | grep quicknotes or pgrep -f quicknotes

Is it listening on the correct port? — ss -tlnp | grep 8080

Is there a firewall blocking? — sudo iptables -L -n -v (Linux) or check Windows Firewall

Is a reverse proxy (nginx/Caddy) misconfigured? — check proxy config and upstream definition

Are there any errors in logs? — check journalctl or app logs

Most often, 502 indicates the upstream server (QuickNotes) is not running or not reachable from the reverse proxy.
```

## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1 Run a broken instance

```bash
$ ADDR=:8080 go run . &
$ PID1=$!
$ sleep 1
$ ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &
$ PID2=$!
$ sleep 2
```
#### Output
```bash
2026/06/14 21:38:07 quicknotes listening on :8080 (notes loaded: 6)
2026/06/14 21:38:07 listen: listen tcp :8080: bind: address already in use
exit status 1
2026/06/14 21:38:08 quicknotes listening on :8080 (notes loaded: 6)
2026/06/14 21:38:08 listen: listen tcp :8080: bind: address already in use
exit status 1
[1]-  Exit 1                  ADDR=:8080 go run .
[2]+  Done                    ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log
```

### 2.2 Walk the outside-in chain
#### 1. Is the process running?
```bash
$ ps -ef | grep quicknotes
sano03      5232    3346  0 21:00 pts/0    00:00:00 /tmp/go-build.../quicknotes
```
One QuickNotes process is running.

#### 2. Is it listening?
```bash
$ ss -tlnp | grep 8080
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=5232,fd=3))
```
 Process 5232 is listening on port 8080.

 #### 3. Is it reachable from host?
 ```bash
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
 ```
Health endpoint returns 200 OK.
 #### 4. Is firewall blocking?
 ```bash
$ sudo iptables -L -n -v
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
...
 ```
 No INPUT rules block port 8080. Firewall is not the issue.
 #### 5. Does DNS work?
 ```bash
$ dig +short localhost
127.0.0.1
 ```
 DNS resolves localhost correctly.

 ### 2.3 Root cause
 The second process failed with:
 ```text
2026/06/14 21:38:08 listen: listen tcp :8080: bind: address already in use
 ```
 Root cause: Port 8080 was already occupied by the first QuickNotes process. The second process attempted to bind to the same port, causing the bind: address already in use error.

 ### 2.4 Repair and re-verify
 ```bash
$ kill 5232
$ sleep 1
$ ADDR=:8080 go run . &
$ sleep 1
$ curl -s http://localhost:8080/health
{"notes":6,"status":"ok"}
 ```
 After killing the old process, a new one starts successfully and returns a 200 response.

 ### 2.5 Mini-postmortem (blameless, ≤200 words)
 ```text
What happened?
Two processes tried to bind to the same port (8080). The first succeeded, the second failed with bind: address already in use. This caused the deploy to fail.
Systemic issue:
There was no coordination mechanism between processes. The system allowed two instances to attempt launching without checking port availability first. This is a common problem in environments without proper process management — it's not a developer mistake, but a missing guardrail.
How to prevent this in the future?
Use systemd with Socket Activation — systemd can hold the port and start the service on demand
Use a simple port check before launch: lsof -i :8080 or ss -tlnp | grep 8080
Use an orchestrator (docker-compose, Kubernetes) to manage port assignment
Use PID/lock files to ensure only one instance runs at a time
These tools shift port conflict resolution from "human memory" to automated policy, eliminating the class of failure entirely.
 ```