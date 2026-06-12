# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

## Environment

- OS/terminal used: WSL Ubuntu
- Repository branch: `feature/lab4`
- QuickNotes address: `http://localhost:8080`
- Go version used: Go 1.25.10 installed manually because the default Ubuntu Go 1.18 package was too old for this project.

---

## Task 1 — Trace a Request End-to-End

### 1.1 Start QuickNotes + capture

I started QuickNotes in Terminal A:

```bash
cd "/mnt/f/Innopolis 3 year/Devops/Lab work/DevOps-Intro/app"
go run .
```

Then I captured loopback traffic on port `8080` in Terminal B:

```bash
cd "/mnt/f/Innopolis 3 year/Devops/Lab work/DevOps-Intro"
rm -f lab4-trace.pcap
sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap
```

In Terminal C, I sent one POST request:

```bash
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

The request succeeded:

```text
Note: Unnecessary use of -X or --request, POST is already inferred.
* Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> POST /notes HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.81.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 39
>
< HTTP/1.1 201 Created
< Content-Type: application/json
< Date: Fri, 12 Jun 2026 09:27:28 GMT
< Content-Length: 93
<
{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-12T09:27:28.846334414Z"}
* Connection #0 to host localhost left intact
```

The packet capture was saved successfully:

```text
10 packets captured
20 packets received by filter
0 packets dropped by kernel
-rwxrwxrwx 1 student student 1.3K Jun 12 12:27 lab4-trace.pcap
```

---

### 1.2 Decode the capture

I decoded the capture with:

```bash
sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt
```

The decoded trace was saved:

```text
-rwxrwxrwx 1 student student 2.5K Jun 12 12:29 lab4-trace.txt
```

#### TCP three-way handshake

The TCP three-way handshake happened between client port `38598` and server port `8080`.

SYN:

```text
12:27:28.844508 IP 127.0.0.1.38598 > 127.0.0.1.8080: Flags [S], seq 3686440765, win 65495, options [mss 65495,sackOK,TS val 1319835283 ecr 0,nop,wscale 10], length 0
```

SYN/ACK:

```text
12:27:28.844534 IP 127.0.0.1.8080 > 127.0.0.1.38598: Flags [S.], seq 2228375971, ack 3686440766, win 65483, options [mss 65495,sackOK,TS val 3297634934 ecr 1319835283,nop,wscale 10], length 0
```

ACK:

```text
12:27:28.844554 IP 127.0.0.1.38598 > 127.0.0.1.8080: Flags [.], ack 1, win 64, options [nop,nop,TS val 1319835283 ecr 3297634934], length 0
```

#### HTTP request

The HTTP request line and JSON body were visible in plain text because this was HTTP, not HTTPS:

```text
12:27:28.845521 IP 127.0.0.1.38598 > 127.0.0.1.8080: Flags [P.], seq 1:176, ack 1, win 64, options [nop,nop,TS val 1319835284 ecr 3297634934], length 175: HTTP: POST /notes HTTP/1.1

POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/7.81.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

#### HTTP response

The server responded with `201 Created` and returned the created note as JSON:

```text
12:27:28.857234 IP 127.0.0.1.8080 > 127.0.0.1.38598: Flags [P.], seq 1:207, ack 176, win 64, options [nop,nop,TS val 3297634947 ecr 1319835284], length 206: HTTP: HTTP/1.1 201 Created

HTTP/1.1 201 Created
Content-Type: application/json
Date: Fri, 12 Jun 2026 09:27:28 GMT
Content-Length: 93

{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-12T09:27:28.846334414Z"}
```

#### Connection close

The connection closed cleanly using FIN packets.

Client FIN:

```text
12:27:28.857618 IP 127.0.0.1.38598 > 127.0.0.1.8080: Flags [F.], seq 176, ack 207, win 64, options [nop,nop,TS val 1319835296 ecr 3297634947], length 0
```

Server FIN:

```text
12:27:28.857818 IP 127.0.0.1.8080 > 127.0.0.1.38598: Flags [F.], seq 207, ack 177, win 64, options [nop,nop,TS val 3297634947 ecr 1319835296], length 0
```

Final ACK:

```text
12:27:28.857845 IP 127.0.0.1.38598 > 127.0.0.1.8080: Flags [.], ack 208, win 64, options [nop,nop,TS val 1319835296 ecr 3297634947], length 0
```

This trace shows the complete flow: TCP handshake, HTTP POST request, HTTP `201 Created` response, and clean connection close.

---

### 1.3 Five debugging commands

#### 1. What is listening?

Command:

```bash
ss -tlnp | grep :8080
```

Output:

```text
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=180,fd=3))
```

Decision:

```text
QuickNotes is listening on TCP port 8080. The process name is quicknotes, and the listening socket is open, so the application is reachable at the transport layer.
```

#### 2. Routes from the host

Command:

```bash
ip route show
```

Output:

```text
default via 172.31.208.1 dev eth0 proto kernel
172.31.208.0/20 dev eth0 proto kernel scope link src 172.31.213.166
```

Decision:

```text
The host has a valid route table. Since the request uses localhost, the traffic stays on the loopback path rather than going through the external default route.
```

#### 3. Reachability

Command:

```bash
mtr -rwc 5 localhost
```

Output:

```text
Start: 2026-06-12T12:37:56+0300
HOST: DESKTOP-KC8JMBQ                 Loss%   Snt   Last   Avg   Best   Wrst  StDev
  1.|-- localhost                       0.0%     5    0.1   0.1    0.1    0.2    0.0
```

Decision:

```text
localhost is reachable with 0.0% packet loss. This confirms that the local loopback path is working.
```

#### 4. DNS works

Command:

```bash
dig +short example.com @1.1.1.1
```

Output:

```text
8.47.69.0
8.6.112.0
```

Decision:

```text
DNS resolution works when querying the Cloudflare resolver at 1.1.1.1. This means DNS is not broken on this host for this test.
```

#### 5. Logs

Command:

```bash
journalctl --user -u quicknotes -n 20 || true
```

Output:

```text
-- No entries --
```

Decision:

```text
There are no user-level systemd journal entries for quicknotes because QuickNotes was run manually with go run instead of being installed as a user systemd service.
```

---

### 1.4 502 debugging reflection

If QuickNotes returned `502 Bad Gateway`, I would first check whether the backend process is actually running and listening on the expected port. A 502 usually means a reverse proxy or load balancer could not get a valid response from the upstream service. I would start with `ss -tlnp | grep :8080` to confirm that QuickNotes is listening, then run `curl http://localhost:8080/health` from the host to test the backend directly. If the backend is not listening or the health check fails, I would inspect the application logs and process state next. If the backend works locally, I would then check the proxy configuration, firewall rules, and DNS.

---

## Task 2 — Outside-In Debugging on a Broken Deploy

### 2.1 Run a broken instance

I reproduced the broken deployment by starting one QuickNotes process on port `8080`, then trying to start a second process on the same port.

Commands used:

```bash
cd "/mnt/f/Innopolis 3 year/Devops/Lab work/DevOps-Intro/app"

ADDR=:8080 go run . &
PID1=$!
echo "PID1=$PID1"

sleep 1

ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &
PID2=$!
echo "PID2=$PID2"

sleep 2

ps -ef | grep "go run" | grep -v grep

cat /tmp/qn-broken.log
```

Output:

```text
PID1=265
2026/06/12 12:43:08 quicknotes listening on :8080 (notes loaded: 7)

PID2=305
2026/06/12 12:43:09 quicknotes listening on :8080 (notes loaded: 7)
2026/06/12 12:43:09 listen: listen tcp :8080: bind: address already in use
exit status 1

student      265      11 13 12:43 pts/0    00:00:00 go run .
```

Exact error:

```text
listen: listen tcp :8080: bind: address already in use
```

This shows that the second QuickNotes instance failed because the first instance was already bound to port `8080`.

---

### 2.2 Outside-in debugging chain

#### 1. Is it running?

Command:

```bash
ps -ef | grep quicknotes
```

Output:

```text
student      297     265  0 12:43 pts/0    00:00:00 /home/student/.cache/go-build/75/7573b27931157697e0af35e53ba44da69fe941fee97bba942fbdf238387c3dc4-d/quicknotes
student      353      11  0 12:51 pts/0    00:00:00 grep --color=auto quicknotes
```

Decision:

```text
A QuickNotes binary is running. The grep process is only from the search command, so the real application process is the quicknotes binary with PID 297.
```

#### 2. Is it listening?

Command:

```bash
ss -tlnp | grep 8080
```

Output:

```text
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=297,fd=3))
```

Decision:

```text
QuickNotes is listening on TCP port 8080. This confirms that one instance is already using the port, which explains why the second instance could not bind to the same address.
```

#### 3. Reachable from host?

Command:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
```

Output:

```text
200
```

Decision:

```text
The running QuickNotes instance is reachable from the host and the health endpoint returns HTTP 200. The service itself works, but a second copy cannot start on the same port.
```

#### 4. Firewall blocking?

Command:

```bash
sudo iptables -L -n -v 2>/dev/null || sudo nft list ruleset 2>/dev/null || true
```

Output:

```text
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

Decision:

```text
The firewall policy is ACCEPT and no blocking rule is shown. Firewall filtering is not the cause of this failure.
```

#### 5. DNS?

Command:

```bash
dig +short localhost
```

Output:

```text

```

Decision:

```text
dig did not return a DNS record for localhost, but this did not prevent local access because curl to http://localhost:8080/health worked. In this environment, localhost resolution is handled locally by the system rather than by normal external DNS.
```

---

### 2.3 Repair and re-verify

I killed the conflicting first process and started QuickNotes again.

Commands used:

```bash
kill 265
sleep 1
ADDR=:8080 go run . &
sleep 1
curl -s http://localhost:8080/health
```

Output:

```text
[1]+  Terminated              ADDR=:8080 go run .
2026/06/12 13:00:13 quicknotes listening on :8080 (notes loaded: 7)
{"notes":7,"status":"ok"}
```

Decision:

```text
After stopping the old process and starting QuickNotes again, the health endpoint returned {"notes":7,"status":"ok"}. The repair was successful.
```

---

### 2.4 Root cause

```text
The broken instance failed because port 8080 was already in use. The first QuickNotes process had already bound to :8080, so the second QuickNotes process could not bind to the same address and exited with: listen tcp :8080: bind: address already in use.
```

---

### 2.5 Mini-postmortem

```text
The failure happened because two QuickNotes instances were started with the same address and port. This is a common service-management problem rather than an individual mistake: without a supervisor or pre-start check, it is easy to accidentally start duplicate processes during debugging or deployment. The system allowed one instance to continue running while the second failed immediately with a bind error. Better tooling could prevent this by using systemd to manage only one service instance, checking port availability before startup, and making deployment scripts fail clearly when the port is already occupied. Monitoring should also alert when a service fails to bind or repeatedly exits during startup.
```

---

## Bonus Task — Decode the TLS Handshake

Attempted: Yes

### B.1 Add an HTTPS layer

Caddy was not available from the current Ubuntu package sources:

```text
E: Unable to locate package caddy
```

As an alternative, I used OpenSSL to create a local self-signed certificate and run a TLS server on port `8443`.

Certificate generation command:

```bash
cd "/mnt/f/Innopolis 3 year/Devops/Lab work/DevOps-Intro"

openssl req -x509 -newkey rsa:2048 \
  -keyout lab4-local.key \
  -out lab4-local.crt \
  -days 1 -nodes \
  -subj "/CN=localhost"
```

TLS server command:

```bash
openssl s_server -accept 8443 \
  -cert lab4-local.crt \
  -key lab4-local.key \
  -www
```

The server started successfully:

```text
Using default temp DH parameters
ACCEPT
```

---

### B.2 Capture the TLS handshake

I captured TLS traffic on loopback port `8443`:

```bash
cd "/mnt/f/Innopolis 3 year/Devops/Lab work/DevOps-Intro"

rm -f lab4-tls.pcap

sudo tcpdump -i lo -nn -s 0 -w lab4-tls.pcap 'tcp port 8443'
```

Then I sent a TLS request:

```bash
curl -vk https://localhost:8443/
```

The TLS packet capture succeeded:

```text
18 packets captured
36 packets received by filter
0 packets dropped by kernel
-rwxrwxrwx 1 student student 9.1K Jun 12 13:22 lab4-tls.pcap
```

---

### B.3 Decode TLS handshake and certificate chain

I saved the verbose curl TLS output:

```bash
curl -vk https://localhost:8443/ 2>&1 | tee lab4-tls-curl.txt
```

Important TLS handshake lines:

```text
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
```

This shows that the client sent a `ClientHello`, the server replied with a `ServerHello`, the server sent a certificate, and the final negotiated protocol was `TLSv1.3`.

The selected cipher suite was:

```text
TLS_AES_256_GCM_SHA384
```

The server certificate shown by curl was:

```text
Server certificate:
subject: CN=localhost
issuer: CN=localhost
SSL certificate verify result: self-signed certificate (18), continuing anyway.
```

I also saved the certificate chain:

```bash
openssl s_client -connect localhost:8443 -showcerts </dev/null 2>&1 | tee lab4-cert-chain.txt
```

Important certificate-chain output:

```text
Certificate chain
 0 s:CN = localhost
   i:CN = localhost
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Jun 12 10:19:30 2026 GMT; NotAfter: Jun 13 10:19:30 2026 GMT
```

The OpenSSL client also confirmed the negotiated TLS version and cipher:

```text
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 2048 bit
Verification error: self-signed certificate
Verify return code: 18 (self-signed certificate)
```

### TLS 1.0 / 1.1 deprecation reasoning

The negotiation step that effectively kills TLS 1.0 and TLS 1.1 is the version and cipher negotiation during `ClientHello` and `ServerHello`. The client offers supported modern protocol versions and cipher suites, and the server chooses one. In this capture, the final negotiated protocol was `TLSv1.3`, not TLS 1.0 or TLS 1.1. In modern deployments, servers should disable TLS 1.0 and TLS 1.1, so if a client only supports those old versions, the server should refuse the handshake instead of selecting an insecure protocol.

Note: I could not use Caddy from apt because it was not available in my Ubuntu package sources, so I used OpenSSL `s_server` on port `8443` as a local TLS endpoint. I decoded the handshake using `curl -vk`, `openssl s_client`, and the captured `lab4-tls.pcap`. This still shows the ClientHello, ServerHello, negotiated TLS version/cipher, and certificate chain.

---

## What surprised me

What surprised me most was how much of the HTTP request was visible in the packet capture when using plain HTTP. The `POST /notes` request line, headers, and JSON body were readable directly in `tcpdump`, which made the difference between HTTP and HTTPS very clear. I also noticed that a service can be healthy and reachable while a second deployment still fails, simply because the port is already occupied. This showed me why checking the listening socket with `ss` is one of the first useful debugging steps.