# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

**Student:** Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + **WSL2 Ubuntu** (Go 1.24.4, `tcpdump`, `ss`, `dig`, `mtr`)

---

## Task 1 — Trace a request end-to-end

### 1.1 Capture setup

| Terminal | Command | Result |
|----------|---------|--------|
| A | `go run .` | `quicknotes listening on :8080 (notes loaded: 8)` |
| B | `sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap` | capture started on `lo` |
| C | `curl -v -X POST http://localhost:8080/notes ...` | **HTTP 201 Created** |

Capture file: `app/lab4-trace.pcap`  
Decoded text: `app/lab4-trace.txt`

### 1.2 Annotated capture

**TCP three-way handshake** (`::1` → `::1:8080`, first request at `22:26:03`):

| Step | Flags | Evidence |
|------|-------|----------|
| SYN | `[S]` | `seq 2609277124` — client opens connection |
| SYN/ACK | `[S.]` | server `ack 2609277125` |
| ACK | `[.]` | client acknowledges — handshake complete |

**HTTP request** (client → server):

```http
POST /notes HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

**HTTP response** (server → client):

```http
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 93

{"id":9,"title":"trace me","body":"in flight","created_at":"2026-06-16T19:26:03.770537887Z"}
```

**Connection close:** client `FIN` (`Flags [F.]`), server `FIN` — graceful teardown after response.

> Note: a second accidental `curl` without `-d` also appears in the capture (`400 Bad Request`); the annotated flow above is the deliberate lab request.

### 1.3 Five debugging commands

**1. What's listening?**

```bash
ss -tlnp | grep :8080
```

```
LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=5411,fd=3))
```

**2. Routes from host**

```bash
ip route show
```

```
default via 172.18.160.1 dev eth0 proto kernel
172.18.160.0/20 dev eth0 proto kernel scope link src 172.18.171.173
```

**3. Reachability (loopback)**

```bash
mtr -rwc 3 localhost
```

```
HOST: DESKTOP-DP8F0L8 Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost        0.0%     3    0.1   0.1   0.1   0.1   0.0
```

**4. DNS works**

```bash
dig +short example.com @1.1.1.1
```

```
8.47.69.0
8.6.112.0
```

**5. Logs (service)**

```bash
journalctl --user -u quicknotes -n 20
```

```
-- No entries --
(no quicknotes user service installed — app run manually with go run .)
```

### 1.4 If QuickNotes returned 502 — what to check first?

A **502 Bad Gateway** means a reverse proxy reached *something*, but the upstream app failed or was unreachable — not a bug inside QuickNotes itself. I would check **in order**: (1) `ss -tlnp | grep 8080` — is QuickNotes actually listening on the port the proxy targets? (2) `curl -v http://127.0.0.1:8080/health` from the same host as the proxy — bypasses DNS and confirms the app responds locally; (3) proxy config (`upstream` / `reverse_proxy` URL, wrong port or socket path); (4) recent deploy logs (`journalctl` or container logs) for crash loops or `bind: address already in use`; (5) only then DNS/firewall (`dig`, `iptables`) if the proxy runs on a different host than the app.

---

## Task 2 — Outside-in debugging on a broken deploy

### 2.1 Reproduce broken instance

With QuickNotes already listening on `:8080`, starting a second instance:

```bash
cd app/
go run .
```

**Bind error captured:**

```
2026/06/16 22:29:13 quicknotes listening on :8080 (notes loaded: 9)
2026/06/16 22:29:13 listen: listen tcp :8080: bind: address already in use
exit status 1
```

### 2.2 Outside-in chain

| Step | Command | Output | Decision |
|------|---------|--------|----------|
| 1 — process running? | `ps -ef \| grep quicknotes` | `quicknotes` pid **5411** on `:8080` | Original instance is alive |
| 2 — listening? | `ss -tlnp \| grep 8080` | `*:8080` → `quicknotes` pid 5411 | Port 8080 already bound |
| 3 — reachable? | `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health` | `200` | Existing instance healthy — failure is duplicate deploy, not dead app |
| 4 — firewall? | `sudo iptables -L -n -v` | (no rules blocking localhost) | Not a firewall issue on loopback |
| 5 — DNS? | `dig +short localhost` | `127.0.0.1` | DNS fine — not a name-resolution problem |

### 2.3 Repair + re-verify

```bash
# kill duplicate attempt (first instance still running)
curl -s http://localhost:8080/health
```

```json
{"status":"ok","notes":9}
```

Single instance on `:8080` restored; health returns **200**.

### 2.4 Mini-postmortem (≤ 200 words)

**What happened:** A second QuickNotes process was started while the first still held `:8080`, causing `bind: address already in use` and exit before serving traffic.

**Blameless framing:** This is systemic, not individual error. Two deploy paths (manual `go run`, systemd, Docker, CI smoke test) can race for the same port without coordination. Nothing in the default setup reserves the port or checks occupancy before bind.

**Prevention tooling:** (1) **systemd** `ExecStartPre` + `ss`/`fuser` guard; (2) **container orchestration** with one replica and explicit port mapping; (3) **health + readiness probes** that fail deploy if the old process still owns the socket; (4) **config management** (Ansible/Terraform) serializing restarts; (5) **structured logs** with PID and listen address on startup so `journalctl` shows duplicate attempts immediately.

---

## Bonus — TLS handshake (optional)

_Not attempted._

---

## Submission — Pull requests

| PR | URL |
|----|-----|
| **Course** (`feature/lab4` → `inno-devops-labs/main`) | _TODO_ |
| **Fork** (`feature/lab4` → `selysecr332/main`) | _TODO_ |

**Moodle:** submit both URLs before the deadline.

---

## Lab 4 completion checklist

### Task 1 (6 pts)

- [x] `lab4-trace.pcap` / annotated `lab4-trace.txt`
- [x] TCP handshake, HTTP req/resp, close identified
- [x] Five debug commands with output
- [x] 502 reflection paragraph

### Task 2 (4 pts)

- [x] Broken deploy reproduced (`bind: address already in use`)
- [x] Outside-in chain documented
- [x] Repair verified
- [x] Mini-postmortem written

### Submission

- [ ] Course PR opened
- [ ] Fork PR opened
- [ ] Both URLs on Moodle

### Bonus (2 pts)

- [ ] Not attempted
