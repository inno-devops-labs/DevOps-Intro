# Lab 4 - OS & Networking: Trace, Debug, and Read the Substrate

## Task 1 - Trace a Request End-to-End

### 1.2 Annotated Packet Capture (`lab4-trace.txt`)

The capture was taken on the `lo` interface. QuickNotes resolved to `::1` (IPv6 loopback), so all packets are IPv6. The full exchange took approximately **1.5 ms**.

```
--- Phase 1: TCP Three-Way Handshake ---

19:12:36.564045 IP6 ::1.46212 > ::1.8080: Flags [S]
  -> SYN — client initiates connection, proposes MSS 65476, window scaling

19:12:36.564084 IP6 ::1.8080 > ::1.46212: Flags [S.]
  -> SYN/ACK — server accepts, echoes timestamp, agrees on MSS and window scale

19:12:36.564109 IP6 ::1.46212 > ::1.8080: Flags [.]
  -> ACK — client acknowledges; TCP connection is now fully established

--- Phase 2: HTTP Request ---

19:12:36.564272 IP6 ::1.46212 > ::1.8080: Flags [P.], length 175: HTTP: POST /notes HTTP/1.1
  -> PSH+ACK — client pushes 175 bytes: HTTP headers + JSON body
    POST /notes HTTP/1.1
    Host: localhost:8080
    User-Agent: curl/8.15.0
    Content-Type: application/json
    Content-Length: 39
    {"title":"trace me","body":"in flight"}

19:12:36.564284 IP6 ::1.8080 > ::1.46212: Flags [.]
  -> ACK — server acknowledges receipt of the request

--- Phase 3: HTTP Response ---

19:12:36.564906 IP6 ::1.8080 > ::1.46212: Flags [P.], length 206: HTTP: HTTP/1.1 201 Created
  -> PSH+ACK — server pushes 206 bytes: status line + headers + response body
    HTTP/1.1 201 Created
    Content-Type: application/json
    Content-Length: 93
    {"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-15T09:12:36.564482119Z"}

19:12:36.564947 IP6 ::1.46212 > ::1.8080: Flags [.]
  -> ACK — client acknowledges the response

--- Phase 4: Graceful Connection Close (FIN handshake, not RST) ---

19:12:36.565275 IP6 ::1.46212 > ::1.8080: Flags [F.]
  -> FIN+ACK — client signals it has no more data to send

19:12:36.565451 IP6 ::1.8080 > ::1.46212: Flags [F.]
  -> FIN+ACK — server also signals it has no more data to send

19:12:36.565511 IP6 ::1.46212 > ::1.8080: Flags [.]
  -> ACK — client acknowledges server FIN; connection fully torn down
```

---

### 1.3 Five Debugging Commands

**1. What is listening on port 8080?**
```
$ ss -tlnp | grep :8080
LISTEN 0      4096       *:8080       *:*    users:(("quicknotes",pid=44458,fd=3))
```
QuickNotes is listening on all interfaces (both IPv4 and IPv6), PID 44458, file descriptor 3.

---

**2. Routing table**
```
$ ip route show
default via 192.168.0.1 dev wlo1 proto dhcp src 192.168.0.102 metric 600
192.168.0.0/24 dev wlo1 proto kernel scope link src 192.168.0.102 metric 600
```
Default route goes via the home router (`192.168.0.1`) over WiFi (`wlo1`). Loopback (`lo`) is implicit and not listed. It handles `::1` traffic without needing a route entry.

---

**3. Reachability to localhost**
```
$ mtr -rwc 5 localhost
Start: 2026-06-15T19:36:56+1000
HOST: fedora    Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.2   0.3   0.1   0.4   0.1
```
Single hop, 0% packet loss, 0.3 ms average. Sub-millisecond and jitter-free, as expected for loopback. `mtr` is most useful over real networks for identifying where along a path latency spikes or loss begins.

---

**4. DNS resolution via Cloudflare**
```
$ dig +short example.com @1.1.1.1
104.20.23.154
172.66.147.243
```
DNS is functional. Querying Cloudflare's resolver (`1.1.1.1`) directly confirms external DNS reachability independent of any local resolver config. Two IPs returned because example.com is served from multiple anycast nodes.

---

**5. Service logs**
```
$ journalctl --user -u quicknotes -n 20 || true
-- No entries --
```
QuickNotes is not registered as a systemd user service - it is running directly via `go run .`. No logs are captured by journald. In a production deploy, registering it as a systemd service would surface startup errors, crashes, and request logs here.

---

### 1.4 502 Debug Reflection

A 502 Bad Gateway means a proxy (e.g. Caddy, nginx) is up but got a bad or no response from the upstream, in this case QuickNotes. The first thing to check is whether QuickNotes is actually running: `ps -ef | grep quicknotes` or `ss -tlnp | grep :8080`. If nothing is listening, that's your answer immediately. If it is listening, try hitting it directly with `curl -s http://localhost:8080/health` to bypass the proxy entirely; a clean 200 there means the proxy is misconfigured (wrong upstream port, wrong address), while a timeout or connection refused points to the app being overloaded or crashed. Finally, `journalctl -u quicknotes -n 50` would surface panic messages.

---

## Task 2 - Outside-In Debugging on a Broken Deploy

### 2.1 Run a broken instance

Two additional QuickNotes instances were launched targeting `:8080`, which was already held by the instance started in Task 1. Both failed immediately:

```
2026/06/15 19:44:59 quicknotes listening on :8080 (notes loaded: 7)
2026/06/15 19:44:59 listen: listen tcp :8080: bind: address already in use
exit status 1
```

Root cause captured: `bind: address already in use`.

---

### 2.2 Walk the outside-in chain

**1) Is any quicknotes process running?**
```
$ ps -ef | grep quicknotes | grep -v grep
.cache/go-build/0a/0aa05a27653e4463904407bc4fca682b044335fe063006487a91b9764a9e8226-d/quicknotes
```
Decision: yes, a process exists. The new instances exited but the original is still alive.

---

**2) Is it listening on 8080?**
```
$ ss -tlnp | grep 8080
LISTEN 0      4096       *:8080       *:*    users:(("quicknotes",pid=56977,fd=3))
```
Decision: PID 56977 is holding the port. That's why both new instances couldn't bind. Proceed to verify it's actually healthy.

---

**3) Is it responding from the host?**
```
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```
Decision: the existing instance is healthy. The port conflict is the only problem — nothing is broken at the application layer.

---

**4) Is a firewall blocking anything?**
```
$ sudo iptables -L -n -v
Chain INPUT  (policy ACCEPT)
Chain OUTPUT (policy ACCEPT)
Chain FORWARD (policy ACCEPT)
```
Decision: default policy is ACCEPT on all chains; no DROP or REJECT rules near port 8080. Firewall is not the issue.

---

**5) DNS resolves localhost?**
```
$ dig +short localhost
127.0.0.1
```
Decision: DNS is fine. All five layers checked. The failure is purely the port conflict at bind time.

---

### 2.3 Repair + Re-verify

Killed the conflicting instance (PID 56977) and started a fresh one:

```
$ kill 56977 && sleep 1 && go run . &
2026/06/15 19:51:20 quicknotes listening on :8080 (notes loaded: 7)

$ curl -s http://localhost:8080/health
{"notes":7,"status":"ok"}
```

Service restored. All 7 notes intact.

---

### 2.4 Blameless Mini-Postmortem

**Root cause:** `listen tcp :8080: bind: address already in use` - a second process attempted to bind a port already held by a running instance.

**What's systemic about this failure:** Port conflicts are not the fault of any individual deploy action. They are a predictable consequence of missing process lifecycle management. When a service is started manually (via `go run .` or a bare shell command), there is no mechanism to guarantee the previous instance has stopped before the new one starts. This pattern appears in rolling deploys, restart-on-crash scripts, and CI/CD pipelines that shell out to start services without waiting for a clean shutdown signal. The failure mode is deterministic and repeatable, yet it surfaces as a runtime error rather than a deploy-time gate.

**What tooling could prevent it:** Registering QuickNotes as a systemd unit eliminates this entirely - `systemctl restart quicknotes` performs a clean stop before starting, and `BindsTo=` and `Conflicts=` directives can make port ownership explicit. Alternatively, a pre-start `ExecStartPre=/bin/sh -c 'fuser -k 8080/tcp || true'` guard evicts any stale holder before bind. At the infrastructure level, a deploy system that queries `ss -tlnp` and gates on a clean port before proceeding would catch this before any process even tries to start.

---

## Bonus Task - Decode the TLS Handshake

### B.1 Setup: Add an HTTPS layer

Caddy v2.10.2 was already installed. A minimal Caddyfile was created at `~/lab4-caddy/Caddyfile`:

```
localhost:8443 {
  reverse_proxy localhost:8080
}
```

Caddy was started with `sudo -b caddy run --config Caddyfile`. On first start, Caddy automatically generated a local ECC root CA, issued an intermediate CA, and signed a leaf certificate for `localhost`. The root was installed into the NSS trust store (Firefox/Chrome databases).

---

### B.2 Capture the TLS handshake: curl -vk output (annotated)

The full handshake was captured by running `curl -vk https://localhost:8443/health`:

```
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
  -> ClientHello — curl offers TLS 1.3, proposes cipher suites, sends SNI="localhost",
    ALPN: h2, http/1.1

* TLSv1.3 (IN), TLS handshake, Server hello (2):
  -> ServerHello — Caddy selects TLS 1.3, chooses TLS_AES_128_GCM_SHA256

* TLSv1.3 (IN), TLS change cipher, Change cipher spec (1):
  -> Caddy signals switch to encrypted record layer

* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
  -> Server sends ALPN confirmation (h2 accepted) and other extensions — now encrypted

* TLSv1.3 (IN), TLS handshake, Certificate (11):
  -> Caddy sends its certificate chain (leaf + intermediate)

* TLSv1.3 (IN), TLS handshake, CERT verify (15):
  -> Server proves it holds the private key via ECDSA signature

* TLSv1.3 (IN), TLS handshake, Finished (20):
  -> Server sends Finished MAC — handshake authenticated

* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
  -> Client confirms Finished — secure channel established

* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256 / x25519 / id-ecPublicKey
  -> Negotiated: TLS 1.3, AES-128-GCM cipher, X25519 key exchange, EC public key

* ALPN: server accepted h2
  -> HTTP/2 is active over this TLS session
```

---

### B.3 Certificate Chain - openssl s_client output

```
$ openssl s_client -connect localhost:8443 -servername localhost -showcerts </dev/null

depth=2 CN=Caddy Local Authority - 2026 ECC Root       ← root CA (self-signed)
depth=1 CN=Caddy Local Authority - ECC Intermediate    ← intermediate CA
depth=0                                                ← leaf cert for localhost

Certificate chain:
  Cert 0 (leaf):
    Subject: (empty — localhost is in SAN extension)
    Issuer:  CN=Caddy Local Authority - ECC Intermediate
    Key:     EC prime256v1 (256-bit)
    SigAlg:  ecdsa-with-SHA256
    Valid:   Jun 15 10:14:57 2026 GMT → Jun 15 22:14:57 2026 GMT  (12-hour leaf!)
    SAN:     localhost

  Cert 1 (intermediate):
    Subject: CN=Caddy Local Authority - ECC Intermediate
    Issuer:  CN=Caddy Local Authority - 2026 ECC Root
    Key:     EC prime256v1 (256-bit)
    SigAlg:  ecdsa-with-SHA256
    Valid:   Jun 15 10:14:55 2026 GMT → Jun 22 10:14:55 2026 GMT  (7-day intermediate)

TLS session:
  Protocol:    TLSv1.3
  Cipher:      TLS_AES_128_GCM_SHA256
  Key exchange: X25519 (253-bit ephemeral)
  Peer sig:    ecdsa_secp256r1_sha256
  Verification: OK
```

---

### B.4 Which negotiation step kills TLS 1.0 / 1.1 in 2026?

The killing blow happens inside the **ClientHello**, in the `supported_versions` extension introduced by TLS 1.3 (RFC 8446). In TLS 1.2 and earlier, the protocol version was carried in the ClientHello record header itself, which allowed servers to downgrade freely. TLS 1.3 moved version negotiation into an explicit `supported_versions` extension, the client lists exactly which versions it accepts, and the server must pick one from that list. Modern clients (curl 8.15.0, all current browsers, OpenSSL 3.x) no longer include TLS 1.0 or TLS 1.1 in this list at all, they have been formally deprecated by RFC 8996 (March 2021) and disabled by default in all major TLS libraries. Even if a server advertised TLS 1.0 support, a 2026 client would ignore it entirely. In this capture, the ServerHello responded with `supported_versions: TLS 1.3`, confirming that the negotiation never even considered the deprecated versions.