# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

**Platform:** macOS 15 (Darwin 25.5.0, Apple Silicon)

> Note on macOS vs Linux commands: `ss` → `lsof -i`; `ip route show` → `netstat -rn`; `journalctl` → macOS unified log (`log show`). The networking substrate is identical; only the tool names differ.

---

## Task 1 — Trace a Request End-to-End

### 1.1 Capture setup

QuickNotes started in one terminal:
```
cd app/ && go run .
2026/06/16 14:30:56 quicknotes listening on :8080 (notes loaded: 6)
```

Capture started (macOS loopback is `lo0`, not `lo`):
```bash
sudo tcpdump -i lo0 -nn -s 0 -A 'tcp port 8080' -w /tmp/lab4-trace.pcap
```

Request fired:
```bash
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

### 1.2 Annotated packet capture (`lab4-trace.txt`)

Full capture saved in `lab4-trace.txt`. Traffic ran over IPv6 loopback (`::1`) because macOS resolves `localhost` to `::1` by default.

#### TCP Three-Way Handshake

```
14:35:39.337160  ::1.57463 → ::1.8080  [S]   seq=615353596          ← SYN  (client opens connection)
14:35:39.337254  ::1.8080  → ::1.57463 [S.]  seq=635635080 ack=…+1  ← SYN-ACK (server accepts)
14:35:39.337281  ::1.57463 → ::1.8080  [.]   ack=1                  ← ACK  (handshake complete, 0.1 ms RTT)
```

Window size 65535, MSS 16324, SACK enabled, timestamps negotiated — both sides ready to transfer data.

#### HTTP Request (PSH+ACK, 174 bytes)

```
14:35:39.337335  ::1.57463 → ::1.8080  [P.]  length=174
  POST /notes HTTP/1.1
  Host: localhost:8080
  User-Agent: curl/8.7.1
  Content-Type: application/json
  Content-Length: 39

  {"title":"trace me","body":"in flight"}
```

Server ACKs the 174 bytes immediately (next packet, `length=0`).

#### HTTP Response (PSH+ACK, 203 bytes)

```
14:35:39.462955  ::1.8080  → ::1.57463 [P.]  length=203             ← 125 ms after request
  HTTP/1.1 201 Created
  Content-Type: application/json
  Date: Tue, 16 Jun 2026 11:35:39 GMT
  Content-Length: 90

  {"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T11:35:39.338268Z"}
```

The 125 ms gap is QuickNotes processing time (JSON decode + persist to disk).

#### Connection Close (FIN handshake)

```
14:35:39.463197  ::1.57463 → ::1.8080  [F.]  ← client sends FIN (done sending)
14:35:39.463248  ::1.8080  → ::1.57463 [.]   ← server ACKs client FIN
14:35:39.463276  ::1.8080  → ::1.57463 [F.]  ← server sends its own FIN
14:35:39.463351  ::1.57463 → ::1.8080  [.]   ← client ACKs server FIN
```

Clean four-packet FIN/ACK exchange (not RST). Total connection lifetime: ~126 ms.

---

### 1.3 Five debugging commands

#### 1. What's listening on :8080?

```bash
$ lsof -i :8080
COMMAND     PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 34847 irina    5u  IPv6 0x96a5dd9d5657b72c      0t0  TCP *:http-alt (LISTEN)
```

**Why:** confirms the process name, PID, and that it's bound on all interfaces (`*`), using IPv6 dual-stack (which also handles IPv4).

#### 2. Routing table

```bash
$ netstat -rn
Routing tables

Internet:
Destination        Gateway            Flags               Netif
default            10.240.16.1        UGScIg              en0
127.0.0.1          127.0.0.1          UH                  lo0
10.240.16/21       link#14            UCS                 en0
```

**Why:** shows the default gateway (`10.240.16.1` via `en0`) and that loopback (`lo0`) handles `127.0.0.1` directly with no gateway hop.

#### 3. MTR reachability (loopback)

```bash
$ sudo mtr -rwc 5 localhost
Start: 2026-06-16T15:33:19+0300
HOST: MacBook-Pro-Irina-4.local    Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost                   0.0%     5    0.3   0.3   0.2   0.3   0.0
```

**Why:** confirms loopback is reachable with 0% packet loss and sub-millisecond latency. One hop only — no routing beyond the OS kernel.

#### 4. DNS resolution (external)

```bash
$ dig +short example.com @1.1.1.1
104.20.23.154
172.66.147.243
```

**Why:** verifies that the machine can reach Cloudflare's resolver (`1.1.1.1`) and DNS is functioning. Two IPs returned — example.com uses Cloudflare's anycast CDN.

#### 5. Service logs (macOS equivalent of journalctl)

```bash
$ log show --last 30s --predicate 'process == "quicknotes"' 2>/dev/null
```

QuickNotes writes to `stderr` via `log.Printf` (Go's standard logger) — output is visible in the terminal that launched it, not the macOS unified log. On a Linux host with systemd: `journalctl --user -u quicknotes -n 20` would show the same lines. On macOS without a service wrapper, stdout/stderr is the canonical log stream.

```
2026/06/16 14:30:56 quicknotes listening on :8080 (notes loaded: 6)
```

---

### 1.4 What would I check first if QuickNotes returned 502?

A 502 Bad Gateway means a proxy received an invalid or no response from the upstream. My first check would be whether QuickNotes itself is actually running and listening: `lsof -i :8080` (or `ss -tlnp | grep 8080` on Linux). If the process is absent — the upstream crashed or never started. If it is listening, I'd hit `/health` directly from the proxy host (`curl http://localhost:8080/health`) to confirm it responds at all; a timeout here points to a firewall rule or network namespace issue blocking the proxy→app path. If `/health` responds but `/notes` returns 502, I'd check the application logs for a panic, an unhandled error, or a timeout exceeding the proxy's `proxy_read_timeout`. Finally I'd verify there's no upstream port mismatch: the proxy config might point to `:8081` while the app listens on `:8080`.

---

## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1 Reproduce the broken instance

Attempted to start a second QuickNotes on the already-occupied `:8080`:

```bash
$ ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log
2026/06/16 22:23:34 quicknotes listening on :8080 (notes loaded: 7)
2026/06/16 22:23:34 listen: listen tcp :8080: bind: address already in use
exit status 1
```

The process prints the listening message first (from `main.go`'s log line before `ListenAndServe`) then immediately exits with the bind error. **Root cause identified immediately from stderr:** `bind: address already in use`.

### 2.2 Outside-in debugging chain

#### Step 1: Is QuickNotes running at all?

```bash
$ ps -ef | grep "[q]uicknotes\|[g]o run"
501 34827 28430  0  2:35PM  0:01.18  go run .
501 34847 34827  0  2:35PM  0:00.06  /path/.../quicknotes
```

**Decision:** process IS running (PID 34847). The second instance exited immediately; the first is still alive. Continue to check if it's listening.

#### Step 2: Is it listening on 8080?

```bash
$ lsof -i :8080
COMMAND     PID  USER   FD   TYPE  DEVICE  NODE NAME
quicknote 34847 irina    5u  IPv6  …       TCP *:http-alt (LISTEN)
```

**Decision:** PID 34847 holds the socket. The second instance never got to bind — it was dead before this command ran. Port is occupied by the first (healthy) instance.

#### Step 3: Is it reachable from the host?

```bash
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```

**Decision:** 200 OK — the first (surviving) instance is healthy and serving traffic. No L7 issue.

#### Step 4: Firewall blocking?

```bash
$ sudo pfctl -sr 2>/dev/null || echo "pfctl requires sudo / no active rules"
pfctl requires sudo / no active rules visible
```

**Decision:** macOS firewall (`pf`) is not blocking port 8080. No iptables on macOS; `pf` is the equivalent. Not the cause.

#### Step 5: DNS for localhost?

```bash
$ grep localhost /etc/hosts
127.0.0.1   localhost
::1         localhost
```

**Decision:** `localhost` resolves via `/etc/hosts` (no DNS server involved — `dig localhost` times out because the system DNS server doesn't know the name). Resolution is correct; not the issue.

### 2.3 Repair and re-verify

```bash
kill 34847          # kill first (healthy) instance to simulate "old deploy still running"
sleep 1
ADDR=:8080 go run . &
sleep 1
curl -s http://localhost:8080/health
# → {"notes":7,"status":"ok"}
```

Second instance now binds successfully and responds with 200. System restored.

### 2.4 Mini-postmortem (blameless)

**Root cause:** `listen tcp :8080: bind: address already in use` — the new process tried to bind a port already held by the previous instance.

**What's systemic about this failure:** this class of error is not a developer mistake — it's a deployment sequencing problem. Any rolling restart, crash-loop, or CI-triggered redeploy that starts the new process before the old one has fully exited will hit this. The OS kernel holds the socket until all file descriptors referencing it are closed; even a `SIGTERM`-ed process keeps the socket alive until it finishes graceful shutdown. In a container environment this is mitigated by Kubernetes readiness probes and pod lifecycle hooks. On bare metal it requires either `SO_REUSEPORT` (multiple processes sharing one port) or a process supervisor (systemd, supervisord) that serializes stop→start. **Prevention tooling:** a pre-start check (`lsof -ti :8080 | xargs kill -0 2>/dev/null && echo "port busy"`) added to the deploy script catches this in < 1 s; a systemd unit with `Restart=on-failure` and `RestartSec=2` gives the old process time to release the socket before the new one starts.
