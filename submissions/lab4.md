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
