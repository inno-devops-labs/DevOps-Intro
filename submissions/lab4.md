# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

Environment: Windows 11 host + **WSL2 (Ubuntu, kernel 6.6)**. QuickNotes runs in
WSL on `:8080`; all captures and tools (`tcpdump`, `ss`, `dig`, `mtr`,
`journalctl`) run inside WSL. The full capture sequence is scripted in
[`lab4-capture.sh`](lab4-capture.sh).

> Note on Go: WSL's system Go is 1.22 but QuickNotes' `go.mod` requires 1.24, so
> a user-local Go 1.24 (`~/go124`) is used with `GOTOOLCHAIN=local`.

---

## Task 1 — Trace a Request End-to-End

### 1.1–1.2: Capture + decode

One `POST /notes` was captured on `lo` and decoded. `curl` resolved `localhost`
to **IPv6 `::1`**, so the whole exchange rides the IPv6 loopback. Raw capture:
[`lab4-trace.txt`](lab4-trace.txt); verbose client side:
[`lab4-curl.txt`](lab4-curl.txt). Annotated (timestamps trimmed, byte-dumps
removed):

```text
# ── TCP three-way handshake ───────────────────────────────────────────
::1.48708 > ::1.8080: Flags [S],  seq 4292351501                       # SYN
::1.8080 > ::1.48708: Flags [S.], seq 930453344, ack 4292351502        # SYN/ACK
::1.48708 > ::1.8080: Flags [.],  ack 1                                 # ACK  → connection established

# ── HTTP request (client → server) ────────────────────────────────────
::1.48708 > ::1.8080: Flags [P.], seq 1:175, length 174: POST /notes HTTP/1.1
    Host: localhost:8080
    Content-Type: application/json
    Content-Length: 39

    {"title":"trace me","body":"in flight"}
::1.8080 > ::1.48708: Flags [.], ack 175                               # server ACKs the request bytes

# ── HTTP response (server → client) ───────────────────────────────────
::1.8080 > ::1.48708: Flags [P.], seq 1:206, length 205: HTTP/1.1 201 Created
    Content-Type: application/json
    Content-Length: 92

    {"id":8,"title":"trace me","body":"in flight","created_at":"2026-06-16T17:56:25.49840222Z"}
::1.48708 > ::1.8080: Flags [.], ack 206                               # client ACKs the response

# ── Connection close (graceful 4-way FIN) ─────────────────────────────
::1.48708 > ::1.8080: Flags [F.], seq 175, ack 206                     # client FIN
::1.8080 > ::1.48708: Flags [F.], seq 206, ack 176                     # server FIN
::1.48708 > ::1.8080: Flags [.],  ack 207                              # client final ACK → closed
```

The whole request/response completed in ~9 ms (`20:56:25.497005` →
`20:56:25.506304`). Note Go's HTTP server sent the response and then the client
initiated the close (`FIN`), a clean shutdown — no `RST`.

### 1.3: The five debugging commands

```text
### 1. ss -tlnp | grep :8080   — what's listening?
LISTEN 0  4096  *:8080  *:*  users:(("quicknotes",pid=1300,fd=3))

### 2. ip route show           — routes from this host
default via 172.28.16.1 dev eth0 proto kernel
172.28.16.0/20 dev eth0 proto kernel scope link src 172.28.27.7

### 3. mtr -rwc 5 localhost     — reachability over lo
HOST: rikire    Loss%  Snt  Last  Avg  Best  Wrst StDev
  1.|-- localhost  0.0%    5   0.0  0.0   0.0   0.0   0.0

### 4. dig +short example.com @1.1.1.1   — DNS works?
172.66.147.243
104.20.23.154

### 5. journalctl --user -u quicknotes -n 20   — service logs
-- No entries --
```

Reading them:
- **`ss`** confirms `quicknotes` (pid 1300) owns `:8080` on all interfaces
  (`*:8080`) — that's why both `::1` and `127.0.0.1` connect.
- **`ip route`** shows WSL's NAT'd network: default gateway `172.28.16.1` on
  `eth0`. Loopback traffic to `::1`/`127.0.0.1` never touches this route.
- **`mtr`** to `localhost` is a single hop with **0% loss** — `lo` is healthy.
- **`dig`** resolves `example.com` via Cloudflare's `1.1.1.1` — external DNS
  works, so a name-resolution failure isn't on the table.
- **`journalctl --user -u quicknotes`** is empty because QuickNotes runs via
  `go run`, not as a systemd unit — there is no journald unit, its logs go to
  stdout. (Documented, not an error.)

### 1.4: What would I check first if QuickNotes returned 502?

A **502 Bad Gateway comes from a reverse proxy in front of the app, not from the
app itself** — it means the proxy could not get a valid response from its
upstream. So my first move is to stop trusting the proxy's error and check the
upstream directly. I'd run `ss -tlnp | grep :8080` to confirm QuickNotes is
actually *listening* and on the address the proxy expects (a classic 502 is the
app bound to `127.0.0.1` while the proxy dials it on another interface, or the
process having crashed and nothing listening at all). Then I'd `curl -v` the app
**directly, bypassing the proxy** — if that returns `201/200`, the fault is the
proxy's upstream config or a timeout; if it fails too, the app is the problem and
I go to its logs (stdout / `journalctl`). In short: confirm *listening →
reachable directly → app logs*, in that order, and only then look at the proxy's
own config and logs.

---

## Task 2 — Outside-In Debugging on a Broken Deploy

Scripted in [`lab4-debug.sh`](lab4-debug.sh); raw output in
[`lab4-task2.txt`](lab4-task2.txt).

### 2.1: The broken instance

Two instances were started on the same port. The first binds `:8080`; the second
fails immediately:

```text
2026/06/16 21:04:17 quicknotes listening on :8080 (notes loaded: 8)
2026/06/16 21:04:17 listen: listen tcp :8080: bind: address already in use
exit status 1   # second instance, exit code 1
```

(QuickNotes logs "listening" *before* it actually calls `ListenAndServe`, so the
optimistic line prints first and the real bind error follows — a small logging
gotcha worth knowing when reading these traces.)

### 2.2: The outside-in chain

| Step | Command | Output | Decision |
|------|---------|--------|----------|
| 1. Running? | `ps -ef \| grep quicknotes` | `go run .` (pid 1795) + child binary `quicknotes` (pid 1898) | A process *is* up — move inward. |
| 2. Listening? | `ss -tlnp \| grep 8080` | `LISTEN *:8080 users:(("quicknotes",pid=1898,fd=3))` | Socket is bound by pid 1898. Not a "nothing listening" case. |
| 3. Reachable? | `curl -s -o /dev/null -w "%{http_code}" …/health` | `HTTP 200` | The *surviving* instance is healthy and serving. |
| 4. Firewall? | `sudo iptables -L -n -v` / `nft list ruleset` | _(see below)_ | Rule out L3/L4 filtering. |
| 5. DNS? | `dig +short localhost` | `127.0.0.1` (from `/etc/hosts`) | Name resolution is fine — not DNS. |

Step 4 — firewall ruleset (needs root):

```text
$ sudo iptables -L -n -v; sudo nft list ruleset
sudo: iptables: command not found
sudo: nft: command not found
```

On this WSL2 instance neither `iptables` nor `nft` is installed, so there is **no
packet-filtering layer at all** — a firewall can't be blocking traffic because
there's nothing here to enforce rules. That immediately rules out L3/L4 filtering
as a cause.

**Conclusion of the chain:** every layer for the *running* instance is green
(process up → listening → reachable → no firewall → DNS fine). The "broken
deploy" is the **second** process, which never got to serve because the port was
already owned. The outside-in walk localizes the fault to **bind time**, not the
network or DNS.

### 2.3: Repair + re-verify

Kill the conflicting instance, restart a single one, re-check health:

```text
after repair, /health = {"notes":8,"status":"ok"}
```

### Root cause

`listen tcp :8080: bind: address already in use` — a **port conflict**: two
processes were told to own the same TCP port; the kernel grants `:8080` to the
first to `bind()` and rejects the second with `EADDRINUSE`.

### Mini-postmortem (blameless)

*What happened.* A second QuickNotes process was started on a port the first
already held; it exited non-zero with `EADDRINUSE` and served no traffic.

*What's systemic — not a person's mistake.* Nothing **prevented** launching a
second copy onto an occupied port, and the only signal was one easily-missed log
line. Manual `go run`/`./binary` starts have no notion of "this service already
runs here," no health gate, no restart policy. The failure is latent in *how the
service is run*, not in who ran it.

*What tooling would prevent it.* Run it under a supervisor — a **systemd unit**
on a fixed port can't be silently double-started: the second start fails loudly
in `systemctl status` / `journalctl`. Add a **pre-flight port check** and a
**readiness probe** to deploy scripts so "didn't bind" surfaces at once.
**Containerizing** gives each instance its own network namespace, or a port
mapping that conflicts loudly at `docker run`. A **rolling deploy with health
checks** replaces "start another copy and hope" with "start, verify, shift
traffic." Make the conflict impossible, or impossible to ignore — never "be more
careful."

## Bonus — Decode the TLS Handshake

QuickNotes speaks plaintext HTTP, so I put a **TLS-terminating reverse proxy** in
front of it. Instead of Caddy (not in Ubuntu's default repos) I used a 20-line Go
proxy ([`lab4-tlsproxy.go`](lab4-tlsproxy.go)) with a self-signed cert — fewer
moving parts, same handshake. I decoded the capture with **`tshark` (CLI)** and
**`openssl s_client`** rather than the Wireshark GUI; the data is identical.
Scripted in [`lab4-tls.sh`](lab4-tls.sh).

```text
:8443  (Go TLS reverse proxy, terminates TLS)  ──►  :8080  (QuickNotes, plain HTTP)
```

`curl -vk https://localhost:8443/health` → `{"notes":8,"status":"ok"}` — TLS
terminated, request proxied, `200 OK` over HTTP/2. Full client trace:
[`lab4-tls-curl.txt`](lab4-tls-curl.txt); cert dump:
[`lab4-tls-cert.txt`](lab4-tls-cert.txt).

### ClientHello (frame 4)

| Field | Value |
|-------|-------|
| SNI (`server_name`) | `localhost` |
| `legacy_version` | TLS 1.2 (`0x0303`) — frozen by spec; record layer even shows `0x0301` for middlebox compat |
| **`supported_versions` ext** | **TLS 1.3 (`0x0304`), TLS 1.2 (`0x0303`)** — note: **no 1.0/1.1 offered** |
| Cipher suites offered | 35 total: the three TLS 1.3 AEAD suites (`TLS_AES_256_GCM_SHA384`, `TLS_CHACHA20_POLY1305_SHA256`, `TLS_AES_128_GCM_SHA256`) followed by TLS 1.2 ECDHE/DHE/RSA suites |

### ServerHello (frame 6)

| Field | Value |
|-------|-------|
| `legacy_version` | TLS 1.2 (`0x0303`) |
| **`supported_versions` ext (selected)** | **TLS 1.3 (`0x0304`)** |
| Chosen cipher | **`TLS_AES_128_GCM_SHA256` (`0x1301`)** |
| Key exchange / sig (from `curl`/`openssl`) | X25519 ECDHE / RSASSA-PSS |

Negotiated result (`curl` + `openssl s_client`):
`TLSv1.3 / TLS_AES_128_GCM_SHA256 / X25519 / RSASSA-PSS`, ALPN → `h2`.

### Certificate chain

```text
subject = CN = localhost
issuer  = CN = localhost          # self-signed (verify code 18)
Public key: RSA 2048, signed with sha256WithRSAEncryption
notBefore = Jun 16 18:11:03 2026 GMT
notAfter  = Jun 17 18:11:03 2026 GMT   # 1-day cert
```

**Why the cert came from `openssl`/`curl`, not the pcap:** in TLS 1.3 the
`Certificate` message is sent **inside the encrypted flight** (after
ServerHello + key exchange), so it is *not* visible as plaintext in
`lab4-tls.pcap` — `tshark` only sees `Application Data`. That's exactly why the
task pairs the capture with `openssl s_client -showcerts`: the cert chain lives
behind encryption now. (Under TLS 1.2 the certificate was sent in the clear.)

### Which negotiation step kills TLS 1.0 / 1.1 in 2026?

The **`supported_versions` extension (RFC 8446)**. Since TLS 1.3, the real
version is no longer the `legacy_version` field in the record/handshake header —
that's permanently pinned to `0x0303` (TLS 1.2) for backward compatibility with
old middleboxes. The actual negotiation happens in `supported_versions`: the
client lists the versions it will accept, and the server picks one from that
list. In this capture the client advertised **only `0x0304` and `0x0303`** — TLS
1.0 (`0x0301`) and 1.1 (`0x0302`) are simply absent — and the Go server sets
`MinVersion: TLS 1.2`. So a 1.0/1.1 session can never be selected: the client
won't offer it and the server won't accept it. The deprecation is enforced *at
the `supported_versions` step*, by both ends refusing to put the old versions on
the table — not by some later "downgrade" rejection.

> Optional: the same handshake can be opened in the Wireshark GUI from
> `lab4-tls.pcap` for screenshots; the CLI decode above is the same data.
