
# Lab 4 — OS and Networking: Trace, Debug, and Read the Substrate

## Task 1 — Trace a Request End-to-End

### 1.1 + 1.2: Packet Capture Analysis

**Capture setup:**
```bash
# Terminal A: Start QuickNotes
cd /mnt/d/inno/DevOps-Intro/app
go run .

# Terminal B: Start tcpdump
sudo tcpdump -i lo -nn -s 0 -w lab4-trace.pcap 'tcp port 8080' > /dev/null 2>&1 & TCPDUMP_PID=$!

# Terminal C: Send request
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

**Decoded packet trace** (from `sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt`):

#### TCP Three-Way Handshake
```
18:19:50.899638 IP6 ::1.36076 > ::1.8080: Flags [S], seq 1056778106, win 65476
  -> SYN (client initiates connection)

18:19:50.899650 IP6 ::1.8080 > ::1.36076: Flags [S.], seq 1449592973, ack 1056778107, win 65464
  -> SYN/ACK (server acknowledges and responds)

18:19:50.899658 IP6 ::1.36076 > ::1.8080: Flags [.], ack 1, win 64
  -> ACK (client acknowledges server's SYN, handshake complete)
```

#### HTTP Request
```
18:19:50.899745 IP6 ::1.36076 > ::1.8080: Flags [P.], seq 1:175, ack 1, win 64, length 174: HTTP: POST /notes HTTP/1.1

POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.5.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

#### HTTP Response
```
18:19:50.904378 IP6 ::1.8080 > ::1.36076: Flags [P.], seq 1:208, ack 175, win 64, length 207: HTTP: HTTP/1.1 201 Created

HTTP/1.1 201 Created
Content-Type: application/json
Date: Mon, 15 Jun 2026 15:19:50 GMT
Content-Length: 94

{"id":10,"title":"trace me","body":"in flight","created_at":"2026-06-15T15:19:50.899955074Z"}
```

#### Connection Close
```
18:19:50.904557 IP6 ::1.36076 > ::1.8080: Flags [F.], seq 175, ack 208, win 64
  -> FIN (client initiates graceful close)

18:19:50.904648 IP6 ::1.8080 > ::1.36076: Flags [F.], seq 208, ack 176, win 64
  -> FIN (server acknowledges and also closes)

18:19:50.904662 IP6 ::1.36076 > ::1.8080: Flags [.], ack 209, win 64
  -> ACK (final acknowledgment, connection fully closed)
```

**Observation:** The entire request-response cycle took approximately 5 milliseconds (from 18:19:50.899638 to 18:19:50.904662). The connection used IPv6 loopback (::1) rather than IPv4 (127.0.0.1), which is the default behavior for modern curl when resolving localhost.

---

### 1.3: Five Debugging Commands

#### 1. What's listening on port 8080?
```bash
$ ss -tlnp | grep :8080
LISTEN 0      4096               *:8080            *:*    users:(("quicknotes",pid=7000,fd=3))
```
**Interpretation:** QuickNotes is listening on all interfaces (*) on port 8080 with PID 7000. The process owns file descriptor 3 (the listening socket).

#### 2. Routes from your host
```bash
$ ip route show
default via 172.31.0.1 dev eth0 proto kernel
172.31.0.0/20 dev eth0 proto kernel scope link src 172.31.5.97
```
**Interpretation:** Default gateway is 172.31.0.1 via eth0 interface. Local subnet is 172.31.0.0/20 with source IP 172.31.5.97. This is typical for WSL2 networking.

#### 3. Reachability (loop on lo)
```bash
$ mtr -rwc 5 localhost
Start: 2026-06-15T18:22:14+0300

HOST: DESKTOP-IN3A60B Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost        0.0%     5    0.1   0.1   0.0   0.1   0.0
```
**Interpretation:** Loopback interface is fully functional with 0% packet loss and sub-millisecond latency (0.1ms average). No network issues on localhost.

#### 4. DNS works
```bash
$ dig +short example.com @1.1.1.1
104.20.23.154
172.66.147.243
```
**Interpretation:** DNS resolution is working correctly. example.com resolves to two IPv4 addresses via Cloudflare's DNS (1.1.1.1). Multiple A records indicate load balancing/CDN.

#### 5. Logs (if installed as service)
```bash
$ journalctl --user -u quicknotes -n 20
-- No entries --
```
**Interpretation:** QuickNotes is not installed as a systemd user service. It's running manually via `go run .`, so there are no journal entries. For production, it should be installed as a system service with proper unit file configuration.

---

### 1.4: What would you check first if QuickNotes returned 502?

If QuickNotes returned a 502 Bad Gateway error, I would first verify whether the backend process is actually running using `ps aux | grep quicknotes` or `systemctl status quicknotes` (if installed as a service). A 502 typically indicates that a reverse proxy (like nginx or Caddy) cannot reach the upstream application server. Next, I would check if the service is listening on the expected port with `ss -tlnp | grep :8080` — if the process is running but not bound to the correct port, it might have failed to start properly or bound to a different interface. Then I would examine the application logs using `journalctl -u quicknotes -n 50` (for systemd) or check stdout/stderr (for manual runs) to identify any startup errors, database connection failures, or runtime exceptions. I would also test direct connectivity with `curl -v http://localhost:8080/health` to bypass any proxy layer and confirm whether the issue originates at the application level or in the proxy configuration itself. Finally, I would review the proxy configuration files to ensure the upstream address is correctly specified and that the proxy has appropriate permissions to connect to the backend service.


## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1: Broken Instance Reproduced

**Setup:** Launched two QuickNotes instances on the same port (`:8080`).

```bash
# First instance (captures the port)
ADDR=:8080 go run . > /tmp/qn-first.log 2>&1 & PID1=$!
#PID1=8860
# Second instance (fails to bind)
ADDR=:8080 go run . > /tmp/qn-broken.log 2>&1 & PID2=$!
#PID2=8998
```

**Error captured:**
```
$ cat /tmp/qn-broken.log
2026/06/15 18:34:37 quicknotes listening on :8080 (notes loaded: 10)
2026/06/15 18:34:37 listen: listen tcp :8080: bind: address already in use
exit status 1
```

The second process exited immediately with status 1, confirming the port conflict.

### 2.2: Outside-In Debugging Chain

#### Step 1: Is it running?
```bash
$ ps -ef | grep quicknotes | grep -v grep
levak       8990    8860  0 18:34 pts/4    00:00:00 /home/levak/.cache/go-build/.../quicknotes
```
**Decision:** Process is running (PID 8990, child of go run PID 8860). Moving to next step.

#### Step 2: Is it listening?
```bash
$ ss -tlnp | grep 8080
LISTEN 0      4096               *:8080            *:*    users:(("quicknotes",pid=8990,fd=3))
```
**Decision:** Port 8080 is bound by quicknotes (PID 8990). Process is listening. Moving to next step.

#### Step 3: Reachable from host?
```bash
$ curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/health
HTTP Status: 200
```
**Decision:** Service is reachable and responding with 200 OK. The first instance is working perfectly. The issue is NOT with the running instance.

#### Step 4: Firewall blocking?
```bash
$ sudo iptables -L -n -v 2>/dev/null || echo "iptables not available or no rules"
iptables not available or no rules
```
**Decision:** iptables is not available in WSL2 environment (typical limitation). No firewall rules are blocking traffic. Moving to next step.

#### Step 5: DNS?
```bash
$ dig +short localhost
127.0.0.1
```
**Decision:** DNS resolution is correct. localhost resolves to 127.0.0.1.

**Conclusion:** The debugging chain shows that the **first instance is working perfectly** (running, listening, reachable, no firewall, DNS correct). The problem is that the **second instance failed to start** because the port was already in use. The root cause is in the application logs (`/tmp/qn-broken.log`).

### 2.3: Root Cause

**Root cause:** `bind: address already in use`

The second QuickNotes instance attempted to bind to port 8080, but the first instance was already listening on that port. TCP only allows one process to bind to a specific port on a given interface.

**Evidence:**
```
$ cat /tmp/qn-broken.log
2026/06/15 18:34:37 listen: listen tcp :8080: bind: address already in use
exit status 1
```

**Note:** When `go run .` is executed, it compiles the binary and spawns it as a child process. Killing the `go run` parent process does not automatically kill the child quicknotes binary, which continues to hold the port.
### 2.4: Mini-Postmortem

**Incident:** Second QuickNotes instance failed to start due to port conflict.

**What happened:** A second instance was launched on port 8080 without stopping the existing one. The Go HTTP server failed immediately with "address already in use."

**Why this is systemic:** This is a classic race condition in deployment automation. When multiple deployment scripts run concurrently, there's no mechanism to detect port conflicts. The application reports the error correctly, but if logs aren't monitored, the failure goes unnoticed. Additionally, `go run` spawns a child process that persists after the parent is killed, creating orphaned processes holding resources.

**Tooling to prevent it:**
1. **Systemd `ExecStartPre`:** Verify the port is free before launch: `ExecStartPre=/bin/bash -c 'ss -tln | grep -q :8080 && exit 1 || exit 0'`
2. **Health check in deploy script:** Query `curl localhost:8080/health` and proceed only if it's down
3. **PID file:** Use `/var/run/quicknotes.pid` to check if the process is alive
4. **Container orchestration:** Docker/Kubernetes handles port allocation automatically

**Lesson:** Always implement idempotent deployment scripts. Use process supervisors (systemd) rather than manual `go run` in production.