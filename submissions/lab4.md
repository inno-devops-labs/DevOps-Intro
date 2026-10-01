# Lab 4 submission

## Task 1 — Trace a Request End-to-End

### 1.1–1.2 — Packet capture and decode

Captured with:
```bash
sudo tcpdump -i lo0 -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
sudo kill <PID>
```

Decoded with:
```bash
tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt
```

**Annotated trace:**

```
20:08:57.960159 IP6 ::1.50625 > ::1.8080: Flags [S], seq 4293837482, ...
20:08:57.960212 IP6 ::1.8080 > ::1.50625: Flags [S.], seq 465245794, ack 4293837483, ...
20:08:57.960225 IP6 ::1.50625 > ::1.8080: Flags [.], ack 1, ...
```
↑ **TCP three-way handshake** — SYN, SYN/ACK, ACK. Client on ephemeral port 50625 connects to server on 8080.

```
20:08:57.960276 IP6 ::1.50625 > ::1.8080: Flags [P.], seq 1:175, length 174: HTTP: POST /notes HTTP/1.1
POST /notes HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```
↑ **HTTP request** — `[P.]` flag means PSH (push) — data packet. Full request line + headers + JSON body.

```
20:08:57.961879 IP6 ::1.8080 > ::1.50625: Flags [P.], seq 1:204, length 203: HTTP: HTTP/1.1 201 Created
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 90

{"id":6,"title":"trace me","body":"in flight","created_at":"2026-09-17T17:08:57.960717Z"}
```
↑ **HTTP response** — server returns 201 Created with the new note's JSON.

```
20:08:57.961997 IP6 ::1.50625 > ::1.8080: Flags [F.], seq 175, ...
20:08:57.962018 IP6 ::1.8080 > ::1.50625: Flags [.], ack 176, ...
20:08:57.962032 IP6 ::1.8080 > ::1.50625: Flags [F.], seq 204, ...
20:08:57.962048 IP6 ::1.50625 > ::1.8080: Flags [.], ack 205, ...
```
↑ **Connection close** — graceful FIN/ACK exchange: each side sends FIN, receives ACK. No RST.

Full trace: [lab4-trace.txt](lab4-trace.txt)

### 1.3 — Five debugging commands

**1. What's listening?**
```
$ lsof -iTCP:8080 -sTCP:LISTEN
COMMAND     PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 56526 witch    5u  IPv6 0x127f95b9e92e4695      0t0  TCP *:http-alt (LISTEN)
```
Note: macOS lacks `iproute2`/`ss`, so `lsof` is used instead. Process `quicknote` (56526) listens on IPv6 :8080. The `*` means it accepts both IPv4 and IPv6 connections.

**2. Routes from this host:**
```
$ netstat -rn | head -20
Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            192.168.1.1        UGScg                 en0       
127                127.0.0.1          UCS                   lo0       
127.0.0.1          127.0.0.1          UH                    lo0       
...
```
Note: macOS replacement for `ip route show`. Default gateway → 192.168.1.1 via en0. `127.0.0.0/8` → lo0 (loopback). Our POST request to localhost goes through `lo0`, never leaving the machine — that's why the capture was on `lo0`.

**3. Reachability:**
```
$ sudo mtr -rwc 5 127.0.0.1
Start: 2026-09-17T20:10:49+0300
HOST: Mac.dlink Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    1.2   1.2   0.9   1.4   0.2
```
Note: single hop (loopback). 0% loss, RTT ~1.2 ms.

**4. DNS works:**
```
$ dig +short example.com @1.1.1.1
172.66.147.243
104.20.23.154
```
Note: public resolver Cloudflare (1.1.1.1) returns two A records for example.com. DNS is functional.

**5. Service logs:**
```
$ tail -20 /tmp/qn.log
2026/09/17 19:59:24 quicknotes listening on :8080 (notes loaded: 5)

$ log show --last 2m --predicate 'process == "quicknote"' | tail -20
(empty)

$ pgrep -fl quicknote
56526 /var/folders/.../go-build.../exe/quicknotes
```
Note: macOS lacks `journalctl`. QuickNotes logs only its startup line; per-request logging isn't implemented. `go run` compiles to a temp dir and runs from there — visible in `pgrep` output.

### 1.4 — Reflection: debugging a 502 on QuickNotes

A `502 Bad Gateway` means QuickNotes is *not* the endpoint we reached — a proxy 
(Caddy, nginx, cloud load balancer) tried to forward our request to an upstream 
QuickNotes instance and failed. So the first thing to check is **not** the HTTP 
server itself, but the path between proxy and upstream. I'd walk the chain in 
this order: (1) `lsof -iTCP:8080 -sTCP:LISTEN` on the host running QuickNotes — 
is it actually listening, and on which interface? A service bound to `127.0.0.1` 
only is unreachable from a proxy on another host; a service not listening at all 
explains the 502 immediately. (2) `curl -v http://<upstream>:8080/health` from 
the *proxy's* perspective — this isolates network reachability and firewall rules 
from application errors. (3) Check the proxy's own logs (`journalctl -u caddy -n 
100` or `/var/log/nginx/error.log`) — they record the *specific* upstream error 
(connection refused, timeout, TLS handshake failure), which instantly narrows 
the diagnosis. (4) `ss -tnp state established '( dport = :8080 or sport = :8080 )'` 
— is a TCP session even being established, or does it die at SYN? Only after 
ruling out network-layer problems would I look at the QuickNotes application 
logs themselves — at that point, 502 usually means the process started but 
crashed mid-request, or its upstream dependency (a database, the notes file) 
is unavailable. The meta-lesson: 502 is a **proxy-to-upstream** error, so 
debug it as such — never start by reading the application's own logs.



## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1 — Reproducing the broken instance

Ran a second QuickNotes instance on the same port while the first was still running:

```bash
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log
```

Output:
```
2026/09/17 20:12:58 quicknotes listening on :8080 (notes loaded: 6)
2026/09/17 20:12:58 listen: listen tcp :8080: bind: address already in use
exit status 1
```

Note: QuickNotes prints "listening on :8080" *before* it actually calls 
`bind()` — so the first line is misleading. The real failure is on the second line.

### 2.2 — Outside-in debugging chain

**Step 1 — Is the process running?**
```bash
ps -ef | grep quicknotes | grep -v grep
```
```
  501 56526 56520   0  7:59   ttys000    0:00.02 /var/folders/.../quicknotes
```
**Decision:** only ONE quicknotes process exists — the original. The second 
instance never appeared in the process list, so it either failed to start or 
crashed immediately. Next check: is the port occupied?

**Step 2 — Who is listening on the port?**
```bash
lsof -iTCP:8080 -sTCP:LISTEN
```
```
COMMAND     PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 56526 witch    5u  IPv6 0x127f95b9e92e4695      0t0  TCP *:http-alt (LISTEN)
```
**Decision:** port :8080 is already held by PID 56526. This is the root cause: 
`bind()` on an occupied port returns `EADDRINUSE`. Next: verify the existing 
instance actually serves traffic (distinguish "port held by a zombie" from 
"port held by a healthy service").

**Step 3 — Does the service respond?**
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
```
```
200
```
**Decision:** the running instance is healthy. The problem is not the 
application itself but a port conflict. Next: rule out firewall issues 
(paranoia check).

**Step 4 — Is a firewall blocking?**
```bash
sudo pfctl -s rules
```
```
scrub-anchor "com.apple/*" all fragment reassemble
anchor "com.apple/*" all
```
**Decision:** only default Apple anchors, no user `block` rules. macOS `pf` 
is not the culprit. (On Linux this step would be `iptables -L -n -v` or 
`nft list ruleset`.)

**Step 5 — Does DNS work?**
```bash
dig +short localhost
```
```
127.0.0.1
```
**Decision:** localhost resolves correctly. DNS is not the problem — and it 
would not matter anyway, since `localhost` comes from `/etc/hosts` and never 
touches the network.

### 2.3 — Repair + re-verify

```bash
kill 56526        # stop the original instance
kill 56520 2>/dev/null   # also reap the parent `go run`
sleep 2
lsof -iTCP:8080 -sTCP:LISTEN    # empty — port is free

ADDR=:8080 go run . > /tmp/qn-fixed.log 2>&1 &
sleep 4
cat /tmp/qn-fixed.log
curl -s http://localhost:8080/health | jq
```
```
2026/09/17 20:15:10 quicknotes listening on :8080 (notes loaded: 6)
{
  "notes": 6,
  "status": "ok"
}
```
After freeing the port, the new instance started successfully and served 
requests. The `notes: 6` value confirms that the previous POST created a 
persistent note — state survives restarts via `notes.json`.

### 2.4 — Root cause + blameless mini-postmortem

**Root cause:** `bind: address already in use` — the port `:8080` was held 
by a previous QuickNotes process that the operator had forgotten to stop. 
Both instances used the same hardcoded default `ADDR`.

**Mini-postmortem (≤200 words, blameless):**

> The failure was systemic, not a personal mistake. The service hardcoded 
> a single default port, had no startup guard to detect and report port 
> conflicts cleanly, and there was no process supervisor to ensure only 
> one instance ran at a time. When a second instance was started manually, 
> the kernel correctly refused `bind()`, but the error surfaced only in 
> the second instance's stderr — easy to miss when running in the 
> background. Tooling that would prevent this class of failure:
> (1) a systemd/launchd unit with `Restart=on-failure` and port-conflict 
> awareness, so the supervisor owns the port lifecycle; 
> (2) reading `ADDR` from env with a unique default per environment 
> (dev :8080, alt :8081) to avoid collisions when two devs share a host; 
> (3) structured startup logging — the misleading "listening on :8080" 
> line before `bind()` should not exist. The takeaway is that "one 
> process per port" is a real invariant that should be enforced by the 
> platform, not by operator memory.
