# Lab 4 Submission

## Task 1 — Trace a Request End-to-End

### 1.2: Annotated TCP Trace

Below is the complete `lab4-trace.txt` with annotations for each key network layer event:

```
=== 1. TCP THREE-WAY HANDSHAKE ===

### STEP 1: Client SYN
07:23:30.742959 IP 127.0.0.1.57672 > 127.0.0.1.8080: Flags [S], seq 900566488, win 65535, options [mss 16344,nop,wscale 6,nop,nop,TS val 1145058885 ecr 0,sackOK,eol], length 0
# Client port 57672 sends SYN to server port 8080
# Flags [S] = SYN flag set
# seq 900566488 = initial sequence number

### STEP 2: Server SYN/ACK
07:23:30.745011 IP 127.0.0.1.8080 > 127.0.0.1.57672: Flags [S.], seq 2279807304, ack 900566489, win 65535, options [mss 16344,nop,wscale 6,nop,nop,TS val 2915998181 ecr 1145058885,sackOK,eol], length 0
# Server responds with SYN/ACK
# Flags [S.] = SYN and ACK flags set
# seq 2279807304 = server's initial sequence number
# ack 900566489 = server acknowledges client's seq + 1

### STEP 3: Client ACK
07:23:30.745053 IP 127.0.0.1.57672 > 127.0.0.1.8080: Flags [.], ack 1, win 6379, options [nop,nop,TS val 1145058887 ecr 2915998181], length 0
# Client sends ACK to complete handshake
# Flags [.] = ACK flag only
# Connection is now ESTABLISHED

=== 2. HTTP REQUEST (POST /notes) ===

07:23:30.745077 IP 127.0.0.1.8080 > 127.0.0.1.57672: Flags [.], ack 1, win 6379, options [nop,nop,TS val 2915998183 ecr 1145058887], length 0
# Server acknowledges established connection

### HTTP REQUEST LINE + JSON BODY
07:23:30.745121 IP 127.0.0.1.57672 > 127.0.0.1.8080: Flags [P.], seq 1:176, ack 1, win 6379, options [nop,nop,TS val 1145058887 ecr 2915998183], length 175: HTTP: POST /notes HTTP/1.1
# Flags [P.] = PUSH flag (send data immediately)
# length 175 = payload is 175 bytes
# HTTP request:
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/7.87.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
# JSON body: {"title":"trace me","body":"in flight"}

07:23:30.745155 IP 127.0.0.1.8080 > 127.0.0.1.57672: Flags [.], ack 176, win 6376, options [nop,nop,TS val 2915998183 ecr 1145058887], length 0
# Server acknowledges receipt of HTTP request

=== 3. HTTP RESPONSE (201 Created) ===

### HTTP RESPONSE LINE + RESPONSE JSON
07:23:30.746775 IP 127.0.0.1.8080 > 127.0.0.1.57672: Flags [P.], seq 1:204, ack 176, win 6376, options [nop,nop,TS val 2915998185 ecr 1145058887], length 203: HTTP: HTTP/1.1 201 Created
# Server sends HTTP response with PUSH flag
# length 203 = payload is 203 bytes
# HTTP response:
HTTP/1.1 201 Created
Content-Type: application/json
Date: Wed, 17 Jun 2026 04:23:30 GMT
Content-Length: 90

{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-17T04:23:30.745453Z"}
# Response body: JSON with created note and id=6

07:23:30.746823 IP 127.0.0.1.57672 > 127.0.0.1.8080: Flags [.], ack 204, win 6376, options [nop,nop,TS val 1145058889 ecr 2915998185], length 0
# Client acknowledges receipt of HTTP response

=== 4. CONNECTION CLOSE (FIN handshake) ===

### CLIENT SENDS FIN
07:23:30.746977 IP 127.0.0.1.57672 > 127.0.0.1.8080: Flags [F.], seq 176, ack 204, win 6376, options [nop,nop,TS val 1145058889 ecr 2915998185], length 0
# Flags [F.] = FIN flag (client initiates close)
# Client signals: "I am done sending"

07:23:30.747008 IP 127.0.0.1.8080 > 127.0.0.1.57672: Flags [.], ack 177, win 6376, options [nop,nop,TS val 2915998185 ecr 1145058889], length 0
# Server acknowledges client's FIN

### SERVER SENDS FIN
07:23:30.747032 IP 127.0.0.1.8080 > 127.0.0.1.57672: Flags [F.], seq 204, ack 177, win 6376, options [nop,nop,TS val 2915998185 ecr 1145058889], length 0
# Flags [F.] = FIN flag (server responds with FIN)
# Server signals: "I am done sending"

07:23:30.747074 IP 127.0.0.1.57672 > 127.0.0.1.8080: Flags [.], ack 205, win 6376, options [nop,nop,TS val 1145058889 ecr 2915998185], length 0
# Client acknowledges server's FIN
# Connection is now CLOSED
```

### 1.3: Debugging Commands Output

#### Command 1: What is listening on port 8080?

```bash
netstat -an | grep ".8080.*LISTEN"
```

Output:
```
tcp46      0      0  *.8080                 *.*                    LISTEN
```

Note: QuickNotes is currently running on the 8080 port

#### Command 2: IP Routes from your host

```bash
ip route show
```

Output:
```
0.0.0.0/1 via utun3 dev utun3
default via 10.16.64.1 dev en0
10.8.1.2/32 via 10.8.1.2 dev utun3
10.16.64.0/20 dev en0  scope link
10.16.64.1/32 dev en0  scope link
10.16.79.184/32 dev en0  scope link
127.0.0.0/8 via 127.0.0.1 dev lo0
127.0.0.1/32 via 127.0.0.1 dev lo0
128.0.0.0/1 via utun3 dev utun3
169.254.0.0/16 dev en0  scope link
212.192.215.102/32 via 10.16.64.1 dev en0
224.0.0.0/4 dev en0  scope link
255.255.255.255/32 dev en0  scope link
```

Note: The `127.0.0.0/8 via 127.0.0.1 dev lo0` route shows that localhost traffic is routed through the loopback interface (lo0).

#### Command 3: Reachability to localhost

```bash
sudo mtr -rwc 5 localhost
```

Output:
```
Start: 2026-06-17T07:37:10+0300
HOST: Sergeys-MacBook-Air.local Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost                  0.0%     5    0.3   0.2   0.2   0.3   0.0
```

Note: `mtr` combines ping and traceroute into one tool. The output shows a single hop to localhost with 0.0% packet loss across all 5 probes. Round-trip time is stable: best 0.2 ms, average 0.2 ms, worst 0.3 ms, standard deviation 0.0 ms. A single hop is expected because loopback traffic never leaves the machine.

#### Command 4: DNS resolution

```bash
dig +short example.com @1.1.1.1
```

Output:
```
172.66.147.243
104.20.23.154
example.com has IPv6 address 2606:4700:10::6814:179a
example.com has IPv6 address 2606:4700:10::ac42:93f3
```

Note: DNS resolution works; example.com resolves to two IPv4 and two IPv6 addresses via the Cloudflare DNS server at 1.1.1.1.

#### Command 5: Service logs

```bash
journalctl --user -u quicknotes -n 20
```

Output:
```
journalctl: no user service for quicknotes
```

Note: QuickNotes is not installed as it macos, so there are no journal logs. In a production setup with systemd service management, this command would show service errors, restarts, and other lifecycle events.

But in general, it is good practice for cloud-native applications to output logs to stdout, but for some reason the quicknotes application does not do this.

### 1.4: Troubleshooting a 502 Error

**If QuickNotes returned an HTTP 502 Bad Gateway, where would you look first?**

First, I would check if QuickNotes is actually listening on port 8080 using `netstat -an | grep ".8080.*LISTEN"`. If no process is bound to the port, the service has crashed or failed to start. Next, I would check the application logs using `journalctl --user -u quicknotes` (if it is a systemd service) or I'll look in a specialized unified log storage like ELK/Loki if they are configured. Finally, I would verify that the localhost routing is correct using `ip route show` and confirm network connectivity with `ping localhost`. A 502 typically means the reverse proxy or load balancer cannot reach the backend application, so verifying the application process exists and is listening is the fastest way to rule in or out a service-level failure.

## Task 2 - Outside-In Debugging on a Broken Deploy

### 2.1: Run a broken instance

I reproduced the broken condition by starting another instance on the same address (`:8080`) while one instance was already listening.

Command:
```bash
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log
```

Output (exact):
```
2026/06/17 19:54:35 quicknotes listening on :8080 (notes loaded: 7)
2026/06/17 19:54:35 listen: listen tcp :8080: bind: address already in use
exit status 1
```

The bind failure is captured in `/tmp/qn-broken.log`.

### 2.2: Outside-in chain 

#### Step 1: Is it running?

Command:
```bash
ps -ef | grep quicknotes | grep -v grep
```

Output:
```
  501 66439 78415   0  7:46AM ttys000    0:00.01 log stream --predicate process == "quicknotes" --style syslog
  501 45622 45615   0  7:17AM ttys008    0:00.03 /var/folders/pl/7blry4vs02z71p4sjnjmd0ww0000gn/T/go-build734188524/b001/exe/quicknotes
```

Decision: QuickNotes process exists, so the service binary is running.

#### Step 2: Is it listening? (netstat instead of ss because of macos)

Command:
```bash
netstat -anv -p tcp | grep '\.8080 .*LISTEN'
```

Output:
```
tcp46      0      0  *.8080                 *.*                    LISTEN       131072  131072  45622      0 00100 00000006 0000000000a1a33a 00000000 00000800      1      0 000001
```

Decision: Port 8080 is occupied by PID 45622, which explains why a second instance cannot bind.

#### Step 3: Reachable from host?

Command:
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
```

Output:
```
200
```

Decision: Host-level connectivity is good. One healthy backend is reachable.

#### Step 4: Firewall blocking? (macOS alternative)

Command:
```bash
sudo -n pfctl -sr 2>/dev/null || pfctl -sr 2>/dev/null || echo "pfctl rules unavailable (pf disabled or requires privileges)"
```

Output:
```
pfctl rules unavailable (pf disabled or requires privileges)
```

Decision: No evidence of PF firewall rules blocking localhost traffic in this test.

#### Step 5: DNS?

Command:
```bash
dig +short localhost
```

Output:
```

```

Decision: `dig` is DNS-focused and may not show `/etc/hosts` results on macOS. For local resolver confirmation:

Command:
```bash
dscacheutil -q host -a name localhost
```

Output:
```
name: localhost
ipv6_address: ::1

name: localhost
ip_address: 127.0.0.1
```

Decision: Local name resolution for `localhost` is correct.

### 2.3: Repair + re-verify

I killed the listener on port 8080, started one clean instance, and verified health.

Commands:
```bash
PID1=$(lsof -nP -iTCP:8080 -sTCP:LISTEN -t | head -n1)
echo "PID1=$PID1"
kill "$PID1"
ADDR=:8080 go run .
curl -s http://localhost:8080/health
```

Key output:
```
PID1=45622
{"notes":7,"status":"ok"}
```

Re-verify status code:

Command:
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
```

Output:
```
200
```

### 2.4: Root cause and mini-postmortem

Root cause: `listen tcp :8080: bind: address already in use`.

Blameless mini-postmortem (<=200 words):

This failure is systemic: local dev and deploy scripts often assume the target port is free, but stale processes, previous runs, or parallel deploy attempts can leave ports occupied. 

Nothing wrong was done by one person; the process lacked guardrails. The app itself behaved correctly by refusing to bind an already-used socket, but the startup workflow did not detect the conflict early or recover automatically. To prevent this class of issue, we should add preflight checks (`lsof`/`netstat`) before start, include clear startup error surfacing in logs and CI checks, and use a supervisor (launchd/systemd) with restart/backoff policies and explicit port ownership. 

In containerized or orchestrated setups, readiness probes and one-instance-per-port service definitions reduce accidental collisions. The key improvement is not blame; it is improving automation so port conflicts are detected before users notice outages.
