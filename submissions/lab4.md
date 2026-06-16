# Lab 4

## Task 1

### Decode the capture

The packet capture in `lab4-trace.txt` shows a complete localhost request to QuickNotes over IPv6 loopback (`::1`) on port `8080`. The relevant request starts at `10:07:22.001973`.

#### TCP three-way handshake

```text
10:07:22.001973 IP6 ::1.41078 > ::1.8080: Flags [S], seq 1569259689, ... length 0
10:07:22.002000 IP6 ::1.8080 > ::1.41078: Flags [S.], seq 3570494351, ack 1569259690, ... length 0
10:07:22.002013 IP6 ::1.41078 > ::1.8080: Flags [.], ack 1, ... length 0
```

Annotation:

- The first packet is the client SYN from ephemeral port `41078` to QuickNotes on port `8080`.
- The second packet is the server SYN/ACK from port `8080` back to the client.
- The third packet is the client ACK, completing the TCP three-way handshake.

#### HTTP request

```text
10:07:22.002070 IP6 ::1.41078 > ::1.8080: Flags [P.], seq 1:175, ack 1, ... length 174: HTTP: POST /notes HTTP/1.1
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.5.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

Annotation:

- The HTTP request line is `POST /notes HTTP/1.1`.
- The request is sent to `localhost:8080`.
- The body is JSON with title `trace me` and body `in flight`.

#### HTTP response

```text
10:07:22.003042 IP6 ::1.8080 > ::1.41078: Flags [P.], seq 1:207, ack 175, ... length 206: HTTP: HTTP/1.1 201 Created
HTTP/1.1 201 Created
Content-Type: application/json
Date: Tue, 16 Jun 2026 07:07:22 GMT
Content-Length: 93

{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T07:07:22.002480556Z"}
```

Annotation:

- QuickNotes returned `HTTP/1.1 201 Created`, which means the note was created successfully.
- The response body includes the created note with `id`, `title`, `body`, and `created_at`.

#### Connection close

```text
10:07:22.003282 IP6 ::1.41078 > ::1.8080: Flags [F.], seq 175, ack 207, ... length 0
10:07:22.003353 IP6 ::1.8080 > ::1.41078: Flags [F.], seq 207, ack 176, ... length 0
10:07:22.003378 IP6 ::1.41078 > ::1.8080: Flags [.], ack 208, ... length 0
```

Annotation:

- The client starts the connection shutdown with `FIN`.
- The server replies with its own `FIN`.
- The final client ACK completes the TCP connection close.

### Five debugging commands

#### 1. What's listening?

Command:

```bash
ss -tlnp | grep :8080
```

Output:

```text
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=2898953,fd=3))
```

Decision:

QuickNotes is running and listening on TCP port `8080`. The process name is `quicknotes`, with PID `2898953`.

#### 2. Routes from the host

Command:

```bash
ip route show
```

Output:

```text
default via 10.90.120.1 dev eno1 proto dhcp src 10.90.120.190 metric 100
default via 10.91.48.1 dev wlp179s0 proto dhcp src 10.91.48.93 metric 600
10.90.120.0/22 dev eno1 proto kernel scope link src 10.90.120.190 metric 100
10.91.48.0/20 dev wlp179s0 proto kernel scope link src 10.91.48.93 metric 600
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
172.18.0.0/16 dev br-24184173a529 proto kernel scope link src 172.18.0.1 linkdown
172.19.0.0/16 dev br-92a7596f9709 proto kernel scope link src 172.19.0.1 linkdown
172.20.0.0/16 dev br-1fb3ccd5b653 proto kernel scope link src 172.20.0.1 linkdown
192.168.122.0/24 dev virbr0 proto kernel scope link src 192.168.122.1 linkdown
```

Decision:

The host has active default routes through `eno1` and `wlp179s0`. Docker and virtualization bridge networks are present but currently marked `linkdown`, so they are not relevant to the local QuickNotes request on `localhost`.

#### 3. Local reachability

Command:

```bash
mtr -rwc 5 localhost
```

Output:

```text
Start: 2026-06-16T10:17:52+0300
HOST: pc        Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.1   0.1   0.1   0.1   0.0
```

Decision:

`localhost` is reachable with `0.0%` packet loss and about `0.1 ms` latency. The loopback path is healthy.

#### 4. DNS check

Command:

```bash
dig +short example.com @1.1.1.1
```

Output:

```text
8.6.112.0
8.47.69.0
```

Decision:

DNS resolution through Cloudflare DNS (`1.1.1.1`) works because the query returned IP addresses for `example.com`.

#### 5. User service logs

Command:

```bash
journalctl --user -u quicknotes -n 20 || true
```

Output:

```text
-- No entries --
```

Decision:

There are no `systemd --user` journal entries for `quicknotes`. This is expected because QuickNotes was run manually for this task, not as a user-level systemd service.

### 502 debugging reflection

If QuickNotes returned `502 Bad Gateway`, I would first check the component in front of QuickNotes, such as a reverse proxy, load balancer, or gateway, because a 502 usually means the gateway could not get a valid response from the upstream service. I would verify that QuickNotes is actually running, confirm it is listening on the expected address and port with `ss -tlnp`, and test the upstream directly with `curl http://localhost:8080/health`. If the app is not reachable, I would inspect process logs for crashes, bind failures, or configuration errors. If the app is reachable locally, I would then check the proxy upstream address, routing, firewall rules, and DNS configuration.

## Task 2

### Broken deploy reproduction

Commands:

```bash
cd app/
ADDR=:8080 go run . &
PID1=$!
sleep 1
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &
PID2=$!
sleep 2
cat /tmp/qn-broken.log
ps -ef | grep quicknotes | grep -v grep
ps -ef | grep "go run" | grep -v grep
```

Output:

```text
[3] 2913573
2026/06/16 10:26:01 quicknotes listening on :8080 (notes loaded: 8)

[4] 2914079
2026/06/16 10:26:26 quicknotes listening on :8080 (notes loaded: 8)
2026/06/16 10:26:26 listen: listen tcp :8080: bind: address already in use
exit status 1

[4]+  Done                    ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log

2026/06/16 10:26:26 quicknotes listening on :8080 (notes loaded: 8)
2026/06/16 10:26:26 listen: listen tcp :8080: bind: address already in use
exit status 1

mostafa  2913671 2913573  0 10:26 pts/3    00:00:00 /home/mostafa/.cache/go-build/32/32655a38a659cde499c37fabd7e81ec7a161a2e7297b91b6bb17f272b23aa937-d/quicknotes
mostafa  2913573 2899005  2 10:26 pts/3    00:00:02 /snap/go/11200/bin/go run .
```

Decision:

The broken deploy was reproduced successfully. The first QuickNotes instance started on port `8080`. The second instance attempted to bind to the same port and failed with `listen tcp :8080: bind: address already in use`.

### Outside-in debugging chain

#### 1. Is the process running?

Commands:

```bash
ps -ef | grep quicknotes | grep -v grep
ps -ef | grep "go run" | grep -v grep
```

Output:

```text
mostafa  2913671 2913573  0 10:26 pts/3    00:00:00 /home/mostafa/.cache/go-build/32/32655a38a659cde499c37fabd7e81ec7a161a2e7297b91b6bb17f272b23aa937-d/quicknotes
mostafa  2913573 2899005  2 10:26 pts/3    00:00:02 /snap/go/11200/bin/go run .
```

Decision:

One QuickNotes process is still running. The failed second startup exited, but the first `go run .` wrapper and its compiled `quicknotes` child process remain active.

#### 2. Is it listening?

Command:

```bash
ss -tlnp | grep 8080
```

Output:

```text
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=2913671,fd=3))
```

Decision:

Port `8080` is already owned by the running `quicknotes` process. This confirms that the second process failed because the address was already in use.

#### 3. Is it reachable from the host?

Commands:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
curl -s http://localhost:8080/health
```

Output:

```text
200
{"notes":8,"status":"ok"}
```

Decision:

The active QuickNotes instance is reachable from the host and returns a healthy response. The issue is not local reachability to the already-running service.

#### 4. Is a firewall blocking it?

Command:

```bash
sudo iptables -L -n -v 2>/dev/null || sudo nft list ruleset 2>/dev/null || true
```

Output excerpt:

```text
Chain INPUT (policy ACCEPT 39M packets, 61G bytes)
 pkts bytes target     prot opt in     out     source               destination
  39M   61G LIBVIRT_INP  0    --  *      *       0.0.0.0/0            0.0.0.0/0

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
  14M   14G DOCKER-USER  0    --  *      *       0.0.0.0/0            0.0.0.0/0
  14M   14G DOCKER-FORWARD  0    --  *      *       0.0.0.0/0            0.0.0.0/0
    0     0 LIBVIRT_FWX  0    --  *      *       0.0.0.0/0            0.0.0.0/0
    0     0 LIBVIRT_FWI  0    --  *      *       0.0.0.0/0            0.0.0.0/0
    0     0 LIBVIRT_FWO  0    --  *      *       0.0.0.0/0            0.0.0.0/0

Chain OUTPUT (policy ACCEPT 28M packets, 23G bytes)
 pkts bytes target     prot opt in     out     source               destination
  28M   23G LIBVIRT_OUT  0    --  *      *       0.0.0.0/0            0.0.0.0/0

Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
  14M   14G RETURN     0    --  *      *       0.0.0.0/0            0.0.0.0/0
```

Decision:

The firewall output shows default `ACCEPT` policies for `INPUT` and `OUTPUT`, and the localhost health check already succeeded. A firewall block is not the cause of this failure.

#### 5. Does DNS resolve localhost?

Command:

```bash
dig +short localhost
```

Output:

```text
127.0.0.1
```

Decision:

`localhost` resolves to `127.0.0.1`, so local name resolution is working. DNS is not the cause of the failed startup.

### Repair and re-verify

Commands:

```bash
ss -tlnp | grep 8080
kill 2913671
sleep 1
ss -tlnp | grep 8080 || echo "nothing listening on 8080"
ADDR=:8080 go run . &
PID1=$!
sleep 1
ss -tlnp | grep 8080
curl -s http://localhost:8080/health
```

Output:

```text
LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=2913671,fd=3))
2026/06/16 10:33:18 shutting down
nothing listening on 8080

[3] 2918953
2026/06/16 10:33:31 quicknotes listening on :8080 (notes loaded: 8)

LISTEN 0      4096               *:8080             *:*    users:(("quicknotes",pid=2919053,fd=3))
{"notes":8,"status":"ok"}
```

Decision:

The conflicting listener was stopped, port `8080` was confirmed free, QuickNotes restarted cleanly, and `/health` returned a valid response.

### Root cause

The second QuickNotes instance failed because another QuickNotes process was already listening on TCP port `8080`. The exact root-cause error was:

```text
listen: listen tcp :8080: bind: address already in use
```

### Mini-postmortem

The broken deploy was caused by two QuickNotes instances trying to bind to the same TCP port, `:8080`. This is a systemic deployment risk because process startup can fail when port ownership is not coordinated, old processes are left running, or service managers do not enforce a single active instance. The application code was not the root problem; the runtime environment already had the required port occupied.

This kind of failure can be prevented with service supervision and deployment checks. A `systemd` unit can manage one authoritative process, stop old instances cleanly, restart failed services, and expose logs through `journalctl`. Pre-flight checks such as `ss -tlnp | grep 8080` can detect port conflicts before rollout. Health checks can confirm that the intended instance is serving traffic after restart.
