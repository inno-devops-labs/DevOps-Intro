## Task 1 — Trace a Request End-to-End (6 pts)

### 1.1 Capture

App started in terminal A with `cd app/ && go run .` (listens on `:8080`).
Capture in terminal B (sudo pre-authenticated with `sudo -v` so it could run
backgrounded without a suspended password prompt):

```bash
sudo tcpdump -i lo0 -s 0 -w lab4-trace.pcap 'tcp port 8080' &
TCPDUMP_PID=$!
```

One request fired in terminal C:

```bash
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

`curl -v` output (note: connection went over IPv6 loopback `::1`):

```
* Connected to localhost (::1) port 8080
> POST /notes HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.7.1
> Content-Type: application/json
> Content-Length: 39
>
< HTTP/1.1 201 Created
< Content-Type: application/json
< Date: Tue, 16 Jun 2026 20:46:57 GMT
< Content-Length: 90
<
{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T20:46:57.566588Z"}
* Connection #0 to host localhost left intact
```

Capture stopped: `sudo kill $TCPDUMP_PID` → tcpdump reported **12 packets captured**.

### 1.2 Decode + annotate

Decoded with `sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt`.
The whole transaction is loopback IPv6 (`::1`), client port `55246` ↔ server port `8080`.
Annotated packet walk:

**① TCP three-way handshake** (packets 1–3):

```
[S]   ::1.55246 > ::1.8080: Flags [S],  seq 1061962572              ← SYN  (client → server)
[S.]  ::1.8080  > ::1.55246: Flags [S.], seq 1185686777, ack ...573 ← SYN/ACK (server → client)
[.]   ::1.55246 > ::1.8080: Flags [.],  ack 1                       ← ACK  (client → server)
```
Connection established. (Plus an extra server `[.]` ack — normal on loopback.)

**② HTTP request line + JSON body** (packet 5, `[P.]` PUSH, length 174):

```
::1.55246 > ::1.8080: Flags [P.], seq 1:175 ... HTTP: POST /notes HTTP/1.1
  POST /notes HTTP/1.1
  Host: localhost:8080
  User-Agent: curl/8.7.1
  Content-Type: application/json
  Content-Length: 39

  {"title":"trace me","body":"in flight"}
```

**③ HTTP response line + JSON body** (packet 7, `[P.]` PUSH, length 203):

```
::1.8080 > ::1.55246: Flags [P.], seq 1:204 ... HTTP: HTTP/1.1 201 Created
  HTTP/1.1 201 Created
  Content-Type: application/json
  Date: Tue, 16 Jun 2026 20:46:57 GMT
  Content-Length: 90

  {"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T20:46:57.566588Z"}
```

**④ Connection close** (FIN handshake, packets 9–12):

```
[F.]  ::1.55246 > ::1.8080: Flags [F.], seq 175  ← client FIN
[.]   ::1.8080  > ::1.55246: Flags [.],  ack 176 ← server ACKs the FIN
[F.]  ::1.8080  > ::1.55246: Flags [F.], seq 204 ← server FIN
[.]   ::1.55246 > ::1.8080: Flags [.],  ack 205  ← client ACKs → connection closed
```

Graceful four-way FIN close (no `RST`). Full raw capture in `lab4-trace.txt`.

### 1.3 Five debugging commands

**1. What's listening on :8080?** (`ss` does not exist on macOS → `lsof`)

```
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
COMMAND     PID          USER   FD   TYPE  DEVICE             NODE NAME
quicknote 34042 dmitrijnaumov    5u  IPv6  0x19c0...877       TCP  *:8080 (LISTEN)
```
→ The `quicknotes` process (PID 34042) owns `*:8080`, bound on IPv6 — which is
why the curl above connected via `::1`.

**2. Routes from this host** (`ip route` → `netstat -rn`, relevant rows):

```
Destination        Gateway            Flags    Netif
default            192.168.0.1        UGScIg   en0      ← default route via Wi-Fi gateway
127                127.0.0.1          UCS      lo0      ← all 127/8 stays on loopback
127.0.0.1          127.0.0.1          UH       lo0
::1                ::1                UHL      lo0      ← IPv6 loopback (used by this request)
```
(Full table — incl. many VPN `utun4` host routes — omitted for brevity.)

**3. Reachability on loopback** (`mtr` → `traceroute`):

```
$ traceroute localhost
traceroute to localhost (127.0.0.1), 64 hops max
 1  localhost (127.0.0.1)  1.687 ms  1.040 ms  0.702 ms
```
→ Single hop, sub-2ms — loopback never leaves the host.

**4. DNS works** (`dig` — same on macOS):

```
$ dig +short example.com @1.1.1.1
172.66.147.243
104.20.23.154
```
→ Resolution against Cloudflare `1.1.1.1` succeeds.

**5. Service logs** — no `journalctl`/journald on macOS. QuickNotes was run in the
foreground via `go run .`, so its log line
(`quicknotes listening on :8080 (notes loaded: N)`) prints to terminal A's stdout;
that terminal *is* the log sink here.

### 1.4 Reflection — what would I check first on a 502?

A 502 Bad Gateway is a **proxy/upstream** error: the front proxy (nginx, Caddy,
a load balancer) accepted my connection but got no valid response from the
backend. So I would not start at the client — I'd work the upstream link. First,
is the QuickNotes process actually alive and **listening** on the expected port
(`lsof -nP -iTCP:8080 -sTCP:LISTEN`)? If it's not listening, it crashed or never
bound — check its logs/stdout for a panic or `bind` error. If it *is* listening,
is the proxy pointed at the right host:port, and is the backend simply too slow
(a handler timeout will surface as 502/504)? In short: 502 means "the thing
behind the gateway is broken or unreachable," so I trace proxy → upstream
process → port → logs, in that order.

---

## Task 2 — Outside-In Debugging on a Broken Deploy (4 pts)

### 2.1 Reproduce the break (port conflict)

```bash
cd app/
ADDR=:8080 go run . &        # first instance
PID1=$!
sleep 2
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &   # second instance
```

First instance bound cleanly:

```
[1] 40010
2026/06/16 23:54:30 quicknotes listening on :8080 (notes loaded: 7)
```

Second instance failed — **exact root-cause error**:

```
2026/06/16 23:54:54 quicknotes listening on :8080 (notes loaded: 7)
2026/06/16 23:54:54 listen: listen tcp :8080: bind: address already in use
exit status 1
[2]  + exit 1     ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log
```

Root cause: **`listen tcp :8080: bind: address already in use`** (`EADDRINUSE`) —
two processes cannot bind the same `host:port`.

### 2.2 Outside-in chain (command → output → decision)

**1. Is it running?** (`ps`)

```
$ ps -ef | grep -E "go run|quicknotes" | grep -v grep
501 40010 39989  ... go run .
501 40014 40010  ... /Users/.../go-build/.../quicknotes
```
→ Yes, and there are **two** processes: the `go run .` wrapper (PID 40010) and
its **child compiled binary** `quicknotes` (PID 40014, parent = 40010). The child
is the real server. *Decision: process alive; move inward.*

**2. Is it listening?** (`lsof`, replaces `ss -tlnp`)

```
$ lsof -nP -iTCP:8080
COMMAND     PID          USER   FD   TYPE  DEVICE             NODE NAME
quicknote 40014 dmitrijnaumov    5u  IPv6  0x3677...01c0      TCP  *:8080 (LISTEN)
```
→ The **child** PID 40014 (not the `go run` wrapper) owns `*:8080`. *Decision:
exactly one listener — the second instance never bound, consistent with EADDRINUSE.*

**3. Reachable from host?** (`curl` health probe)

```
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```
→ The surviving first instance serves fine. *Decision: not a connectivity/app
fault — the failure is purely the second bind losing the race for the port.*

**4. Firewall blocking?** (`pfctl`, replaces `iptables`/`nft`)

```
$ sudo pfctl -sr
scrub-anchor "com.apple/*" all fragment reassemble
anchor "com.apple/*" all
```
→ Only default macOS anchors, no rules blocking 8080. *Decision: not a firewall
problem — network layer ruled out.*

**5. DNS?** (`dig`)

```
$ dig +short localhost
(empty)
```
→ Empty is **expected**: `localhost` resolves from `/etc/hosts`, not DNS, and
`dig` only queries DNS. *Decision: name resolution not involved — "it's not DNS."*

**Conclusion of the chain:** running ✓, listening ✓ (one instance), reachable ✓,
firewall clear, DNS irrelevant → the only fault is the **second process losing the
bind race** on an already-occupied port.

### 2.3 Repair + re-verify — and a process-tree gotcha

```bash
kill $PID1        # PID1 = 40010
sleep 1
ADDR=:8080 go run . &
sleep 1
curl -s http://localhost:8080/health
```

Result — the new instance **still failed to bind**, yet `/health` returned 200:

```
[1]  + terminated  ADDR=:8080 go run .
2026/06/16 23:56:03 listen: listen tcp :8080: bind: address already in use
exit status 1
$ curl -s http://localhost:8080/health
{"notes":7,"status":"ok"}
```

**Why:** `kill $PID1` killed only the `go run` **wrapper** (40010), not its child
listener `quicknotes` (40014). The child was **orphaned and kept holding `:8080`**,
so the fresh `go run` hit the same `EADDRINUSE`, and the 200 from `/health` is the
*old orphaned listener* still answering — not a clean restart. A classic false-green.

**Correct repair** — kill the actual listener found via `lsof`, then restart:

```bash
lsof -nP -iTCP:8080            # find the real listener PID (the quicknotes child, 40014)
kill 40014                     # or: pkill quicknotes
sleep 1
ADDR=:8080 go run . &          # now binds cleanly
curl -s http://localhost:8080/health
```

### 2.4 Blameless mini-postmortem (≤200 words)

A second instance crash-looped with `bind: address already in use`. No one "did it
wrong" — the system simply *permitted* two processes to contend for one `host:port`
with nothing enforcing single-instance ownership. The incident exposed a second,
sharper systemic gap: killing the `go run` wrapper did **not** reap its child
server. Wrapper and listener are different PIDs, and a plain `kill` of the parent
orphaned the child, which kept holding the port. The misleading `200` from the
health check then made a *failed* restart look successful.

What's systemic: process *lifecycle* and *ownership* were both unmanaged. A real
supervisor (launchd, systemd, or a container runtime) tracks the whole process
group/cgroup, so stopping the unit reaps every child and frees the port atomically,
and it refuses to start a duplicate. Preventive tooling: readiness/liveness probes
that distinguish "bound and serving" from "stale orphan answering," a deploy
pre-check that the port is free (`lsof`/`ss`) before launch, and dynamic port
allocation or per-container network namespaces so two instances can never collide
in the first place.
---
