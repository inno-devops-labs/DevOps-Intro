# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

Environment: WSL2 (Ubuntu 24.04 "noble") on Windows. QuickNotes run locally via `go run .` on `:8080`.

---

## Task 1 — Trace a Request End-to-End

### 1.1–1.2: Packet capture + annotation

A single `POST /notes` was captured on the loopback interface with:

```bash
sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap
```

The request used IPv6 loopback (`::1`) because `localhost` resolved to `::1` before `127.0.0.1` (visible in `curl -v`: `Trying [::1]:8080`). Client port `47658`, server port `8080`. Full decoded trace is in `lab4-trace.txt`. Annotated breakdown of the 10 captured packets:

**TCP three-way handshake (packets 1–3):**
- Packet 1 — `Flags [S]` (SYN), client→server, seq 3514288627
- Packet 2 — `Flags [S.]` (SYN+ACK), server→client, seq 558034398, ack 3514288628
- Packet 3 — `Flags [.]` (ACK) — handshake complete, connection established

**HTTP request (packets 4–5):**
- Packet 4 — `Flags [P.]`, length 174: `POST /notes HTTP/1.1` + headers + JSON body `{"title":"trace me","body":"in flight"}`
- Packet 5 — server `ACK` acknowledging the 174-byte request

**HTTP response (packets 6–7):**
- Packet 6 — `Flags [P.]`, length 206: `HTTP/1.1 201 Created` + JSON `{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T12:48:57..."}`
- Packet 7 — client `ACK` acknowledging the response

**Connection close (packets 8–10):**
- Packet 8 — `Flags [F.]` (FIN) from client
- Packet 9 — `Flags [F.]` (FIN+ACK) from server
- Packet 10 — `Flags [.]` (final ACK) from client — graceful four-way close (FIN, not RST)

`curl -v` confirmed the application layer: `< HTTP/1.1 201 Created`, `Content-Length: 93`, response body with `"id":7`.

### 1.3: Five debugging commands

**1. What's listening? — `ss -tlnp | grep :8080`**
```
LISTEN 0  4096  *:8080  *:*  users:(("quicknotes",pid=1659,fd=3))
```
QuickNotes listens on all interfaces (`*:8080`), owned by PID 1659.

**2. Routes — `ip route show`**
```
default via 192.168.224.1 dev eth0 proto kernel
192.168.224.0/20 dev eth0 proto kernel scope link src 192.168.239.58
```
Typical WSL2 NAT network: default gateway `192.168.224.1` on `eth0`, host IP `192.168.239.58`.

**3. Reachability — `mtr -rwc 5 localhost`**
```
HOST: DESKTOP-BJUCF2F  Loss%  Snt  Last  Avg  Best  Wrst StDev
  1.|-- localhost       0.0%    5   0.1  0.1   0.1   0.2   0.1
```
Single hop (loopback), 0% loss, ~0.1 ms — loopback is healthy.

**4. DNS — `dig +short example.com @1.1.1.1`**
```
8.6.112.0
8.47.69.0
```
External DNS resolution via Cloudflare works.

**5. Logs — `journalctl --user -u quicknotes -n 20`**
```
-- No entries --
```
Expected: QuickNotes runs as a foreground `go run .` process, not a systemd unit, so journald has no records for it.

### 1.4: What would I check first if QuickNotes returned 502?

A `502 Bad Gateway` is emitted by a *proxy/load balancer in front of* the app, not by the app itself — it means the proxy could not get a valid response from the upstream. So I would not start by reading QuickNotes' own logs; I'd start at the boundary between proxy and app. First, confirm the backend is actually up and bound to its port (`ss -tlnp | grep 8080` — is anything listening?). If it is listening, I'd check whether the proxy can reach it from where the proxy runs (`curl` to the upstream address:port directly, bypassing the proxy), since a 502 often means the upstream crashed, is still starting, bound to the wrong interface (e.g. `127.0.0.1` while the proxy dials a different address), or is timing out. Only after confirming reachability would I look at the app logs and the proxy's own error log to see whether it's a connection refused, a timeout, or a malformed response.

---

## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1: Reproducing the break

With one healthy instance already on `:8080`, a second instance was started on the same port:

```bash
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log
```

Output:
```
2026/06/16 20:45:10 quicknotes listening on :8080 (notes loaded: 7)
2026/06/16 20:45:10 listen: listen tcp :8080: bind: address already in use
exit status 1
```

**Root cause: `bind: address already in use`** — the port was already held by the first instance. Note the app logs "listening on :8080" *before* the bind actually succeeds, so the log line is misleading — it claims success a moment before the failure.

### 2.2: Outside-in chain (command + output + decision)

**1) Is it running? — `ps -ef | grep quicknotes`**
```
alpatov+ 1659 ... /home/alpatovia/.cache/go-build/.../quicknotes
```
*Decision:* a process exists (the first/healthy instance); the broken second instance already exited. Continue.

**2) Is it listening? — `ss -tlnp | grep 8080`**
```
LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=1659,fd=3))
```
*Decision:* port 8080 is held by PID 1659. This is the source of the bind conflict for any second instance.

**3) Reachable from host? — `curl -s -o /dev/null -w "%{http_code}" .../health`**
```
200
```
*Decision:* the service is actually healthy and serving — the "outage" is only that the *second* instance can't start, not that the service is down.

**4) Firewall blocking? — `iptables -L` / `nft list ruleset`**
```
(empty)
```
*Decision:* no firewall rules interfering. Rule out network filtering.

**5) DNS? — `dig +short localhost`**
```
127.0.0.1
```
*Decision:* name resolution is fine. "It's never DNS" holds this time.

**Conclusion:** the service on 8080 is alive and returns 200; the only anomaly is a second process unable to bind an already-bound port. Root cause is a **port conflict**, not network/DNS/firewall.

### 2.3: Repair + re-verify

```bash
kill 1659          # stop the conflicting instance
ss -tlnp | grep 8080   # → (empty), port freed
ADDR=:8080 go run . &  # start a clean instance
curl -s http://localhost:8080/health
# → {"notes":7,"status":"ok"}
```

### 2.4: Blameless mini-postmortem (≤ 200 words)

A second QuickNotes instance failed to start with `bind: address already in use` because the port was already held by a running instance. Nobody "did it wrong" — this is a systemic shape, not a personal error. Two instances were told to claim the same fixed port, and nothing in the deploy path detected the collision before launch. What's systemic: a hard-coded port with no pre-flight check, an app that logs "listening" before the bind result is known (so naive log-based health checks would report a false success), and no supervisor enforcing single-instance ownership. Tooling that prevents this class of failure: a process supervisor (systemd unit with `Restart=` and a single canonical owner of the port) that refuses to start a duplicate; a pre-bind readiness probe that actually connects to the port; making the port configurable per instance (env-driven, as `ADDR` already allows) so parallel instances don't collide; and CI/deploy checks that fail fast on a port already in use. The fix in the moment is trivial (free the port, restart); the durable fix is removing the implicit assumption that exactly one instance ever owns a fixed port.

---

## Bonus — Decode the TLS Handshake

### B.1: HTTPS layer via Caddy

Caddy 2.6.2 was configured as a TLS-terminating reverse proxy in front of QuickNotes:

```
localhost:8443 {
  reverse_proxy localhost:8080
}
```

Caddy generated a local CA and a self-signed cert for `localhost`, then served HTTPS on `:8443` (negotiating h1/h2/h3). `curl -sk https://localhost:8443/health` returned `{"notes":7,"status":"ok"}` — TLS termination + proxying works.

### B.2–B.3: Captured handshake

Capture: `sudo tcpdump -i lo -nn -s 0 -w lab4-tls.pcap 'tcp port 8443'`, then `curl -vk https://localhost:8443/health`.

`curl -v` summary of the negotiated connection:
```
SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256 / X25519 / id-ecPublicKey
ALPN: server accepted h2
issuer: CN=Caddy Local Authority - ECC Intermediate
```

**ClientHello** (decoded with `tshark -Y "tls.handshake.type == 1" -V`) — screenshot `clienthello.png`:
- Record `Version: TLS 1.2 (0x0303)` — legacy field, deliberately downgraded for middlebox compatibility
- 31 cipher suites offered; top three are TLS 1.3 suites: `TLS_AES_256_GCM_SHA384`, `TLS_CHACHA20_POLY1305_SHA256`, `TLS_AES_128_GCM_SHA256`
- `server_name: localhost` (SNI)
- ALPN: `h2`, `http/1.1`
- **`supported_versions` extension: TLS 1.3 (0x0304), TLS 1.2 (0x0303)** — the real version offer

**ServerHello** (`tls.handshake.type == 2`) — screenshot `serverhello.png`:
- Record `Version: TLS 1.2 (0x0303)` — legacy field again
- **`supported_versions` extension: TLS 1.3 (0x0304)** — server's actual choice
- `Cipher Suite: TLS_AES_128_GCM_SHA256 (0x1301)`
- `key_share: x25519`

**Certificate chain** (`openssl s_client -connect localhost:8443 -servername localhost`) — screenshot `cert_chain.png`:
```
subject=
issuer=CN = Caddy Local Authority - ECC Intermediate
notBefore=Jun 16 17:54:03 2026 GMT
notAfter =Jun 17 05:54:03 2026 GMT
```
Leaf cert has no CN (name lives in SAN, modern practice), issued by Caddy's local intermediate CA, valid only ~12 hours (Caddy's short-lived local certs). Note: SNI (`-servername localhost`) is **required** — without it the server sends a `tlsv1 alert internal error` and no certificate, since it can't pick which cert to serve.

> Wireshark GUI is unavailable in this headless WSL environment, so the handshake was decoded with `tshark` (Wireshark's CLI engine) — identical fields to the GUI packet-detail pane. Console screenshots are attached.

### Which negotiation step kills TLS 1.0/1.1 in 2026?

The **version negotiation via the `supported_versions` extension** (RFC 8446). In TLS 1.3, the real version is no longer in the record's `Version` field (pinned at 1.2 for compatibility) — it's carried in `supported_versions`. The client here lists only TLS 1.3 and 1.2; it never offers 1.0 or 1.1. The server picks the highest mutually supported version (1.3). Even if a client *did* offer 1.0/1.1, modern servers and crypto libraries (Caddy on OpenSSL 3.x) have those protocol versions disabled at the library level and would refuse them during this exact step. So a downgrade to 1.0/1.1 dies at version negotiation, before any cipher or key exchange is agreed.

---

## Files in this submission

- `submissions/lab4.md` — this document
- `submissions/lab4-trace.txt` — full decoded packet trace from Task 1
- `submissions/img/clienthello.png`, `serverhello.png`, `cert_chain.png` — TLS handshake evidence
