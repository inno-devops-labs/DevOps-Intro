# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

My host is Windows, so I ran the whole lab inside **WSL2 (Ubuntu 24.04)**, which
is a real Linux kernel with a real loopback interface — so `tcpdump -i lo`, `ss`,
`dig`, and `mtr` all behave exactly as the lab expects. Go 1.26 and the net tools
(`tcpdump`, `iproute2`, `dnsutils`, `mtr`) are installed in that distro.

Two small substitutions, both equivalent to what the lab asks:
- For the Bonus I used **socat** as the TLS-terminating reverse proxy instead of
  Caddy (Caddy needs an external apt repo; socat is in Ubuntu's repos and does the
  same job — terminate TLS on `:8443`, forward to `:8080`).
- I decoded the handshake with **tshark** (Wireshark's CLI) instead of the
  Wireshark GUI, so the evidence is text I can paste here rather than screenshots.

Captured artifacts are in [`lab4-artifacts/`](lab4-artifacts/): `lab4-trace.pcap`,
`lab4-trace.txt`, `lab4-tls.pcap`, `tls-sclient.txt`.

---

## Task 1 — Trace a Request End-to-End

### 1.1 Start QuickNotes + capture + one POST

App came up: `quicknotes listening on :8080 (notes loaded: 8)`. The single
request (`curl -v -X POST .../notes`) returned **201 Created**:

```
> POST /notes HTTP/1.1
> Host: localhost:8080
> Content-Type: application/json
> Content-Length: 39
>
{"title":"trace me","body":"in flight"}

< HTTP/1.1 201 Created
< Content-Type: application/json
< Content-Length: 93
<
{"id":9,"title":"trace me","body":"in flight","created_at":"2026-06-16T18:44:28.877279214Z"}
```

curl resolved `localhost` to `::1` and used IPv6 loopback, which still rides `lo`,
so the capture picked it up. Full capture: `lab4-artifacts/lab4-trace.pcap`.

### 1.2 Decode the capture

Decoded with `tcpdump -r lab4-trace.pcap -nn -A` (full text in
[`lab4-artifacts/lab4-trace.txt`](lab4-artifacts/lab4-trace.txt)). Here is the
whole conversation, annotated — every stage the lab asks for is present:

```
# ── TCP three-way handshake ──────────────────────────────
::1.37486 > ::1.8080: Flags [S],  seq 647365548                 # SYN
::1.8080 > ::1.37486: Flags [S.], seq 4097737289, ack 647365549 # SYN/ACK
::1.37486 > ::1.8080: Flags [.],  ack 1                          # ACK

# ── HTTP request line + JSON body ────────────────────────
::1.37486 > ::1.8080: Flags [P.], seq 1:175 ... HTTP: POST /notes HTTP/1.1
    Host: localhost:8080
    Content-Type: application/json
    Content-Length: 39
    {"title":"trace me","body":"in flight"}
::1.8080 > ::1.37486: Flags [.], ack 175                         # server ACKs the request

# ── HTTP response line + response JSON ───────────────────
::1.8080 > ::1.37486: Flags [P.], seq 1:207 ... HTTP: HTTP/1.1 201 Created
    Content-Type: application/json
    Content-Length: 93
    {"id":9,"title":"trace me","body":"in flight","created_at":"2026-06-16T18:44:28.877279214Z"}

# ── Connection close (graceful FIN handshake) ────────────
::1.37486 > ::1.8080: Flags [F.], seq 175   # client FIN
::1.8080 > ::1.37486: Flags [F.], seq 207   # server FIN
::1.37486 > ::1.8080: Flags [.], ack 208    # final ACK
```

So: SYN → SYN/ACK → ACK, then the POST and its body, then `201 Created` and its
JSON, then a clean FIN/FIN/ACK close (no RST — the connection ended gracefully).

### 1.3 The five debugging commands

```
$ ss -tlnp | grep :8080
LISTEN 0  4096  *:8080  *:*  users:(("quicknotes",pid=2659,fd=3))
```
What's listening: the `quicknotes` process, on every interface, port 8080.

```
$ ip route show
default via 172.20.80.1 dev eth0 proto kernel
172.20.80.0/20 dev eth0 proto kernel scope link src 172.20.82.253
```
Routes from the host: a default route out `eth0` (the WSL NAT gateway) and the
local `/20` subnet. Loopback isn't shown here because it's a host-local route.

```
$ mtr -rwc 5 localhost
HOST: ...           Loss%  Snt  Last  Avg  Best  Wrst StDev
  1.|-- localhost   0.0%    5   0.1  0.1   0.0   0.1   0.0
```
Reachability: one hop (it never leaves the box), 0% loss, sub-millisecond.

```
$ dig +short example.com @1.1.1.1
172.66.147.243
104.20.23.154
```
DNS works: a direct query to Cloudflare's resolver returns A records.

```
$ journalctl --user -u quicknotes -n 20
-- No entries --
```
No logs, because I ran QuickNotes by hand (`go run .`), not as a systemd unit.
Expected — that's why the lab guards it with `|| true`.

### 1.4 What I'd check first on a 502

A 502 means something *in front of* QuickNotes (a proxy / load balancer) got a
connection but couldn't get a valid response from the app behind it, so the
problem is almost never the proxy — it's the upstream. I'd work the same
outside-in chain: first `ss -tlnp | grep :8080` to confirm the app is actually
listening on the port the proxy targets (a crashed or not-yet-started app is the
classic cause); if it's listening, `curl -v http://localhost:8080/health`
straight to the app to see whether it answers at all or hangs (timeout vs reset
tells me crash-loop vs slow); then the app's own logs for panics or a failing
dependency, and finally the proxy's upstream config in case it's pointed at the
wrong port or host. The packet capture is the tiebreaker: a RST means the app
refused/closed, a silent timeout means it accepted and never replied.

---

## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1 Reproduce the break

Instance #1 took `:8080`. Instance #2, started on the **same** port, died
immediately with exit code 1:

```
2026/06/16 21:46:07 quicknotes listening on :8080 (notes loaded: 9)
2026/06/16 21:46:07 listen: listen tcp :8080: bind: address already in use
```

### 2.2 The outside-in chain (command + output + decision)

```
$ ps -ef | grep -E "go run|quicknotes|exe/main" | grep -v grep
root  2659  313   ... /tmp/go-build.../exe/quicknotes     # the running app
root  2899  2894  ... go run .                            # its `go run` parent
```
Decision: a QuickNotes process *is* alive — so this isn't "nothing is running."

```
$ ss -tlnp | grep 8080
LISTEN 0  4096  *:8080  *:*  users:(("quicknotes",pid=2659,fd=3))
```
Decision: the port is held, and by pid 2659 — the *first* instance. So the new
deploy never got the socket.

```
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```
Decision: the endpoint answers 200 — but it's the *old* process answering, not my
new deploy. The "outage" is really "my new version never started."

```
$ sudo iptables -L -n -v   (|| nft list ruleset)
(no iptables/nft rules / not available in this kernel)
```
Decision: not a firewall problem — traffic isn't being filtered.

```
$ dig +short localhost          -> 127.0.0.1
$ getent hosts localhost        -> ::1   localhost
```
Decision: not DNS. (`dig` queries a DNS server and returns 127.0.0.1; the name
the app actually resolves comes from `/etc/hosts` via `getent`, which is `::1`.
Either way the name resolves fine.)

### 2.3 Repair + re-verify

Kill the conflicting first instance, start a fresh one, re-check:

```
$ curl -s http://localhost:8080/health
{"notes":9,"status":"ok"}
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```

### 2.4 Root cause + blameless mini-postmortem

**Root cause:** `bind: address already in use` — the new instance tried to bind
`:8080` while the old one still held it, so `ListenAndServe` failed and the
process exited.

**Postmortem (blameless).** Nothing here was a careless mistake; it's a systemic
gap. A process that owns a port keeps owning it until it fully exits, and a naive
"start the new one" deploy has no step that guarantees the old one is gone first.
The failure is also quiet from the outside: health checks keep returning 200
because the *old* process is still serving, so a dashboard looking only at
`/health` would show all-green while the new version never shipped. What prevents
this class of failure is tooling, not vigilance: a real process supervisor
(systemd, a container runtime, Kubernetes) that stops the old instance and waits
for the port to free before starting the new one, or a deploy model where the new
instance binds a *different* port and traffic is cut over only after its health
check passes (blue-green / rolling). A pre-start check (`ss -tlnp | grep :8080`)
that fails fast with a clear message would also have turned a silent no-op deploy
into an obvious error. The lesson is to make "is the port really free?" an
explicit, automated gate rather than an assumption. *(~190 words.)*

---

## Bonus — Decode the TLS Handshake

socat terminated TLS on `:8443` with a self-signed cert for `localhost` and
proxied to `:8080`. I captured `lab4-tls.pcap` and decoded it with tshark.

**ClientHello** (what curl offered):
```
Handshake Type: Client Hello (1)
  (record-layer legacy version: TLS 1.0 — frozen for middlebox compatibility)
  Server Name Indication extension -> Server Name: localhost          # SNI
  supported_versions extension -> TLS 1.3 (0x0304), TLS 1.2 (0x0303)  # real versions
  Cipher Suites (31): TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256,
    TLS_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384, ...
```

**ServerHello** (what the server chose):
```
Handshake Type: Server Hello (2)
  legacy version field: TLS 1.2 (0x0303)
  supported_versions extension -> TLS 1.3 (0x0304)     # the real negotiated version
  Cipher Suite: TLS_AES_256_GCM_SHA384 (0x1302)
```

**Certificate chain** (`openssl s_client`, full output in `tls-sclient.txt`):
```
Certificate chain
 0 s:CN = localhost
   i:CN = localhost
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Verify return code: 18 (self-signed certificate)
```
A one-link chain (the leaf is its own issuer — self-signed), negotiated as
**TLS 1.3** with an AES-256-GCM cipher. curl's trace confirms the 1.3 flow:
ClientHello → ServerHello → Encrypted Extensions → Certificate → CERT verify →
Finished.

**Which negotiation step kills TLS 1.0 / 1.1 in 2026?** The
**`supported_versions` extension**, introduced by TLS 1.3 (RFC 8446). The version
in the record/legacy field is permanently pinned at "TLS 1.2" so old middleboxes
don't choke — the *actual* version is negotiated only through this extension. A
2026 client (curl/OpenSSL here) simply doesn't list 1.0 or 1.1 in
`supported_versions`, and a modern server won't select them, so they're never on
the table. Even if a client tried to fall back to a 1.0 record-layer `ClientHello`,
current libraries reject it outright. TLS 1.0/1.1 weren't "turned off" by one
switch — they were dropped from the version-negotiation extension and from
libraries' allowed-version floors.

---

## Summary

| Task | Evidence |
|------|----------|
| 1 — trace end-to-end | pcap + decoded `lab4-trace.txt`: handshake, POST+body, 201+JSON, FIN close; all 5 debug commands; 502 reflection |
| 2 — broken deploy | `bind: address already in use` reproduced; outside-in chain (ps/ss/curl/firewall/DNS); repair to 200; blameless postmortem |
| Bonus — TLS | ClientHello (SNI + offered versions + ciphers), ServerHello (TLS 1.3 + cipher), self-signed chain; TLS 1.0/1.1 deprecation explained |
