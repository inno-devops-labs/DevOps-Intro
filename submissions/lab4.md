# Lab 4 — Network Troubleshooting and Broken Deploy

## Environment

- OS: macOS
- Application: QuickNotes
- Application port: `8080`
- Loopback interface: `lo0`
- Packet capture tool: `tcpdump`
- Network diagnostic tools: `ss`, `ip`, `mtr`, `dig`, `lsof`, `pfctl`

> Some commands in the lab are Linux-specific. On macOS, equivalent tools were used where necessary. In particular, `journalctl` is unavailable because macOS does not use systemd.

---

# Task 1 — Observe and Explain the Network Path

## 1. Packet capture

QuickNotes was started on port `8080`, and traffic was captured on the macOS loopback interface.

The resulting capture file was:

```text
lab4-trace.pcap
```

File information:

```text
-rw-r--r--@ 1 root staff 1.5K lab4-trace.pcap

lab4-trace.pcap: pcap capture file, microsecond ts (little-endian)
```

The capture was decoded with:

```bash
sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt
```

The capture used the BSD loopback link type:

```text
reading from file lab4-trace.pcap, link-type NULL (BSD loopback)
```

The request used IPv6 loopback address `::1`.

The TCP connection was:

```text
client ::1:55131 → server ::1:8080
```

Port `55131` was an ephemeral client port automatically selected by the operating system.

Port `8080` was the listening port of QuickNotes.

---

## 2. TCP three-way handshake

The beginning of the packet capture contained:

```text
::1.55131 > ::1.8080  Flags [S]
::1.8080 > ::1.55131 Flags [S.]
::1.55131 > ::1.8080 Flags [.]
```

This corresponds to the standard TCP three-way handshake:

```text
Client :55131                         QuickNotes :8080

     SYN
      -------------------------------->

                         SYN + ACK
      <--------------------------------

     ACK
      -------------------------------->

           TCP connection established
```

Flag meanings:

- `[S]` — SYN
- `[S.]` — SYN + ACK
- `[.]` — ACK

This occurs at Layer 4, the transport layer.

---

## 3. HTTP request

After the TCP connection was established, the client sent:

```text
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.7.1
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

The TCP segment containing the request had:

```text
Flags [P.]
```

`[P.]` represents PSH + ACK.

At this point the packet contains Layer 7 application data.

The protocol stack can therefore be represented as:

```text
Layer 7 — Application
HTTP POST /notes
JSON request body

        ↓

Layer 4 — Transport
TCP
55131 → 8080

        ↓

Layer 3 — Network
IPv6
::1 → ::1

        ↓

Loopback interface
lo0
```

Because the destination was localhost, the packet never needed to leave the host through Wi-Fi or Ethernet.

---

## 4. HTTP response

QuickNotes returned:

```text
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 90
```

Response body:

```json
{
  "id": 6,
  "title": "trace me",
  "body": "in flight",
  "created_at": "2026-10-06T17:43:47.900355Z"
}
```

`201 Created` confirms that the new note was successfully created.

The request-response path was:

```text
curl
  |
  | POST /notes
  v
QuickNotes
  |
  | create note
  v
HTTP/1.1 201 Created
```

---

## 5. TCP connection termination

The capture ended with:

```text
client → server  Flags [F.]
server → client  ACK
server → client  Flags [F.]
client → server  ACK
```

This represents an orderly TCP connection shutdown:

```text
Client                              Server

     FIN + ACK
      -------------------------------->

                         ACK
      <--------------------------------

                         FIN + ACK
      <--------------------------------

     ACK
      -------------------------------->

              Connection closed
```

The connection therefore terminated normally rather than being reset.

---

# Task 1 — Diagnostic Commands

## Listening socket

Command:

```bash
ss -tlnp | grep :8080
```

Output:

```text
tcp46 LISTEN 0 0 *:8080 *:*
```

Decision:

A TCP listener was present on port `8080`.

On macOS, `lsof` was also used to identify the owning process:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

This allowed the actual QuickNotes PID owning the socket to be identified.

---

## Routing

Command:

```bash
ip route show
```

Relevant output:

```text
127.0.0.0/8 via 127.0.0.1 dev lo0
127.0.0.1/32 via 127.0.0.1 dev lo0
```

The native macOS routing table also showed the IPv6 loopback route:

```text
::1 → lo0
```

Decision:

Localhost traffic is routed through the `lo0` loopback interface rather than through a physical network interface.

The packet capture used IPv6 `::1`, so the IPv6 loopback route was used for the captured HTTP request.

---

## Path diagnostics with mtr

Running `mtr` without elevated privileges failed:

```text
mtr-packet: Failure to open IPv4 sockets
mtr-packet: Failure to open IPv6 sockets
mtr: Failure to start mtr-packet: Invalid argument
```

Running it with elevated privileges succeeded:

```bash
sudo /opt/homebrew/sbin/mtr -rwc 5 localhost
```

Output:

```text
HOST: MacBook-Pro-Alisa.local Loss% Snt Last Avg Best Wrst StDev
 1.|-- localhost               0.0%   5  0.2 0.2 0.1 0.2 0.0
```

Decision:

Localhost is reachable in one hop with `0.0%` packet loss.

The initial failure was caused by insufficient privileges for the low-level sockets required by `mtr`, not by a networking failure.

---

## DNS diagnostic

Command:

```bash
dig +short example.com @1.1.1.1
```

Output:

```text
104.20.23.154
172.66.147.243
```

Decision:

External DNS resolution through Cloudflare resolver `1.1.1.1` works correctly.

---

## Logs

The lab suggests:

```bash
journalctl --user -u quicknotes -n 20
```

However, `journalctl` is not available on this system:

```bash
command -v journalctl
```

returned no path.

Decision:

This is expected on macOS because `journalctl` is a systemd journal client and macOS does not use systemd.

QuickNotes was launched interactively using `go run .`, therefore its application logs were observed directly in the terminal and redirected to files when required.

---

## 502 Bad Gateway troubleshooting

If QuickNotes were returning `502 Bad Gateway`, I would first verify the connection between the reverse proxy or gateway and the QuickNotes upstream service.

I would check whether QuickNotes is actually running and listening on the expected address and port using `ss` or `lsof`, then call its `/health` endpoint directly with `curl`, bypassing the proxy.

If the application itself were healthy, I would continue outward by checking proxy configuration, upstream DNS resolution, routing, firewall rules, and the logs of both the proxy and QuickNotes.

A `502` normally indicates that the client successfully reached a gateway or proxy but that gateway could not obtain a valid response from its upstream service. Therefore, direct reachability of the upstream application is the first useful check.

---

# Task 2 — Broken Deploy

## 2.1 Reproduce the failure

A working QuickNotes instance was started on port `8080`.

Its log contained:

```text
quicknotes listening on :8080 (notes loaded: 6)
```

The listener was verified with:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

Output:

```text
COMMAND     PID   USER            FD TYPE  NAME
quicknote 35917 alisaevdosenko    5u IPv6  TCP *:8080 (LISTEN)
```

Its health endpoint was checked:

```bash
curl --max-time 3 -sS -o /dev/null \
  -w "HTTP %{http_code}\n" \
  http://localhost:8080/health
```

Output:

```text
HTTP 200
```

A second QuickNotes instance was then started on the same address:

```bash
ADDR=:8080 go run .
```

It failed with:

```text
quicknotes listening on :8080 (notes loaded: 6)
listen: listen tcp :8080: bind: address already in use
exit status 1
```

The exact error was saved to:

```text
/tmp/qn-broken.log
```

The failure occurred because two processes cannot simultaneously own the same listening address and TCP port under the same socket configuration.

Conceptually:

```text
QuickNotes #1
    |
    +---- bind(:8080) ---- success
                  |
                  v
               LISTEN

QuickNotes #2
    |
    +---- bind(:8080)
                  |
                  v
              EADDRINUSE
                  |
                  v
      "address already in use"
```

---

# 2.2 Outside-in troubleshooting

## Step 1 — Process

Command:

```bash
ps -ef | grep '[q]uicknote'
```

Output showed one running QuickNotes process:

```text
/Users/alisaevdosenko/Library/Caches/go-build/.../quicknotes
```

Decision:

The original QuickNotes process was still running.

The second QuickNotes process was absent because it had terminated immediately after the bind failure.

---

## Step 2 — Listening socket

Command:

```bash
ss -tlnp | grep 8080
```

Output:

```text
tcp46 LISTEN 0 0 *:8080 *:*
```

Command:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

Output identified QuickNotes PID `35917` as the owner of the socket.

Decision:

Port `8080` was already bound by the first QuickNotes instance.

This directly explains why the new instance could not bind to the same port.

---

## Step 3 — Host reachability

Command:

```bash
curl --max-time 3 -sS -o /dev/null \
  -w "%{http_code}\n" \
  http://localhost:8080/health
```

Output:

```text
200
```

Decision:

Port `8080` was reachable and the existing application instance was healthy.

An important observation is that a successful health check did **not** prove that the new deployment succeeded.

The response was produced by the old instance:

```text
QuickNotes #1 → healthy
QuickNotes #2 → failed deployment
```

Therefore, checking only a shared service endpoint can hide the failure of a replacement instance.

---

## Step 4 — Firewall

Native macOS packet-filter rules were inspected with:

```bash
sudo pfctl -sr
```

Output:

```text
scrub-anchor "com.apple/*" all fragment reassemble
scrub-anchor "com.apple.internet-sharing" all fragment reassemble
anchor "com.apple/*" all
anchor "com.apple.internet-sharing" all
```

The macOS Application Firewall state was checked with:

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

Output:

```text
Firewall is disabled. (State = 0)
```

Decision:

The firewall was not responsible for the failure.

This conclusion was also supported by the successful HTTP request to `localhost:8080`.

---

## Step 5 — Name resolution

Command:

```bash
dig +short localhost
```

returned no DNS result.

This did not mean that localhost resolution was broken. `localhost` is resolved locally on macOS rather than through normal public DNS.

Native macOS resolution was checked with:

```bash
dscacheutil -q host -a name localhost
```

Output:

```text
name: localhost
ipv6_address: ::1

name: localhost
ip_address: 127.0.0.1
```

`/etc/hosts` contained:

```text
127.0.0.1 localhost
::1       localhost
```

Decision:

Localhost name resolution works correctly for both IPv4 and IPv6.

DNS/name resolution was unrelated to the deployment failure.

---

# Root Cause

The second QuickNotes deployment attempted to bind TCP port `8080` while the previous QuickNotes process still owned that listening socket.

The operating system therefore rejected the second `bind()` operation with an address-in-use error.

```text
First instance
      |
      v
*:8080 LISTEN
      |
      +---------------------+
                            |
Second instance             |
      |                     |
      v                     |
bind(*:8080)                |
      |                     |
      +---- port occupied --+
      |
      v
EADDRINUSE
      |
      v
process exits
```

The failure was not caused by routing, DNS, firewall rules, or host connectivity.

---

# 2.3 Repair and Re-verify

The process owning port `8080` was identified:

```text
Listener PID: 35917
```

It was stopped:

```bash
kill "$LISTENER_PID"
```

Afterward, the port was checked with:

```bash
ss -tlnp | grep :8080
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

Both returned no listener, confirming that port `8080` had been released.

A fresh QuickNotes instance was then started:

```bash
ADDR=:8080 go run . > /tmp/qn-fixed.log 2>&1 &
```

Startup log:

```text
2026/10/11 20:38:18 quicknotes listening on :8080 (notes loaded: 6)
```

The new listener was:

```text
COMMAND     PID   USER            FD TYPE  NAME
quicknote 36101 alisaevdosenko    5u IPv6  TCP *:8080 (LISTEN)
```

The health endpoint was then re-verified:

```bash
curl -sS http://localhost:8080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

The repair was therefore successful.

---

# Note about `go run` PIDs

When QuickNotes was launched using:

```bash
go run .
```

the shell job PID and the PID owning the TCP socket were different.

For example:

```text
FIX_PID=36095
```

while `lsof` showed:

```text
quicknote PID 36101 → TCP *:8080
```

This occurs because `go run` builds the program and starts a compiled child binary.

For socket troubleshooting, the process reported by `lsof` is therefore more relevant than relying only on the shell job PID.

---

# Mini-postmortem

## Impact

A new QuickNotes instance could not start because TCP port `8080` was already occupied. The existing instance continued to answer requests, so the service itself remained reachable, but the replacement deployment failed.

## Detection

The failure was detected immediately from the application startup log:

```text
listen tcp :8080: bind: address already in use
```

`ss` and `lsof` confirmed that another QuickNotes process already owned port `8080`.

## Root cause

The previous QuickNotes instance was still running when another instance attempted to bind to the same address and port.

## Resolution

The process owning port `8080` was identified using `lsof` and terminated. After verifying that the port was free, QuickNotes was started again and `/health` returned a successful response.

## Prevention

A deployment procedure should stop or replace the previous instance in a controlled manner before starting a new process on the same fixed port. Automated deployment scripts should verify port ownership and process health, and should fail clearly when an unexpected listener already exists. A service manager or an orchestration mechanism would also make process lifecycle management more reliable and reduce the chance of orphaned application instances.