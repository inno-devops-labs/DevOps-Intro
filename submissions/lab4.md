# Lab 4 submission

Environment: WSL2 (Ubuntu 24.04). QuickNotes was cross-compiled for `linux/amd64` and run inside WSL so the loopback traffic is visible to `tcpdump -i lo`.

## Task 1: Trace a request end-to-end

### 1.1 Capture

```bash
# terminal A: run the server
./quicknotes

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

## Task 2: Outside-in debugging on a broken deploy

Reproduced with the same `~/lab4/quicknotes` linux binary, started twice on the same port to simulate a failed deploy.

### 2.1 Run a broken instance

```bash
ADDR=:8080 ./quicknotes > qn1.log 2>&1 &              # instance 1 - binds :8080
sleep 1
ADDR=:8080 ./quicknotes > /tmp/qn-broken.log 2>&1 &   # instance 2 - the "new deploy"
sleep 2
ps -ef | grep quicknotes | grep -v grep
```

Instance 1 (pid 487) stays up; instance 2 logs its error and exits immediately:

```
2026/06/17 01:53:55 quicknotes listening on :8080 (notes loaded: 5)
2026/06/17 01:53:55 listen: listen tcp :8080: bind: address already in use
```

Exact error: `bind: address already in use`. The new deploy never came up.

### 2.2 Outside-in chain

| Step | Command | Output | Decision |
| --- | --- | --- | --- |
| 1. Running? | `ps -ef \| grep quicknotes` | `... 487 ... ./quicknotes` (one PID) | A process IS running - but which instance? |
| 2. Listening? | `sudo ss -tlnp \| grep 8080` | `LISTEN *:8080 users:(("quicknotes",pid=487))` | Port 8080 is held by pid 487 (the first instance) |
| 3. Reachable? | `curl -s -o /dev/null -w "%{http_code}" .../health` | `200` | The socket answers, so L3/L4/L7 are fine |
| 4. Firewall? | `iptables -L` / `nft list ruleset` | neither installed, no rules | No packet filter in the path - not a firewall issue |
| 5. DNS? | `dig +short localhost` | `127.0.0.1` (`getent`: `::1 localhost`) | Name resolution works |

Every outside-in check is green, yet the deploy failed - that is the tell. The fault is not in the network path: a process is already bound to 8080, so the new instance could never start. Cross-referencing `ss` (pid **487** = the first instance) against the broken log (`address already in use`) pins it.

### 2.3 Repair + re-verify

```bash
kill 487                      # free the port by killing the conflicting first instance
sleep 1
ADDR=:8080 ./quicknotes &     # start the intended instance
curl -s http://localhost:8080/health
```

```
ss:   LISTEN *:8080 users:(("quicknotes",pid=526))   # new pid now owns the port
curl: {"notes":5,"status":"ok"}                      # HTTP 200
```

Port freed, new instance bound, health green.

### Root cause

`listen tcp :8080: bind: address already in use` - a previous QuickNotes process still held port 8080, so the second `ListenAndServe` could not bind and `log.Fatalf` terminated the process.

### Mini-postmortem (blameless)

What is systemic here is not that someone "forgot to stop the old process" - it is that nothing in the path made the conflict visible or prevented it. A second instance was allowed to launch against an already-bound port, and its only signal was a single fatal line that scrolled past in a backgrounded process. From the outside everything looked healthy (a process was running, the port returned 200), which is exactly how a stale instance masquerades as a good deploy. The deeper gap is the missing supervisor: run under systemd or any process manager and the unit owns the port, a restart stops the old instance before starting the new one, and a failed start surfaces in `systemctl status` / `journalctl` instead of a lost stdout line. Tooling that prevents this class of failure: a real init/supervisor with restart-on-failure, a deploy health gate that confirms the *new* process answered (not just any process), and an `ss`/`lsof` preflight that fails fast on a busy port.
