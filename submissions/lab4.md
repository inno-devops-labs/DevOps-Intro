# Lab 4 submission

**Platform:** macOS (loopback interface `lo0`; `ss` via Homebrew `iproute2mac`)

## Task 1 — Trace a Request End-to-End

### 1.1–1.2 Packet capture

Captured on `lo0` (macOS loopback). Full decode in `lab4-trace.txt`; binary capture in `lab4-trace.pcap`.

**Annotated trace (key packets):**

| # | Time | Phase | Packet |
|---|------|-------|--------|
| 1 | 22:34:17.041526 | **SYN** | `::1.50607 → ::1.8080` Flags `[S]` |
| 2 | 22:34:17.041640 | **SYN/ACK** | `::1.8080 → ::1.50607` Flags `[S.]` |
| 3 | 22:34:17.041665 | **ACK** | `::1.50607 → ::1.8080` Flags `[.]` — handshake complete |
| 4 | 22:34:17.041691 | **HTTP request** | Flags `[P.]` length 174 — `POST /notes HTTP/1.1` + JSON body |
| 5 | 22:34:17.042240 | **HTTP response** | Flags `[P.]` length 203 — `HTTP/1.1 201 Created` + JSON body |
| 6 | 22:34:17.042335–042376 | **Close** | Client `FIN` → server `ACK` → server `FIN` → client `ACK` |

**HTTP request (from capture):**

```
POST /notes HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

**HTTP response (from capture):**

```
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 90

{"id":9,"title":"trace me","body":"in flight","created_at":"2026-06-16T19:34:17.041929Z"}
```

Traffic used **IPv6 loopback** (`::1`) — typical for `curl` to `localhost` on macOS.

**`curl -v` corroboration (same request shape):**

```
* Connected to localhost (::1) port 8080
> POST /notes HTTP/1.1
> Host: localhost:8080
> Content-Type: application/json
> Content-Length: 39
>
< HTTP/1.1 201 Created
< Content-Type: application/json
< Content-Length: 90
{"id":8,"title":"trace me","body":"in flight","created_at":"2026-06-16T19:25:43.757485Z"}
```

### 1.3 Five debugging commands

**1. What's listening? (`ss -tlnp | grep :8080`)**

```
tcp46  LISTEN  0  0  *:8080  *:*
```

`lsof` confirms process:

```
COMMAND    PID          USER   FD   TYPE  NODE NAME
quicknote 8864 arsenypinigin    7u  IPv6       TCP *:8080 (LISTEN)
```

**2. Routes (`ip route show` — macOS: `netstat -rn`)**

```
Destination        Gateway            Flags    Netif
default            192.168.1.1        UGScg    en0
127                127.0.0.1          UCS      lo0
127.0.0.1          127.0.0.1          UH        lo0
```

Loopback traffic to `:8080` stays on `lo0` — no gateway hop.

**3. Reachability (`mtr -rwc 5 localhost` — used `ping -c 5 127.0.0.1` when mtr needs sudo)**

```
PING 127.0.0.1 (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.109 ms
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.169 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.109 ms
--- 127.0.0.1 ping statistics ---
3 packets transmitted, 3 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 0.109/0.129/0.169/0.028 ms
```

**4. DNS (`dig +short example.com @1.1.1.1`)**

```
104.20.23.154
172.66.147.243
```

**5. Logs (`journalctl --user -u quicknotes -n 20`)**

Not available on macOS (no systemd/journalctl). QuickNotes logs to stdout when run with `go run .`:

```
2026/06/16 22:26:08 quicknotes listening on :8080 (notes loaded: 8)
```

### 1.4 If QuickNotes returned 502 — what to check first?

A 502 Bad Gateway means a proxy or load balancer received an invalid response from an upstream server — the edge is up but the backend is not answering correctly. I would check in order: (1) is QuickNotes actually running and listening (`ss`/`lsof` on `:8080`)? (2) can I reach it directly from the host (`curl -v http://localhost:8080/health`)? (3) if behind a reverse proxy, are upstream address and port correct in the proxy config? (4) are there connection errors in proxy logs (timeouts, connection refused)? Only after the app layer is confirmed healthy would I look at DNS, firewall rules, or routing — a 502 specifically points to a broken hop between proxy and origin, not a client-side DNS failure.

---

## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1 Reproduce

Started two instances on the same port:

```bash
ADDR=:8080 go run . &   # PID1 — succeeds
ADDR=:8080 go run . &   # PID2 — fails
```

**Second instance error:**

```
2026/06/16 22:26:10 quicknotes listening on :8080 (notes loaded: 8)
2026/06/16 22:26:10 listen: listen tcp :8080: bind: address already in use
exit status 1
```

### 2.2 Outside-in chain

| Step | Command | Output | Decision |
|------|---------|--------|----------|
| 1. Process running? | `ps` / `lsof -iTCP:8080` | `quicknote` PID 8864 listening | First instance is up; second crashed |
| 2. Listening? | `ss -tlnp \| grep 8080` | `*:8080 LISTEN` | Port 8080 is taken by PID 8864 |
| 3. Reachable? | `curl -w %{http_code} localhost:8080/health` | `200` | **First** instance serves traffic fine — failure is deploy-time, not runtime |
| 4. Firewall? | `iptables` / `nft` | N/A on macOS | Skip — loopback not blocked |
| 5. DNS? | `dig +short localhost` | NXDOMAIN | Irrelevant — using `127.0.0.1`/`::1` directly |

**Root cause:** `bind: address already in use` — second `go run .` could not acquire `:8080` because the first process already holds it.

### 2.3 Repair

```bash
kill $PID1          # free port 8080
ADDR=:8080 go run . &
curl -s http://localhost:8080/health
# {"notes":8,"status":"ok"}
```

### 2.4 Mini-postmortem (blameless)

Two deploy processes were started against the same `ADDR=:8080` without coordination. The first bound successfully; the second failed at `ListenAndServe` with `address already in use` and exited — but in a real environment the failed deploy might go unnoticed if health checks still hit the old process. This is systemic: port conflicts are silent when something already listens, and manual deploy scripts lack atomic handoff. Prevention tooling: systemd socket activation with `SO_REUSEPORT` policies, pre-deploy port checks (`ss -tlnp`), blue/green or rolling deploys that stop the old instance before starting the new one, and CI smoke tests that verify the *new* binary PID is serving (not just that `:8080` returns 200).

---

## Bonus Task — TLS Handshake

<!-- Optional: requires Caddy + sudo tcpdump on port 8443 — not attempted on macOS in this session -->
