# Lab 4 Submission — OS & Networking: Trace, Debug, and Read the Substrate

> Decoded packet/HTTP trace: [lab4-trace.txt](lab4-trace.txt).
> Command outputs below marked _(regenerate on your machine)_ are examples and
> must be replaced with output from your own host; `tcpdump`, `journalctl`, and the
> firewall commands need `sudo`.

---

## Task 1 — Packet Capture Analysis

### 1.1 Capture a `POST /notes` to `localhost:8080`

```bash
# Terminal 1
cd app/ && go run .

# Terminal 2 (root)
sudo tcpdump -i lo -n -s 0 -w lab4.pcap 'tcp port 8080'

# Terminal 3
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"lab4","body":"trace me"}'

# decode
tcpdump -r lab4.pcap -n -tttt -S > lab4-trace.txt
```

The decoded, annotated trace is in [lab4-trace.txt](lab4-trace.txt). It marks:

- **TCP three-way handshake** — `SYN` → `SYN,ACK` → `ACK`. The client picks an
  ephemeral source port, both sides exchange initial sequence numbers, and the
  connection reaches `ESTABLISHED`.
- **HTTP request** — a `PSH,ACK` segment carrying `POST /notes HTTP/1.1`, the
  headers, and the 34-byte JSON body; the server `ACK`s the bytes.
- **HTTP response** — a `PSH,ACK` from the server carrying `HTTP/1.1 201 Created`
  and the 88-byte JSON note; the client `ACK`s it.
- **Connection closure** — `FIN`/`ACK` from each side (the active closer enters
  `TIME_WAIT`).

The HTTP layer in the trace is the real exchange this app produced (verified with
`curl -v`): request `POST /notes` with `Content-Length: 34`, response
`201 Created` with `Content-Length: 88`.

### 1.2 Five diagnostic commands

**`ss` — listening sockets / who owns :8080** _(regenerate on your machine)_
```text
$ ss -tlnp | grep 8080
LISTEN 0  4096  *:8080  *:*  users:(("quicknotes",pid=31519,fd=3))
```
Shows the app is listening on all interfaces, port 8080, with the owning PID/fd.

**`ip route` — routing table** _(regenerate on your machine)_
```text
$ ip route
default via 10.247.1.1 dev eno1 proto dhcp src 10.247.1.173 metric 100
10.247.1.0/24 dev eno1 proto kernel scope link src 10.247.1.173 metric 100
```
Shows the default gateway and per-interface subnets — i.e. how egress traffic is
routed. Loopback traffic to `127.0.0.1` never leaves the host.

**`mtr` — hop-by-hop path + loss** _(regenerate on your machine)_
```text
$ mtr -rwc 5 127.0.0.1
HOST: myhost            Loss%  Snt  Last  Avg
1.|-- localhost          0.0%    5   0.1   0.1
```
For localhost it's a single hop; against a remote host it combines traceroute +
ping to localise latency/loss per hop.

**`dig` — DNS resolution** _(real output from this host)_
```text
$ dig localhost
;; ANSWER SECTION:
localhost.   0   IN   A   127.0.0.1
```
Confirms `localhost` resolves to `127.0.0.1` (loopback). Useful to prove name
resolution isn't the cause of a connection problem.

**`journalctl` — service logs** _(regenerate on your machine; needs sudo for system units)_
```text
$ journalctl -u quicknotes --no-pager -n 20
# (if running under systemd; otherwise check the foreground log)
quicknotes listening on :8080 (notes loaded: 4)
```
Surfaces start-up, crash, and OOM messages with timestamps — the first place to
look when a service "isn't responding."

### 1.3 Reflection — first steps for a 502

A **502 Bad Gateway** means a *reverse proxy* (nginx/Caddy/LB) accepted the client
connection but got an invalid/empty response — or no connection — from the
**upstream**. So 502 is almost never the proxy itself; it points at the backend.
First steps, outside-in: (1) confirm the proxy is up and which upstream it targets;
(2) on the backend host, `ss -tlnp` to check the app is actually **listening** on
the expected port and address (a bind to `127.0.0.1` when the proxy connects over
the network is a classic 502); (3) `curl -v http://<upstream>:<port>/health`
directly, bypassing the proxy, to isolate proxy-vs-app; (4) `journalctl`/app logs
for crashes, panics, or slow startup; (5) check timeouts and that the backend isn't
returning before headers. If the app is healthy directly but the proxy 502s, suspect
networking/firewall between proxy and upstream, or a wrong upstream address/port.

---

## Task 2 — Debugging a Deliberately-Broken Deployment

### 2.1 Reproduce the port-binding failure

Run two instances on the same address:
```bash
# Terminal 1
cd app/ && ADDR=:8080 go run .          # binds :8080 OK
# Terminal 2
cd app/ && ADDR=:8080 go run .          # second instance
```
The second process fails to start:
```text
listen: listen tcp :8080: bind: address already in use
```
_(Paste your real terminal output / screenshot here.)_

### 2.2 Outside-in diagnostic chain

| Step | Command | What it tells you |
|------|---------|-------------------|
| Process status | `ps aux \| grep quicknotes` | Is a process running? How many? |
| Listening ports | `ss -tlnp \| grep 8080` | Who already owns `:8080` (PID/fd) |
| HTTP reachability | `curl -v http://localhost:8080/health` | Does the *first* instance answer? |
| Firewall rules | `sudo nft list ruleset` or `sudo iptables -L -n` | Is traffic being dropped/rejected? |
| DNS | `dig localhost` / `getent hosts localhost` | Does the name resolve correctly? |

Typical findings: `ps` shows one healthy instance plus one that exited; `ss` shows a
single `LISTEN` on `:8080` owned by the first PID; `curl` to `/health` returns
`200 {"status":"ok"}` from that first instance; firewall is empty/allow; DNS is
fine. The failing second process never bound a socket.

### 2.3 Root cause

`SO_REUSEADDR` does not let two processes share the same `(addr, port)` for
listening, so the **second** `bind()` on `:8080` returns `EADDRINUSE`. The root
cause is **two instances configured with the same listen address** — an operational
mistake (duplicate start, or a restart before the old process released the socket),
not a code bug. Fix: run one instance per port, or give the second a different
`ADDR` (e.g. `ADDR=:8081`).

### 2.4 Blameless postmortem (≤200 words)

**Incident.** A second QuickNotes instance was started on `:8080` while the first
still held the socket; the new process exited with `bind: address already in use`,
leaving the deploy in a confusing half-state.

**Impact.** No user-facing outage — the original instance kept serving — but the
deploy appeared "failed" and consumed on-call time to diagnose.

**Why it happened (systemic, not personal).** Nothing prevented two processes from
claiming the same port: the listen address is a free-form env var with no
preflight check, there was no process supervisor enforcing a single instance, and
the error surfaced only as a generic kernel message far from its cause.

**What would prevent recurrence.** (1) Run under a supervisor (systemd unit /
container) so a single managed instance owns the port and restarts are serialised.
(2) Add a startup preflight that checks the port is free and logs an actionable
message. (3) Make `ADDR` explicit per environment and validate it in CI/CD. (4) Use
health checks before declaring a deploy successful. The aim is to make the failure
*impossible* or *self-explanatory*, not to blame whoever ran the command.

---

## Bonus Task — TLS Handshake Decode (optional, +2)

<!-- TODO if attempting: capture in Wireshark and paste screenshots/output. -->

### Caddy reverse proxy with HTTPS on :8443

`Caddyfile`:
```text
localhost:8443 {
    reverse_proxy 127.0.0.1:8080
}
```
```bash
caddy run --config Caddyfile
sudo tcpdump -i lo -n -w tls.pcap 'tcp port 8443'      # capture
curl -vk https://localhost:8443/health                  # generate handshake
```

### What to annotate in Wireshark

- **ClientHello** — client's offered TLS versions, cipher suites, SNI
  (`localhost`), and the `supported_versions` extension advertising TLS 1.3.
- **ServerHello** — the version/cipher the server *selected* (expect TLS 1.3,
  `TLS_AES_128_GCM_SHA256` or similar) and the chosen key-share.
- With TLS 1.3 the certificate is **encrypted**; note that the handshake completes
  in 1-RTT (no separate ServerKeyExchange/Finished in cleartext like TLS 1.2).

### Certificate chain
```bash
openssl s_client -connect localhost:8443 -servername localhost -showcerts </dev/null
```
Paste the chain (leaf → intermediate → root). With Caddy's local CA the leaf is
issued by Caddy's local authority.

### TLS deprecation in 2026

TLS **1.0 and 1.1** were formally deprecated by **RFC 8996 (2021)** and are being
removed from remaining clients/servers; modern stacks negotiate **TLS 1.3** (as the
capture should show) and treat 1.0/1.1 as forbidden.
<!-- TODO: confirm against the Lecture 4 slide which exact deprecation it cites for
2026 (e.g. an end-of-support / compliance date) and state that version + date here. -->

---

## Submission Checklist

- [ ] `submissions/lab4.md` (this file) with annotated capture summary + 5 commands + 502 reflection
- [ ] `submissions/lab4-trace.txt` with your real decoded `tcpdump` output
- [ ] Task 2: reproduced port conflict, outside-in chain outputs, root cause, postmortem (≤200 words)
- [ ] (Bonus) Wireshark ClientHello/ServerHello + `openssl s_client` chain + TLS deprecation note
- [ ] PR `feature/lab4 → main` opened against **upstream** and against **your fork**
- [ ] Both PR URLs submitted to Moodle
