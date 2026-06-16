# Lab 4 Submission

Environment: Ubuntu 24.04 WSL2, running as root for packet capture. I installed the missing lab tools in WSL: `tcpdump`, `dnsutils`, `mtr-tiny`, `jq`, `iptables`, `nftables`, and official Go `1.24.13`. QuickNotes was run with `go run .` from `app/`.

## Task 1 - Trace a Request End-to-End

### 1.1 Start QuickNotes and Capture

QuickNotes startup:

```text
$ cd app/
$ ADDR=:8080 DATA_PATH=/tmp/qn-lab4-notes.json SEED_PATH=seed.json /usr/local/go1.24.13/bin/go run .
2026/06/15 23:44:59 quicknotes listening on :8080 (notes loaded: 4)
```

Packet capture:

```text
$ tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w /tmp/lab4-trace.pcap
tcpdump: listening on lo, link-type EN10MB (Ethernet), snapshot length 262144 bytes
10 packets captured
20 packets received by filter
0 packets dropped by kernel
```

Request:

```text
$ curl -v -X POST http://127.0.0.1:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
Note: Unnecessary use of -X or --request, POST is already inferred.
*   Trying 127.0.0.1:8080...
* Connected to 127.0.0.1 (127.0.0.1) port 8080
> POST /notes HTTP/1.1
> Host: 127.0.0.1:8080
> User-Agent: curl/8.5.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 39
>
< HTTP/1.1 201 Created
< Content-Type: application/json
< Date: Mon, 15 Jun 2026 20:45:00 GMT
< Content-Length: 93
<
{"id":5,"title":"trace me","body":"in flight","created_at":"2026-06-15T20:45:00.935400747Z"}
* Connection #0 to host 127.0.0.1 left intact
```

### 1.2 Annotated Packet Decode

Decoded with:

```text
$ tcpdump -r /tmp/lab4-trace.pcap -nn -A
```

Three-way handshake:

```text
23:45:00.934679 IP 127.0.0.1.39264 > 127.0.0.1.8080: Flags [S], seq 1360833904, win 65495, options [mss 65495,sackOK,TS val 2451582144 ecr 0,nop,wscale 7], length 0
23:45:00.934694 IP 127.0.0.1.8080 > 127.0.0.1.39264: Flags [S.], seq 4156630879, ack 1360833905, win 65483, options [mss 65495,sackOK,TS val 2451582144 ecr 2451582144,nop,wscale 7], length 0
23:45:00.934705 IP 127.0.0.1.39264 > 127.0.0.1.8080: Flags [.], ack 1, win 512, options [nop,nop,TS val 2451582144 ecr 2451582144], length 0
```

The client sends SYN, the server answers SYN/ACK, and the client completes the handshake with ACK.

HTTP request and JSON body:

```text
23:45:00.934848 IP 127.0.0.1.39264 > 127.0.0.1.8080: Flags [P.], seq 1:175, ack 1, win 512, options [nop,nop,TS val 2451582144 ecr 2451582144], length 174: HTTP: POST /notes HTTP/1.1
POST /notes HTTP/1.1
Host: 127.0.0.1:8080
User-Agent: curl/8.5.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

HTTP response and response JSON:

```text
23:45:00.936338 IP 127.0.0.1.8080 > 127.0.0.1.39264: Flags [P.], seq 1:207, ack 175, win 512, options [nop,nop,TS val 2451582145 ecr 2451582144], length 206: HTTP: HTTP/1.1 201 Created
HTTP/1.1 201 Created
Content-Type: application/json
Date: Mon, 15 Jun 2026 20:45:00 GMT
Content-Length: 93

{"id":5,"title":"trace me","body":"in flight","created_at":"2026-06-15T20:45:00.935400747Z"}
```

Connection close:

```text
23:45:00.936602 IP 127.0.0.1.39264 > 127.0.0.1.8080: Flags [F.], seq 175, ack 207, win 512, options [nop,nop,TS val 2451582145 ecr 2451582145], length 0
23:45:00.936724 IP 127.0.0.1.8080 > 127.0.0.1.39264: Flags [F.], seq 207, ack 176, win 512, options [nop,nop,TS val 2451582146 ecr 2451582145], length 0
23:45:00.936740 IP 127.0.0.1.39264 > 127.0.0.1.8080: Flags [.], ack 208, win 512, options [nop,nop,TS val 2451582146 ecr 2451582146], length 0
```

The client begins close with FIN/ACK, the server replies FIN/ACK, and the client ACKs the server close.

### 1.3 Five Debugging Commands

Listening socket:

```text
$ ss -tlnp | grep :8080
LISTEN 0      4096                *:8080            *:*    users:(("quicknotes",pid=570,fd=3))
```

Decision: QuickNotes is actually bound to TCP port 8080, so a local connection should reach the process.

Routes:

```text
$ ip route show
default via 172.17.192.1 dev eth0 proto kernel
172.17.192.0/20 dev eth0 proto kernel scope link src 172.17.202.111
```

Decision: WSL has a default route via its virtual network, but the QuickNotes request used loopback, so the external route is not in the data path for this request.

Reachability:

```text
$ mtr -rwc 5 localhost
Start: 2026-06-15T23:45:02+0300
HOST: skebob    Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.1   0.1   0.1   0.1   0.0
```

Decision: Loopback reachability is healthy with zero packet loss and about 0.1 ms latency.

DNS:

```text
$ dig +short example.com @1.1.1.1
172.66.147.243
104.20.23.154
```

Decision: External DNS resolution through Cloudflare DNS works from the WSL environment.

Journal:

```text
$ journalctl --user -u quicknotes -n 20
-- No entries --
```

Decision: QuickNotes was run directly with `go run .`, not installed as a user systemd service, so there are no user journal entries for `quicknotes`.

### 1.4 If QuickNotes Returned 502

I would start at the layer that produced the 502, usually the reverse proxy or load balancer, because a 502 means the proxy could not get a valid response from the upstream. First I would check whether QuickNotes is listening on the configured host and port with `ss -tlnp`, then verify direct upstream health with `curl http://127.0.0.1:8080/health`. If direct health works, I would inspect proxy config, upstream DNS, and proxy logs; if direct health fails, I would move down to process state, bind errors, firewall rules, and application logs.

## Task 2 - Outside-In Debugging on a Broken Deploy

### 2.1 Broken Instance

I started one QuickNotes process on `:8080`, then started a second process on the same port.

```text
$ ADDR=:8080 DATA_PATH=/tmp/qn-lab4-broken1.json SEED_PATH=seed.json /usr/local/go1.24.13/bin/go run . &
PID1=388

$ ADDR=:8080 DATA_PATH=/tmp/qn-lab4-broken2.json SEED_PATH=seed.json /usr/local/go1.24.13/bin/go run . 2>&1 | tee /tmp/qn-broken.log &
PID2=570
```

Processes:

```text
$ ps -ef | grep 'go run' | grep -v grep
root         388     384 14 23:46 pts/0    00:00:00 /usr/local/go1.24.13/bin/go run .

$ ps -ef | grep quicknotes | grep -v grep
root         562     388  0 23:46 pts/0    00:00:00 /root/.cache/go-build/bf/bf9966fb130f0e7b32237a756c1a13bf804f8a57f1d97917c1a7c635d8a94405-d/quicknotes
```

Exact error from the failed second process:

```text
2026/06/15 23:46:05 quicknotes listening on :8080 (notes loaded: 4)
2026/06/15 23:46:05 listen: listen tcp :8080: bind: address already in use
exit status 1
```

Root cause: the first QuickNotes process already owned `:8080`, so the second process could not bind the same address.

### 2.2 Outside-In Chain

1. Is a QuickNotes process running?

```text
$ ps -ef | grep quicknotes
root         562     388  0 23:46 pts/0    00:00:00 /root/.cache/go-build/bf/bf9966fb130f0e7b32237a756c1a13bf804f8a57f1d97917c1a7c635d8a94405-d/quicknotes
```

Decision: One QuickNotes process is running. The failed process exited, but the first instance is still alive.

2. Is it listening?

```text
$ ss -tlnp | grep 8080
LISTEN 0      4096                *:8080            *:*    users:(("quicknotes",pid=562,fd=3))
```

Decision: Port 8080 is occupied by the existing QuickNotes process, confirming the bind conflict.

3. Is it reachable from host?

```text
$ curl -s -o /tmp/lab4-chain-health-body.txt -w '%{http_code}\n' http://localhost:8080/health
200

$ cat /tmp/lab4-chain-health-body.txt
{"notes":4,"status":"ok"}
```

Decision: The running first instance is healthy. The incident is not total app downtime; it is a failed second deploy/startup.

4. Is a firewall blocking?

```text
$ iptables -L -n -v
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

Decision: The default policies are ACCEPT and there are no blocking rules in this WSL environment, so firewall policy is not the cause.

5. DNS?

```text
$ dig +short localhost
127.0.0.1
```

Decision: `localhost` resolves to loopback as expected. DNS is not the cause.

### 2.3 Repair and Re-Verify

`go run` leaves a compiled QuickNotes child process, so I killed both the wrapper and the child before starting a clean instance.

```text
$ pkill -f 'go run .' || true
$ pkill -f quicknotes || true
$ ss -tlnp | grep 8080 || true

$ ADDR=:8080 DATA_PATH=/tmp/qn-lab4-repair.json SEED_PATH=seed.json /usr/local/go1.24.13/bin/go run . &
PID3=369

$ cat /tmp/qn-repair.log
2026/06/15 23:46:34 quicknotes listening on :8080 (notes loaded: 4)

$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}

$ ss -tlnp | grep 8080
LISTEN 0      4096                *:8080            *:*    users:(("quicknotes",pid=544,fd=3))
```

Decision: After the conflicting process was removed, a fresh QuickNotes instance bound `:8080` and returned healthy status.

### 2.4 Blameless Mini-Postmortem

The failure was a port ownership conflict: a new QuickNotes process was started before the old listener released `:8080`. Systemically, this happens when process lifecycle is implicit and deployments do not have a single supervisor responsible for stop, start, health checks, and rollback. Tooling can prevent this by running the app under systemd or a container orchestrator with one service definition, explicit restart policy, readiness checks, and logs tied to the unit. A pre-start check such as `ss -tlnp` or a health-gated deployment script would catch the conflict before reporting the deploy as successful.

## Bonus Task

### B.1 HTTPS layer with Caddy

I terminated TLS with Caddy on `localhost:8443` and proxied traffic to the QuickNotes HTTP server on `127.0.0.1:8080`.

```caddyfile
{
  auto_https disable_redirects
}

localhost:8443 {
  tls internal
  reverse_proxy 127.0.0.1:8080
}
```

QuickNotes backend:

```text
2026/06/16 10:25:29 quicknotes listening on :8080 (notes loaded: 4)
```

Caddy started and obtained a local internal certificate:

```text
{"level":"info","msg":"using provided configuration","config_file":"/tmp/lab4-Caddyfile","config_adapter":"caddyfile"}
{"level":"info","logger":"http","msg":"enabling HTTP/3 listener","addr":":8443"}
{"level":"info","logger":"http","msg":"enabling automatic TLS certificate management","domains":["localhost"]}
{"level":"info","logger":"tls.obtain","msg":"certificate obtained successfully","identifier":"localhost"}
```

Listener verification:

```text
LISTEN 0 4096 *:8443 *:* users:(("caddy",pid=603,fd=7))
```

### B.2 TLS capture

Capture command:

```bash
tcpdump -i lo -nn -s 0 -w /tmp/lab4-tls.pcap 'tcp port 8443'
curl -vk https://localhost:8443/health
```

The HTTPS request succeeded through the TLS proxy:

```text
* Connected to localhost (::1) port 8443
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256 / X25519 / id-ecPublicKey
* ALPN: server accepted h2
* Server certificate:
*  issuer: CN=Caddy Local Authority - ECC Intermediate
* SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
> GET /health HTTP/2
< HTTP/2 200
< server: Caddy
{"notes":4,"status":"ok"}
```

Capture result:

```text
tcpdump: listening on lo, link-type EN10MB (Ethernet), snapshot length 262144 bytes
21 packets captured
42 packets received by filter
0 packets dropped by kernel
```

### B.3 Decoded handshake

I decoded `lab4-tls.pcap` with Wireshark's CLI decoder, `tshark`, to capture the same fields requested for the Wireshark screenshots.

ClientHello:

```text
Frame 4: 603 bytes on wire (4824 bits), 603 bytes captured (4824 bits)
TLSv1 Record Layer: Handshake Protocol: Client Hello
  Version: TLS 1.0 (0x0301)
  Handshake Protocol: Client Hello
    Version: TLS 1.2 (0x0303)
    Cipher Suites (31 suites)
      Cipher Suite: TLS_AES_256_GCM_SHA384 (0x1302)
      Cipher Suite: TLS_CHACHA20_POLY1305_SHA256 (0x1303)
      Cipher Suite: TLS_AES_128_GCM_SHA256 (0x1301)
      Cipher Suite: TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 (0xc02c)
      Cipher Suite: TLS_EMPTY_RENEGOTIATION_INFO_SCSV (0x00ff)
    Extension: server_name (len=14) name=localhost
      Server Name: localhost
    Extension: supported_versions (len=5) TLS 1.3, TLS 1.2
      Supported Version: TLS 1.3 (0x0304)
      Supported Version: TLS 1.2 (0x0303)
```

ServerHello:

```text
Frame 6: 1506 bytes on wire (12048 bits), 1506 bytes captured (12048 bits)
TLSv1.2 Record Layer: Handshake Protocol: Server Hello
  Handshake Protocol: Server Hello
    Version: TLS 1.2 (0x0303)
    Cipher Suite: TLS_AES_128_GCM_SHA256 (0x1301)
    Extension: supported_versions (len=2) TLS 1.3
      Supported Version: TLS 1.3 (0x0304)
```

Certificate chain:

```text
Certificate chain
 0 s:
   i:CN = Caddy Local Authority - ECC Intermediate
   a:PKEY: id-ecPublicKey, 256 (bit); sigalg: ecdsa-with-SHA256
   v:NotBefore: Jun 16 07:25:29 2026 GMT; NotAfter: Jun 16 19:25:29 2026 GMT
 1 s:CN = Caddy Local Authority - ECC Intermediate
   i:CN = Caddy Local Authority - 2026 ECC Root
   a:PKEY: id-ecPublicKey, 256 (bit); sigalg: ecdsa-with-SHA256
   v:NotBefore: Jun 16 07:25:29 2026 GMT; NotAfter: Jun 23 07:25:29 2026 GMT
Server certificate
subject=
issuer=CN = Caddy Local Authority - ECC Intermediate
Peer signing digest: SHA256
Peer signature type: ECDSA
Server Temp Key: X25519, 253 bits
New, TLSv1.3, Cipher is TLS_AES_128_GCM_SHA256
Verify return code: 20 (unable to get local issuer certificate)
```

### TLS 1.0 / 1.1 deprecation note

TLS 1.0 and TLS 1.1 are eliminated during version negotiation. The `TLS 1.0 (0x0301)` record version and `TLS 1.2 (0x0303)` ClientHello version shown above are compatibility fields, not the selected protocol. The real offer is the `supported_versions` extension, where this client offered only `TLS 1.3` and `TLS 1.2`. The server selected `TLS 1.3` in its ServerHello `supported_versions` extension. A client that only supported TLS 1.0 or 1.1 would fail at this ClientHello/ServerHello negotiation step with a protocol-version failure instead of reaching HTTP.
