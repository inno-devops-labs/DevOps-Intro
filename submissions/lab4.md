# Lab 4 submission

Environment: WSL2 (Ubuntu 24.04). QuickNotes was cross-compiled for `linux/amd64` and run inside WSL so the loopback traffic is visible to `tcpdump -i lo`.

## Task 1: Trace a request end-to-end

### 1.1 Capture

```bash
# terminal A: run the server (cross-compiled linux binary)
./quicknotes                       # listening on :8080, 4 seeded notes

# terminal B: capture loopback traffic on port 8080
sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap

# terminal C: fire exactly one request
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

`curl` resolved `localhost` to `::1` first, so the whole exchange runs over the **IPv6 loopback** (`::1`).

### 1.2 Decode (annotated)

Full decode: [lab4-trace.txt](attachments/lab4/lab4-trace.txt). The four phases the lab asks for:

**1. TCP three-way handshake** (`SYN` -> `SYN/ACK` -> `ACK`):

```
::1.53968 > ::1.8080: Flags [S],  seq 3820193617          # SYN
::1.8080 > ::1.53968: Flags [S.], seq 1109512878, ack 1   # SYN/ACK
::1.53968 > ::1.8080: Flags [.],  ack 1                    # ACK  -> connection established
```

**2. HTTP request line + JSON body** (`PSH` carrying 174 bytes):

```
::1.53968 > ::1.8080: Flags [P.], seq 1:175 ... HTTP: POST /notes HTTP/1.1
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.5.0
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

**3. HTTP response line + response JSON** (`201 Created`, 206 bytes):

```
::1.8080 > ::1.53968: Flags [P.], seq 1:207 ... HTTP: HTTP/1.1 201 Created
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 93

{"id":5,"title":"trace me","body":"in flight","created_at":"2026-06-16T20:49:40.615872267Z"}
```

**4. Connection close** (graceful `FIN` from both ends):

```
::1.53968 > ::1.8080: Flags [F.], seq 175   # client FIN
::1.8080 > ::1.53968: Flags [F.], seq 207   # server FIN
::1.53968 > ::1.8080: Flags [.],  ack 208   # final ACK -> closed
```

### 1.3 Five debugging commands

**1. What is listening?** `sudo ss -tlnp | grep :8080`

```
LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=471,fd=3))
```

`quicknotes` owns the listening socket on port 8080 (`sudo` needed to see the PID/process name).

**2. Routes from the host.** `ip route show`

```
default via 172.21.48.1 dev eth0 proto kernel
172.21.48.0/20 dev eth0 proto kernel scope link src 172.21.57.201
```

Default route goes out the WSL NAT gateway on `eth0`; our `localhost` request never touches it - it stays on `lo`.

**3. Reachability.** `mtr -rwc 5 localhost`

```
HOST: danielpancakePC   Loss%  Snt  Last  Avg  Best  Wrst StDev
  1.|-- localhost        0.0%    5   0.1   0.1   0.1   0.1   0.0
```

One hop, 0% loss, ~0.1 ms - the loopback path is healthy.

**4. DNS works.** `dig +short example.com @1.1.1.1`

```
172.66.147.243
104.20.23.154
```

The external resolver answers, so DNS egress is fine.

**5. Service logs.** `journalctl --user -u quicknotes -n 20`

```
-- No entries --
```

QuickNotes runs as a foreground process, not a systemd unit, so journald has nothing for it. Its log line goes to stdout instead: `quicknotes listening on :8080 (notes loaded: 4)`.

### 1.4 What I would check first if QuickNotes returned 502

A 502 comes from a gateway/proxy in front of the app that could not get a valid response from the upstream, so I debug the proxy-to-app boundary outside-in. First I confirm the app is actually up and bound to the expected port (`ss -tlnp | grep :8080`), then I hit it directly, bypassing the proxy (`curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/health`). If the direct call is `200`, the app is healthy and the fault is the proxy's upstream config - wrong port or host, or the app bound to `127.0.0.1` while the proxy dials a different address. If the direct call also fails, the app crashed or never bound, so I check its logs/exit status and whether something else already holds the port. The order is always: is it running, is it listening, is it reachable from where the proxy sits, and is the proxy pointed at the right upstream.
