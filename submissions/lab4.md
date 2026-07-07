# Lab 4 submission

**Environment:** Ubuntu 24.04 VM. Tools: `tcpdump`, `ss`, `ip`, `dig`, `mtr`, `jq`, Go 1.24.2, Caddy 2.6 (bonus). QuickNotes built as `/tmp/quicknotes` (`ADDR=:8080`).

**Artifacts:** `submissions/attachments/lab4/` — captures, command logs, TLS decode.

---

## Task 1 — Trace a Request End-to-End

### 1.1–1.2: Capture + decode

**Commands (VM):**

```bash
cd app && go build -o /tmp/quicknotes .
ADDR=:8080 /tmp/quicknotes &
tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap &
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

Full decode: [`lab4-trace.txt`](attachments/lab4/lab4-trace.txt) · binary: [`lab4-trace.pcap`](attachments/lab4/lab4-trace.pcap)

**Annotated highlights** (IPv6 loopback `::1` → `::1:8080`):

| Phase | Packet / flag | Evidence |
|-------|---------------|----------|
| **TCP handshake** | SYN → SYN/ACK → ACK | `11:26:23.201919` `Flags [S]` · `11:26:23.201946` `Flags [S.]` · `11:26:23.201968` `Flags [.]` |
| **HTTP request** | `POST /notes HTTP/1.1` + JSON body | `11:26:23.202182` `Flags [P.]` — `POST /notes HTTP/1.1`, `Content-Type: application/json`, `{"title":"trace me","body":"in flight"}` |
| **HTTP response** | `HTTP/1.1 201 Created` + JSON | `11:26:23.203056` — `HTTP/1.1 201 Created`, body `{"id":5,"title":"trace me",...}` |
| **Connection close** | FIN handshake | Client `Flags [F.]` `11:26:23.203444` · Server `Flags [F.]` `11:26:23.204491` · final ACK |

`curl -v` confirms the same at L7: [`curl-verbose.txt`](attachments/lab4/curl-verbose.txt) — `HTTP/1.1 201 Created`, connected via `[::1]:8080`.

### 1.3: Five debugging commands

Full output: [`debug-commands.txt`](attachments/lab4/debug-commands.txt)

**1. What's listening?**

```text
LISTEN 0  4096  *:8080  *:*  users:(("quicknotes",pid=67371,fd=3))
```

**Decision:** process is bound on all interfaces (`*:8080`); PID/name visible with root.

**2. Routes**

```text
default via 10.93.24.1 dev eth0 proto static
10.93.24.0/22 dev eth0 proto kernel scope link src 10.93.26.172
```

**Decision:** default route via `eth0`; localhost traffic stays on `lo` (not shown — implicit).

**3. Reachability (`mtr -rwc 5 localhost`)**

```text
HOST: capstone55  Loss% 0.0%  Snt 5  Avg 0.1 ms
```

**Decision:** loopback healthy; no packet loss.

**4. DNS (`dig +short example.com @1.1.1.1`)**

```text
8.47.69.0
8.6.112.0
```

**Decision:** external DNS resolver answers; not involved in `localhost:8080` path.

**5. Logs (`journalctl --user -u quicknotes`)**

```text
-- No entries --
```

**Decision:** QuickNotes was run manually, not as a user unit — expected empty; would check app stdout or systemd unit logs in production.

### 1.4: If QuickNotes returned 502?

A **502 Bad Gateway** means a proxy reached an upstream but got an invalid/empty response — the failure is *between* the edge and the app, not in the client's TCP stack. I would check in order: (1) is the upstream process listening (`ss -tlnp | grep 8080`)? (2) does `curl -v http://127.0.0.1:8080/health` succeed *directly*, bypassing the proxy? (3) proxy error logs (Caddy/nginx) for `connection refused` vs `timeout`; (4) firewall/`iptables` on the path; (5) only then DNS or external routing. On this VM, Task 2 showed the classic case: port conflict left one instance healthy while a second failed to bind — a proxy might still route to a dead peer and emit 502 if misconfigured.

---

## Task 2 — Outside-In Debugging on a Broken Deploy

Full log: [`task2-broken.txt`](attachments/lab4/task2-broken.txt)

### 2.1: Reproduce

Started two instances on `:8080`. Second instance failed:

```text
2026/06/15 11:26:38 quicknotes listening on :8080 (notes loaded: 5)
2026/06/15 11:26:38 listen: listen tcp :8080: bind: address already in use
```

**Root cause:** `bind: address already in use` — first process (PID 67398) held `:8080`.

### 2.2: Outside-in chain

| Step | Command | Output | Decision |
|------|---------|--------|----------|
| 1 — running? | `ps -ef \| grep quicknotes` | PID 67398 `/tmp/quicknotes` | One instance alive; second exited on bind error |
| 2 — listening? | `ss -tlnp \| grep 8080` | `quicknotes` pid 67398 on `*:8080` | Socket owned by first process |
| 3 — reachable? | `curl -w %{http_code} localhost:8080/health` | `200` | App healthy *despite* failed second start — misleading if you only check HTTP |
| 4 — firewall? | `iptables -L -n -v` | all chains `policy ACCEPT`, 0 packets | Not a firewall issue |
| 5 — DNS? | `dig +short localhost` | `127.0.0.1` | Name resolves; not DNS |

### 2.3: Repair

Killed PID1, started fresh instance → `curl /health` → `{"notes":5,"status":"ok"}`.

### 2.4: Blameless mini-postmortem

Two deploy scripts both used `ADDR=:8080` without coordination. The first instance succeeded; the second logged `address already in use` and exited, but monitoring that only checks HTTP 200 would still show green. **Systemic issue:** no port allocation, no systemd `Restart=on-failure` with alerting on bind errors, no pre-flight `ss` check in the deploy playbook. **Prevention:** declare the listen port in one place (unit file / Compose / Ansible template), use `systemd` socket activation or a single supervisor, and fail the deploy pipeline if `listen:` appears in stderr. A health check hitting `/health` is necessary but not sufficient — process-level checks (`systemctl is-active`, `ss -tlnp`) catch "wrong process on port" earlier than L7.

---

## Bonus Task — TLS Handshake Decode

Caddy terminates TLS on `localhost:8443` → reverse proxy → QuickNotes `:8080`. Capture used `tcpdump -i any` (IPv4 `127.0.0.1`; `-i lo` alone missed traffic on first attempt).

Artifacts: [`lab4-tls.pcap`](attachments/lab4/lab4-tls.pcap) · [`curl-tls.txt`](attachments/lab4/curl-tls.txt) · [`openssl-certs.txt`](attachments/lab4/openssl-certs.txt) · [`clienthello.txt`](attachments/lab4/clienthello.txt) · [`serverhello.txt`](attachments/lab4/serverhello.txt)

### ClientHello (tshark)

- **Record version:** TLS 1.0 (0x0301) — legacy wrapper; real version in extension
- **Client version:** TLS 1.2 (0x0303)
- **`supported_versions` extension:** TLS 1.3, TLS 1.2
- **SNI:** `localhost`
- **Cipher suites offered:** includes modern (`TLS_AES_128_GCM_SHA256`, `TLS_CHACHA20_POLY1305_SHA256`, ECDHE-GCM) and legacy (`TLS_RSA_WITH_AES_128_CBC_SHA`, etc.)

### ServerHello (tshark)

- **Selected cipher:** `TLS_AES_128_GCM_SHA256` (0x1301)
- **`supported_versions` extension:** **TLS 1.3** (0x0304) — negotiation upgrades to TLS 1.3
- Followed by Change Cipher Spec + encrypted Application Data (TLS 1.3)

`curl -vk` confirms: `TLSv1.3 / TLS_AES_128_GCM_SHA256 / X25519`.

### Certificate chain (`openssl s_client -showcerts`)

```text
 0 s: (leaf, CN empty, SAN localhost)
   i: CN = Caddy Local Authority - ECC Intermediate
 1 s: CN = Caddy Local Authority - ECC Intermediate
   i: CN = Caddy Local Authority - 2026 ECC Root
```

Short-lived ECDSA leaf (~12 h), internal CA — expected for `tls internal`.

### TLS 1.0 / 1.1 in 2026?

The step that **kills TLS 1.0/1.1** is the **`supported_versions` extension** in ClientHello (client offers only 1.2+) combined with the server's **`supported_versions` in ServerHello picking TLS 1.3**. Neither side negotiates SSL 3.0 / TLS 1.0 / TLS 1.1. Browsers and libraries disabled 1.0/1.1 by default years ago; RFC 8996 deprecated them. Caddy/modern stacks refuse to complete handshakes at those versions even if legacy cipher names appear in the client's list for middlebox compatibility — the actual protocol version is chosen only from `supported_versions`, not from the legacy record-layer version field (still 0x0301 in the ClientHello wrapper).
