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
