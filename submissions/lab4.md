# Lab 4 - OS & Networking: Trace, Debug, and Read the Substrate

## Environment

I completed the lab in a disposable Linux container so the Linux networking tools from the task were available.

```text
Image: golang:1.24-bookworm
Kernel: Linux ae8db4a22f62 6.12.54-linuxkit #1 SMP Tue Nov 4 21:21:47 UTC 2025 aarch64 GNU/Linux
Go: go version go1.24.13 linux/arm64
Installed tools: iproute2 dnsutils mtr-tiny tcpdump curl procps iptables nftables jq systemd
```

QuickNotes startup:

```bash
ADDR=:8080 DATA_PATH=/tmp/quicknotes-lab4-docker.json SEED_PATH=seed.json go run .
```

```text
2026/06/14 14:16:24 quicknotes listening on :8080 (notes loaded: 4)
```

Full raw Linux output is also saved in `submissions/lab4-linux-evidence.txt`.

## Task 1 - Trace a Request End-to-End

### 1.1 Start QuickNotes and capture

I captured loopback traffic inside the Linux container:

```bash
tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w submissions/lab4-trace.pcap
```

```text
tcpdump: listening on lo, link-type EN10MB (Ethernet), snapshot length 262144 bytes
10 packets captured
20 packets received by filter
0 packets dropped by kernel
```

Then I sent one request:

```bash
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

```text
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> POST /notes HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.88.1
> Accept: */*
> Content-Type: application/json
> Content-Length: 39
>
} [39 bytes data]
< HTTP/1.1 201 Created
< Content-Type: application/json
< Date: Sun, 14 Jun 2026 14:16:25 GMT
< Content-Length: 93
<
{"id":5,"title":"trace me","body":"in flight","created_at":"2026-06-14T14:16:25.453003253Z"}
```

### 1.2 Decode the capture

The decoded trace is saved in `submissions/lab4-trace.txt`, and the Linux pcap is saved as `submissions/lab4-trace.pcap`.

TCP three-way handshake:

```text
14:16:25.452682 IP 127.0.0.1.47304 > 127.0.0.1.8080: Flags [S], seq 4278554227, length 0
14:16:25.452689 IP 127.0.0.1.8080 > 127.0.0.1.47304: Flags [S.], seq 1200757750, ack 4278554228, length 0
14:16:25.452695 IP 127.0.0.1.47304 > 127.0.0.1.8080: Flags [.], ack 1, length 0
```

HTTP request:

```text
14:16:25.452898 IP 127.0.0.1.47304 > 127.0.0.1.8080: Flags [P.], seq 1:176, ack 1, length 175: HTTP: POST /notes HTTP/1.1

POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/7.88.1
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

HTTP response:

```text
14:16:25.453162 IP 127.0.0.1.8080 > 127.0.0.1.47304: Flags [P.], seq 1:207, ack 176, length 206: HTTP: HTTP/1.1 201 Created

HTTP/1.1 201 Created
Content-Type: application/json
Date: Sun, 14 Jun 2026 14:16:25 GMT
Content-Length: 93

{"id":5,"title":"trace me","body":"in flight","created_at":"2026-06-14T14:16:25.453003253Z"}
```

Connection close:

```text
14:16:25.456667 IP 127.0.0.1.47304 > 127.0.0.1.8080: Flags [F.], seq 176, ack 207, length 0
14:16:25.456716 IP 127.0.0.1.8080 > 127.0.0.1.47304: Flags [F.], seq 207, ack 177, length 0
14:16:25.456730 IP 127.0.0.1.47304 > 127.0.0.1.8080: Flags [.], ack 208, length 0
```

Conclusion: the TCP connection opened cleanly, the request reached QuickNotes, the app returned `201 Created`, and the connection closed normally with FIN/ACK rather than RST.

### 1.3 Five debugging commands

#### 1. What is listening?

```bash
ss -tlnp | grep :8080
```

```text
LISTEN 0      4096               *:8080            *:*    users:(("quicknotes",pid=2698,fd=3))
```

Decision: QuickNotes is listening on port `8080`.

#### 2. Routes from the host/container

```bash
ip route show
```

```text
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2
```

Decision: the container has a default route through the Docker bridge gateway. The request to `localhost` stays on loopback.

#### 3. Reachability

```bash
mtr -rwc 5 localhost
```

```text
Start: 2026-06-14T14:16:26+0000
HOST: ae8db4a22f62 Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost     0.0%     5    0.0   0.1   0.0   0.2   0.1
```

Decision: localhost is reachable in one hop with no loss.

#### 4. DNS works

```bash
dig +short example.com @1.1.1.1
```

```text
172.66.147.243
104.20.23.154
```

Decision: external DNS resolution through `1.1.1.1` works.

#### 5. Logs

```bash
journalctl --user -u quicknotes -n 20 || true
```

```text
No journal files were found.
-- No entries --
```

Decision: QuickNotes was started manually with `go run`, not installed as a user systemd service, so there were no journal entries. The process logs were visible in the terminal output.

### 1.4 If QuickNotes returned 502

If QuickNotes returned `502 Bad Gateway`, I would start at the proxy or load balancer because 502 usually means the proxy could not get a valid response from its upstream. My outside-in order would be: confirm that the proxy routes to the expected host and port, check that QuickNotes is listening with `ss -tlnp`, call `/health` directly with `curl -v`, and then inspect service logs for crashes, bind failures, or timeouts. If the direct health check worked, I would look at proxy timeout settings, upstream DNS resolution, and firewall/network rules between the proxy and QuickNotes.

## Task 2 - Outside-In Debugging on a Broken Deploy

### 2.1 Broken instance

To reproduce the broken deploy, I left one QuickNotes process running on `:8080` and started a second copy on the same port:

```bash
ADDR=:8080 DATA_PATH=/tmp/quicknotes-lab4-broken.json SEED_PATH=seed.json go run .
```

```text
2026/06/14 14:16:36 quicknotes listening on :8080 (notes loaded: 4)
2026/06/14 14:16:36 listen: listen tcp :8080: bind: address already in use
exit status 1
```

Root cause: the second process could not bind `:8080` because the first process already owned that port.

### 2.2 Outside-in chain

#### 1. Is it running?

```bash
ps -ef | grep quicknotes
```

```text
root      2698   898  0 14:16 ?        00:00:00 /tmp/go-build1352676339/b001/exe/quicknotes
```

Decision: one QuickNotes process was still running.

#### 2. Is it listening?

```bash
ss -tlnp | grep 8080
```

```text
LISTEN 0      4096               *:8080            *:*    users:(("quicknotes",pid=2698,fd=3))
```

Decision: PID `2698` already owned port `8080`.

#### 3. Reachable from host/container?

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
```

```text
200
```

Decision: the already-running instance was healthy, so the failed deploy was a bind conflict, not a total app outage.

#### 4. Firewall blocking?

```bash
iptables -L -n -v 2>/dev/null || nft list ruleset 2>/dev/null || true
```

```text
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

Decision: the firewall policy was accepting traffic. Since `/health` returned `200`, the failure was not caused by a firewall block.

#### 5. DNS?

```bash
dig +short localhost
```

```text
127.0.0.1
```

Decision: `localhost` resolved correctly.

### 2.3 Repair and re-verify

I killed the conflicting instance, restarted QuickNotes, and checked `/health`:

```bash
ADDR=:8080 DATA_PATH=/tmp/quicknotes-lab4-repaired.json SEED_PATH=seed.json go run .
curl -s http://localhost:8080/health
```

```text
2026/06/14 14:16:38 quicknotes listening on :8080 (notes loaded: 4)
{"notes":4,"status":"ok"}
```

Decision: after removing the port conflict, QuickNotes started and served health checks correctly.

### 2.4 Mini-postmortem

The outage was caused by two QuickNotes processes trying to own the same fixed port. This is a systemic failure because port ownership is hidden shared state: a deploy script can start a new process while an old one still exists, or a service manager can retry without cleaning up the previous instance. Better tooling would make the state explicit before deploy: a systemd unit with a clear restart policy, preflight checks for the target port, health checks that distinguish "old instance healthy" from "new instance started", and deployment automation that stops or drains the old process before binding the new one. Nobody needs blame for the bind error; the process model should make double-starts hard to create and easy to diagnose.

## Bonus - TLS Handshake

I attempted the bonus task with nginx as the TLS-terminating reverse proxy. QuickNotes still served plain HTTP on `:8080`, and nginx served HTTPS on `:8443` with a self-signed localhost certificate.

### B.1 HTTPS layer

I generated a self-signed certificate and configured nginx to proxy HTTPS traffic to QuickNotes:

```nginx
server {
  listen 8443 ssl;
  server_name localhost;
  ssl_certificate /tmp/lab4-tls/localhost.crt;
  ssl_certificate_key /tmp/lab4-tls/localhost.key;
  ssl_protocols TLSv1.2 TLSv1.3;

  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto https;
  }
}
```

Listeners:

```text
LISTEN 0      511          0.0.0.0:8443      0.0.0.0:*    users:(("nginx",pid=2661,fd=5))
LISTEN 0      4096               *:8080            *:*    users:(("quicknotes",pid=2686,fd=3))
```

### B.2 Capture the TLS handshake

```bash
tcpdump -i lo -nn -s 0 -w submissions/lab4-tls.pcap 'tcp port 8443'
curl -vk https://localhost:8443/health
```

```text
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* Server certificate:
*  subject: CN=localhost
*  issuer: CN=localhost
< HTTP/1.1 200 OK
{"notes":4,"status":"ok"}
```

The TLS capture is saved as `submissions/lab4-tls.pcap`.

### B.3 Decode the handshake

I decoded the pcap with `tshark`:

- `submissions/lab4-tls-clienthello.txt` - ClientHello decode.
- `submissions/lab4-tls-serverhello.txt` - ServerHello decode.
- `submissions/lab4-tls-certificate.txt` - certificate chain from `openssl s_client`.
- `submissions/lab4-tls-summary.txt` - concise summary.
- `submissions/lab4-tls-evidence.txt` - full command output.

ClientHello highlights:

```text
Server Name: localhost
Cipher Suite: TLS_AES_256_GCM_SHA384 (0x1302)
Cipher Suite: TLS_CHACHA20_POLY1305_SHA256 (0x1303)
Cipher Suite: TLS_AES_128_GCM_SHA256 (0x1301)
Supported Version: TLS 1.3 (0x0304)
Supported Version: TLS 1.2 (0x0303)
Supported Version: TLS 1.1 (0x0302)
Supported Version: TLS 1.0 (0x0301)
```

ServerHello highlights:

```text
Cipher Suite: TLS_AES_256_GCM_SHA384 (0x1302)
Extension: supported_versions (len=2)
Supported Version: TLS 1.3 (0x0304)
Key Share Entry: Group: x25519
```

Certificate chain:

```text
Certificate chain
 0 s:CN = localhost
   i:CN = localhost
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Jun 14 15:06:32 2026 GMT; NotAfter: Jun 15 15:06:32 2026 GMT

Verify return code: 18 (self-signed certificate)
```

The negotiation step that kills TLS 1.0 and TLS 1.1 is the protocol version negotiation in ServerHello. The client advertised multiple supported versions, including TLS 1.0 and 1.1, but nginx was configured with only `TLSv1.2 TLSv1.3`. The server selected `TLS 1.3 (0x0304)` in the `supported_versions` extension. A client that only supported TLS 1.0 or 1.1 would be rejected before any HTTP request was sent.
