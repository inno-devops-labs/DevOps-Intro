# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

> Capture-and-analyze methodology: each `tcpdump` capture is self-terminating
> (`-c <count>` packet cap with a `timeout` backstop and `-U` unbuffered writes),
> so the `.pcap` is always flushed to disk before analysis. The capture is then
> decoded offline with `tcpdump -r` / `tshark -r`, never by re-triggering the bug.
> Host: native Linux x86_64 (kernel 6.17.0-20-generic).

---

## Task 1 — Trace a Request End-to-End

### 1.1 Start QuickNotes + capture

QuickNotes is started from the built binary on `:8080`:

```bash
cd app/
ADDR=:8080 ./quicknotes
# 2026/06/17 04:40:34 quicknotes listening on :8080 (notes loaded: 4)
```

Capture on the loopback interface with a self-terminating packet cap so no
manual `kill` is needed and the `.pcap` is always complete on disk:

```bash
sudo timeout -s INT 20 tcpdump -i lo -nn -s 0 -U -c 200 \
  -w lab4-trace.pcap 'tcp port 8080' &
# wait for tcpdump to arm, then fire exactly one request:
curl -sS -o /tmp/curl-T1-body.txt -w "HTTP_CODE=%{http_code}\n" \
  -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
# HTTP_CODE=201
# {"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T20:48:23.232463298Z"}
```

The capture self-terminates after the packet cap / timeout; `lab4-trace.pcap`
(1440 bytes, 10 packets) is decoded below.

### 1.2 Decode the capture

```bash
sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt
```

Annotated `lab4-trace.txt` (10 packets, IPv6 loopback `::1`):

#### TCP three-way handshake

```
04:48:23.232241 IP6 ::1.48000 > ::1.8080: Flags [S],   seq 2534835882, ...   # ① client SYN
04:48:23.232260 IP6 ::1.8080 > ::1.48000: Flags [S.],  seq ..., ack 2534835883 ... # ② server SYN/ACK
04:48:23.232275 IP6 ::1.48000 > ::1.8080: Flags [.],   ack 1, ...           # ③ client ACK  → ESTABLISHED
```

#### HTTP request — `POST /notes` + JSON body

```
04:48:23.232313 IP6 ::1.48000 > ::1.8080: Flags [P.], length 174: HTTP: POST /notes HTTP/1.1
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.5.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
04:48:23.232318 IP6 ::1.8080 > ::1.48000: Flags [.], ack 175, ...   # server ACKs the request
```

#### HTTP response — `201 Created` + response JSON

```
04:48:23.232772 IP6 ::1.8080 > ::1.48000: Flags [P.], length 206: HTTP: HTTP/1.1 201 Created
HTTP/1.1 201 Created
Content-Type: application/json
Date: Tue, 16 Jun 2026 20:48:23 GMT
Content-Length: 93

{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T20:48:23.232463753Z"}
04:48:23.232782 IP6 ::1.48000 > ::1.8080: Flags [.], ack 207, ...   # client ACKs the response
```

#### Connection close — 4-way FIN exchange (clean close, no RST)

```
04:48:23.232917 IP6 ::1.48000 > ::1.8080: Flags [F.], seq 175, ack 207, ...  # ④ client FIN (curl done sending)
04:48:23.232948 IP6 ::1.8080 > ::1.48000: Flags [F.], seq 207, ack 176, ...  # ⑤ server FIN
04:48:23.232964 IP6 ::1.48000 > ::1.8080: Flags [.], ack 208, ...            # ⑥ client final ACK → TIME_WAIT
```

**End-to-end timeline (all within the same millisecond, `04:48:23.232xxx`):**
handshake (~0.034 ms) → request → response (~0.459 ms server-side processing)
→ clean FIN/FIN/ACK teardown. Total wall time ≈ 0.7 ms. The request is
delivered in a single `PSH` segment (174 B), the response likewise (206 B);
no segmentation, no retransmission, no TCP options missing — a textbook
loopback HTTP transaction.

### 1.3 The five debugging commands

#### 1. `ss -tlnp | grep :8080` — what's listening?

```
LISTEN 0      4096                    *:8080             *:*    users:(("quicknotes",pid=24752,fd=3))
```
QuickNotes is listening on `*:8080` (all interfaces, IPv4+IPv6 via the
dual-stack wildcard), PID 24752, socket fd 3, accept backlog 4096. *Why run
it:* confirms the process is actually bound and accepting — the L4 "is it
there?" answer before anything else.

#### 2. `ip route show` — routes from the host

```
default via 192.168.0.1 dev wlp2s0 proto dhcp src 192.168.0.9 metric 600
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
172.18.0.0/16 dev br-ed4c4e62a95e ... linkdown
172.19.0.0/16 dev br-99c97985a57d ... linkdown
172.20.0.0/16 dev br-9a5690048b24 ... linkdown
172.21.0.0/16 dev br-53cd28200819 proto kernel scope link src 172.21.0.1
172.22.0.0/16 dev br-6a4c577368cb ... linkdown
192.168.0.0/24 dev wlp2s0 proto kernel scope link src 192.168.0.9 metric 600
```
Default route is via the home gateway `192.168.0.1` over Wi-Fi (`wlp2s0`,
`192.168.0.9`); several Docker bridges exist (one active, the rest `linkdown`).
*Why run it:* a 502 against a remote backend often starts with "does my routing
even point at the right interface?" — this answers L3 reachability.

#### 3. `mtr -rwc 5 localhost` — reachability over loopback

```
Start: 2026-06-17T04:54:02+0800
HOST: fleter    Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.0   0.1   0.0   0.1   0.0
```
0% loss, ~0.1 ms avg to `localhost`. *Why run it:* confirms the path to the
service host is intact at L3/L4 before blaming the application. (For a remote
backend this would also reveal the hop where packets die — e.g. the Facebook
BGP outage looked exactly like "100% loss past the edge router".)

#### 4. `dig +short example.com @1.1.1.1` — DNS works?

```
172.66.147.243
104.20.23.154
```
Cloudflare's resolver returns two A records for `example.com`. *Why run it:*
"it's never DNS" until it is — a 502 on a hostname often resolves (no pun) to
a stale/missing DNS record. Querying an authoritative-ish resolver directly
removes the local stub resolver from the suspect list.

#### 5. `journalctl --user -u quicknotes -n 20` — service logs

```
-- No entries --
```
QuickNotes is **not** installed as a `systemd --user` unit in this lab (it runs
as a bare process), so the journal has no entries for it; the real logs are on
the process's stdout (`/tmp/quicknotes-A.log`). *Why run it:* the journal is the
canonical "what did the service say about itself?" source when it *is*
unit-managed — checking it is reflex one when a 502 hits a deployed service.

### 1.4 Reflection — what would I check first if QuickNotes returned 502?

A `502 Bad Gateway` means *something in front of* QuickNotes gave up on
*something behind it*, so I check the chain from the outside in, fastest signal
first. **Step one is `curl` the service directly** (bypassing any proxy) and
read the actual status/body — if the backend itself answers 200/201 here, the
502 originates at the proxy, not the app, and I switch to the proxy's
`journalctl`/access log. If the backend is the culprit, I immediately check
`ss -tlnp` to confirm the process is **still bound** on the port the proxy
upstreams to (a crashed/restarted QuickNotes on a different port is the classic
502 cause), then `journalctl -u quicknotes` for an OOM/panic/`bind` error. DNS
and routing (`dig`, `ip route`) come next only if the proxy "can't find" the
backend by name. In short: **client status first, then "is the socket alive",
then logs — DNS/routing are confirming steps, not the first move**, because a
local bind failure or a crashed process explains ~90% of real 502s.

---

## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1 Reproduce a broken instance

The "break" is a classic port collision: a second replica tries to bind a port
the first already owns. Two instances are launched against the same `ADDR=:8080`.

**First instance — acquires the port:**
```bash
$ ADDR=:8080 ./quicknotes > /tmp/qn-first.log 2>&1 &   # PID1=30393
$ cat /tmp/qn-first.log
2026/06/17 04:55:23 quicknotes listening on :8080 (notes loaded: 4)
2026/06/17 04:55:51 shutting down        # ← later, when killed in §2.3
```

**Second instance — fails to bind:**
```bash
$ ADDR=:8080 ./quicknotes > /tmp/qn-broken.log 2>&1 &  # PID2=30449 (exits ~immediately)
$ cat /tmp/qn-broken.log
2026/06/17 04:55:30 quicknotes listening on :8080 (notes loaded: 4)   # log line fires pre-bind, in the goroutine setup
2026/06/17 04:55:30 listen: listen tcp :8080: bind: address already in use   # ← exact error
```

> Note on the misleading "listening" line: `main.go` prints it from a goroutine
> *before* calling `srv.ListenAndServe()`, so it appears even when the bind then
> fails. The authoritative signal is the **`listen:` line + process exit**.

```bash
$ ps -ef | grep "[q]uicknotes"
ilia  30393 ... ./quicknotes     # only the FIRST instance survives
$ ps -p 30449 >/dev/null || echo "exited (expected — bind failed)"
exited (expected — bind failed)
```

### 2.2 Walk the outside-in chain

For every step: **command → output → decision**.

#### Step 1 — is it running?  `ps -ef | grep quicknotes`
```bash
$ ps -ef | grep quicknotes
ilia  30393 ... ./quicknotes
```
**Decision:** *A* quicknotes process is alive (PID 30393). But "a process
exists" ≠ "the process you launched" — and crucially it's only **one** of the
two I started. The missing replica is the symptom. Proceed to confirm what's
actually bound.

#### Step 2 — is it listening?  `ss -tlnp | grep 8080`
```bash
$ ss -tlnp | grep 8080
LISTEN 0  4096  *:8080  *:*  users:(("quicknotes",pid=30393,fd=3))
```
**Decision:** Exactly **one** listener on `:8080`, and it's PID 30393 (the
first instance). The second replica never appears here because its failure was
at the socket layer — `bind()` returned `EADDRINUSE` before it could ever
`listen()`. This is the step that pins the failure to **L4, not L7**: the app
code is fine, the kernel refused the second bind.

#### Step 3 — reachable from host?  `curl /health`
```bash
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```
**Decision:** `200 OK`. The **surviving** instance serves correctly, which
narrowly scopes the incident: this is not "the service is down," it's "the
**second replica** failed to come up." In a load-balanced deploy that's the
difference between a user-visible outage and a silent capacity loss.

#### Step 4 — firewall blocking?  `iptables -L -n -v`
```bash
$ sudo iptables -L -n -v | head -20
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target prot opt in out source destination
Chain FORWARD (policy DROP ...)
 ... (only Docker bridge rules: br-53cd28200819 → 172.21.0.x ACCEPTs; two bridge DROPs)
Chain OUTPUT (policy ACCEPT ...)
```
**Decision:** `INPUT` policy is `ACCEPT` with **no DROP/REJECT rules**; the only
`DROP`s are Docker bridge isolation (`br-*`), unrelated to loopback. Firewall
is **ruled out** as the cause. (Still worth running — in a cloud deploy a
security-group/nftables rule is a top-three 502 cause, so I confirm it's clean
rather than assume.)

#### Step 5 — DNS?  `dig +short localhost`
```bash
$ dig +short localhost
127.0.0.1
```
**Decision:** `localhost` → `127.0.0.1` resolves correctly. DNS is **not** the
cause — and is in fact structurally irrelevant here, because a same-host bind
collision never touches the resolver. (Included for completeness of the chain;
the muscle memory matters for *remote*-backend 502s.)

**Chain verdict:** The failure is localized at **Step 2 (L4 bind)**, confirmed
by Step 1 (only one process), invisible-but-fine at Steps 3–5 (the survivor
serves, no firewall, no DNS issue). Root cause: `bind: address already in use`.

### 2.3 Repair + re-verify

Kill the conflicting first instance, free the port, start a fresh one:
```bash
$ kill 30393; sleep 1
$ ss -tlnp | grep :8080 || echo "port 8080 free"
port 8080 free

$ ADDR=:8080 ./quicknotes > /tmp/qn-repaired.log 2>&1 &   # PID=30620
$ cat /tmp/qn-repaired.log
2026/06/17 04:55:52 quicknotes listening on :8080 (notes loaded: 4)

$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:8080/notes \
    -H 'Content-Type: application/json' -d '{"title":"postmortem","body":"repaired"}'
201
$ ss -tlnp | grep :8080
LISTEN 0  4096  *:8080  *:*  users:(("quicknotes",pid=30620,fd=3))
```
**Re-verify:** health `200`, a fresh `POST` returns `201`, and there is again
exactly one listener (PID 30620). Repaired.

### 2.4 Root cause

```
listen tcp :8080: bind: address already in use
```
The Go `net/http` server calls `bind(2)` on `:8080`; the kernel returns
`EADDRINUSE` because the first instance already owns the `*:8080` listening
socket (absent `SO_REUSEPORT`, only one socket may `bind()` a given
`{addr,port}`). The second replica's `ListenAndServe` therefore returns a
non-nil error, `main.go` hits `log.Fatalf("listen: %v", err)`, and the process
exits. The service stays "up" only because the first replica is still serving.

### 2.5 Blameless mini-postmortem (≤ 200 words)

A second QuickNotes replica failed with `bind: address already in use` because
the first already owned `:8080`; without `SO_REUSEPORT` the kernel allows
exactly one listener per `{addr,port}`. This is **systemic**, not an operator
error: it is the *default* behavior of every process that hardcodes a port, and
it bites wherever two lifecycles share a host — a dev laptop with a leftover
`go run`, a CI runner reused across jobs, or `systemd` `Restart=` racing a slow
shutdown. The failure is also **quiet**: the surviving process answers health
checks, so a naive uptime probe reports green while capacity silently halves.
Tooling that prevents it: (1) health checks asserting **replica count**, not just
"one alive"; (2) a pre-bind port probe (`ss -ltn sport = :8080`) that refuses to
launch on an occupied port; (3) `SO_REUSEPORT` or per-instance ephemeral ports;
(4) `Type=notify` systemd units so the supervisor knows a replica never reached
`READY=1`. The port-collision class is a **tooling gap** — the fix is making the
conflict loud at start time.

---

## Bonus Task — Decode the TLS Handshake

QuickNotes speaks plaintext HTTP; this task front-ends it with a
TLS-terminating reverse proxy so the handshake becomes observable. I used
**Caddy** (auto-HTTPS via its internal CA → self-signed cert for `localhost`)
pointing at the still-running QuickNotes on `:8080`, and decoded the capture
with **`tshark`** (Wireshark's CLI; the lab's "screenshots" are reproduced here
as annotated `tshark -V` field dumps — same protocol dissection, text form).
Full field dumps are reproduced inline below.

### B.1 Add an HTTPS layer (Caddy reverse proxy)

The host already runs `nginx` on `:80` and `node` on `:443`, so the stock
Caddyfile (which adds an automatic HTTP→HTTPS redirect on `:80`) collides.
Two fixes: bind the TLS site on `localhost:8443` **only**, and disable the
`:80` redirect:

```bash
sudo apt install caddy tshark          # caddy 2.6.2, tshark 4.2.2
sudo tee /etc/caddy/Caddyfile >/dev/null <<'EOF'
{
    auto_https disable_redirects       # don't touch :80 (nginx owns it)
}

localhost:8443 {
    tls internal                        # Caddy's local CA → self-signed leaf
    reverse_proxy localhost:8080        # → QuickNotes
}
EOF
sudo systemctl restart caddy
sudo journalctl -u caddy | grep "certificate obtained"   # → "certificate obtained successfully" identifier=localhost
ss -tlnp | grep 8443                                       # → caddy on *:8443
curl -sk https://localhost:8443/health                     # → {"notes":5,"status":"ok"}
```

### B.2 Capture the TLS handshake

Same self-terminating capture style as Task 1 (packet cap + `timeout` backstop,
`-U` unbuffered, so the `.pcap` is always complete):

```bash
sudo timeout -s INT 20 tcpdump -i lo -nn -s 0 -U -c 60 \
  -w lab4-tls.pcap 'tcp port 8443' &
# … arm, then one request:
curl -sk -o /dev/null -w "%{http_code}\n" https://localhost:8443/health   # → 200
```
`lab4-tls.pcap` (4674 B, 21 packets) is decoded below.

### B.3 Decode — ClientHello, ServerHello, cert chain

Handshake overview (`tshark -r lab4-tls.pcap -Y tls`):

```
 4  ::1 → ::1   TLSv1    603  Client Hello (SNI=localhost)
 6  ::1 → ::1   TLSv1.3  1507 Server Hello, Change Cipher Spec, Application Data …
 8  ::1 → ::1   TLSv1.3  150  Change Cipher Spec, Application Data   (client Finished)
 …            (rest = encrypted Application Data, incl. cert/EE/Finished)
```

#### ➡️ ClientHello (frame 4) — annotated screenshot-equivalent

```
TLSv1 Record Layer: Handshake Protocol: Client Hello
    Version: TLS 1.2 (0x0303)                      # legacy handshake_version (compat)
    Session ID Length: 32                           # TLS 1.3 downgrade sentinel
    Cipher Suites (31 suites):
        TLS_AES_256_GCM_SHA384 (0x1302)            # ─┐ TLS 1.3 AEAD suites
        TLS_CHACHA20_POLY1305_SHA256 (0x1303)      #  │ (first three offered)
        TLS_AES_128_GCM_SHA256 (0x1301)            # ─┘
        TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 …  # then TLS 1.2 ECDHE suites
        … (no CBC-only / static-RSA-before-TLS1.2 offenders present)
    Extension: server_name … Server Name: localhost          # ← SNI
    Extension: supported_groups: x25519, secp256r1, x448 …    # key-share candidates
    Extension: supported_versions (len=5): TLS 1.3, TLS 1.2   # ← ONLY 1.3 + 1.2 offered
    Extension: ALPN: h2, http/1.1                            # ← app-layer negotiation
    Extension: signature_algorithms: ecdsa_secp256r1_sha256, ed25519, rsa_pss_*, …
```

Key fields the lab asks for:
- **TLS version offered:** `supported_versions` = **TLS 1.3, TLS 1.2** (no 1.0/1.1).
- **Cipher suites offered:** 31 suites, led by the three TLS 1.3 AEAD suites
  (`TLS_AES_256_GCM_SHA384`, `TLS_CHACHA20_POLY1305_SHA256`,
  `TLS_AES_128_GCM_SHA256`), then ECDHE TLS 1.2 suites.
- **SNI:** `localhost` (the `server_name` extension).

#### ⬅️ ServerHello (frame 6) — annotated screenshot-equivalent

```
TLSv1 Record Layer: Handshake Protocol: Server Hello
    Version: TLS 1.2 (0x0303)                      # legacy field (TLS 1.3 always says 1.2 here)
    Random: 702adec8…ee990d1                       # server_random (32 B)
    Cipher Suite: TLS_AES_128_GCM_SHA256 (0x1301)  # ← chosen cipher
    Extension: supported_versions (len=2): TLS 1.3 # ← real negotiated version: TLS 1.3
    Extension: key_share (len=36): Group x25519    # ← server's ECDHE public key
… (Change Cipher Spec, then encrypted: EncryptedExtensions[ALPN=h2], Certificate,
   CertificateVerify, Finished — all under TLS 1.3 AEAD)
```

Key fields:
- **Chosen cipher:** `TLS_AES_128_GCM_SHA256 (0x1301)`.
- **Negotiated version:** **TLS 1.3** (the `supported_versions` extension is
  authoritative in 1.3; the legacy `Version: TLS 1.2` in the record/handshake
  headers is a fixed compatibility value per RFC 8446).
- **Key exchange:** X25519 via the `key_share` extension (1-RTT, no RSA key
  transport — impossible in TLS 1.3 anyway).

#### 📜 Certificate chain — `openssl s_client -connect [::1]:8443 -servername localhost -showcerts`

```
Certificate chain
 0  s: (no CN — leaf for "localhost")              # 2026-06-16 → 2026-06-17, ECDSA P-256
    i: CN = Caddy Local Authority - ECC Intermediate
    a: id-ecPublicKey 256-bit, sigalg: ecdsa-with-SHA256
 1  s: CN = Caddy Local Authority - ECC Intermediate
    i: CN = Caddy Local Authority - 2026 ECC Root  # the local root CA
    a: id-ecPublicKey 256-bit, sigalg: ecdsa-with-SHA256
---
Protocol  : TLSv1.3
Cipher    : TLS_AES_128_GCM_SHA256
Server Temp Key: X25519, 253 bits
Verify return code: 20 (unable to get local issuer certificate)   # self-signed root not in trust store → expected
```
A two-link chain: **leaf** (CN-less, `SAN=localhost`, signed by the
intermediate) → **Caddy Local Authority - ECC Intermediate** (signed by the
**2026 ECC Root**, not sent because it's a root). Both links are ECDSA P-256.
`Verify return code 20` is expected and harmless — the Caddy local root isn't in
the system trust store; `curl -k` / `openssl` without `-CAfile` therefore can't
chain to a trusted root, which is the entire point of a *self-signed* local
setup.

`curl -vk` independently confirms the app-layer outcome: `SSL connection using
TLSv1.3 / TLS_AES_128_GCM_SHA256 / X25519`, `ALPN: server accepted h2`, and the
proxied `GET /health` returns `200 {"notes":5,"status":"ok"}`.

### B.4 Annotation — which negotiation step kills TLS 1.0 / 1.1 in 2026?

TLS 1.0 / 1.1 are eliminated at the **ClientHello `supported_versions` extension
(RFC 8446 §4.2.1) — they are never even *offered*.** In this capture the
client's `supported_versions` advertises **only `TLS 1.3 (0x0304)` and
`TLS 1.2 (0x0303)`**; `TLS 1.0 (0x0301)` / `TLS 1.1 (0x0302)` do not appear in
the list, so the server has nothing to downgrade *to*. (The lone `Version: TLS
1.0 (0x0301)` one sees in the raw `tshark` dump is the **legacy record-layer
`record_version`**, which RFC 8446 §5.1 *mandates* be `0x0301` for compatibility
with middleboxes — it is not a negotiated version and cannot enable 1.0.) This
matches the 2020/2021 deprecation by the IETF (RFC 8996) and the browser/OS
removals: modern stacks (curl 8.5 here, built on OpenSSL 3.x) simply omit 1.0/1.1
from `supported_versions`, and servers like Caddy refuse to negotiate a version
that was never offered. The server-side `supported_versions` reply then pins the
choice to **TLS 1.3**. So in 2026 the deprecation is enforced *cooperatively at
the version-advertisement step* — not by a later cipher-suites or alert
mechanism.

---
