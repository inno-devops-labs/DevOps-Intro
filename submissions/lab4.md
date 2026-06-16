# Lab 4 — OS & Networking
## Task 1 — Trace one request end to end

### Capture

QuickNotes was running (`go run .` in `app/`). I captured loopback traffic on port 8080 with
tcpdump, fired a single `POST /notes`, then stopped the capture and decoded it:

```bash
sudo tcpdump -i lo0 -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap &
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
# stop tcpdump, then:
tcpdump -r lab4-trace.pcap -nn -A > lab4-trace.txt
```

Full decoded capture: [lab4-trace.txt](lab4-trace.txt) (raw pcap: [lab4-trace.pcap](lab4-trace.pcap)).

### What's in the capture

**1. TCP three-way handshake** — connection set up before any HTTP:

```
::1.54597 > ::1.8080: Flags [S],  seq 2147487999            # SYN     (client -> server)
::1.8080 > ::1.54597: Flags [S.], seq 3048454762, ack ...   # SYN-ACK (server -> client)
::1.54597 > ::1.8080: Flags [.],  ack 1                     # ACK     (handshake done)
```

**2. HTTP request** — `POST /notes` plus the JSON body (one push, 174 bytes):

```
::1.54597 > ::1.8080: Flags [P.], length 174: HTTP: POST /notes HTTP/1.1
    POST /notes HTTP/1.1
    Host: localhost:8080
    User-Agent: curl/8.7.1
    Content-Type: application/json
    Content-Length: 39

    {"title":"trace me","body":"in flight"}
```

**3. HTTP response** — `201 Created` with the new note (id 6):

```
::1.8080 > ::1.54597: Flags [P.], length 203: HTTP: HTTP/1.1 201 Created
    HTTP/1.1 201 Created
    Content-Type: application/json
    Content-Length: 90

    {"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T15:16:57.540103Z"}
```

**4. Connection close** — a clean four-way FIN, both sides:

```
::1.54597 > ::1.8080: Flags [F.]    # client says it's done
::1.8080 > ::1.54597: Flags [.]     # server ACKs
::1.8080 > ::1.54597: Flags [F.]    # server says it's done
::1.54597 > ::1.8080: Flags [.]     # client ACKs -> closed
```

So the whole thing is: open the connection, send the request, get the response, close cleanly.
The full exchange took about 3.5 ms on loopback.

### The five debugging commands

**1. What's listening on 8080?**

```
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
COMMAND     PID     USER   FD   TYPE  NODE NAME
quicknote 29861 avlaptev    5u  IPv6   TCP *:8080 (LISTEN)
```
One process owns the port, bound on all interfaces (`*:8080`), IPv6 socket.

**2. Routes from the host**

```
$ netstat -rn -f inet | head
default            10.246.1.1         UGScg   en9
default            10.91.48.1         UGScIg  en0
...
```
Two default routes (this machine is on a corporate VPN — `utun6`, `en9`, `en0`). For loopback
traffic none of this matters; it never leaves the host.

**3. Reachability to localhost**

```
$ ping -c 5 localhost
PING localhost (127.0.0.1): 56 data bytes
Request timeout for icmp_seq 0
...
5 packets transmitted, 0 packets received, 100.0% packet loss

$ traceroute -n -m 3 localhost
 1  127.0.0.1  0.594 ms
```
Interesting real finding: **ICMP to loopback is being dropped** (almost certainly a corporate
endpoint-security agent), so `ping` shows 100% loss — but the host is obviously reachable:
`traceroute` gets a reply in 0.6 ms and every `curl` to `:8080` works. Lesson: ping failing
doesn't mean the service is down; ICMP and TCP are different paths.

**4. DNS works?**

```
$ dig +short example.com @1.1.1.1
8.47.69.0
8.6.112.0
```
DNS resolves (returns answers). The addresses look like the corporate network rewrites/intercepts
public DNS, but resolution itself is working.

**5. Logs** (no systemd/journalctl on macOS — QuickNotes runs in the foreground):

```
2026/06/16 18:10:12 quicknotes listening on :8080 (notes loaded: 5)
```

### If QuickNotes returned 502, what would I check first?

A 502 doesn't come from QuickNotes itself — the app returns its own codes (200/201/404). A 502
means something *in front* of it (a reverse proxy / load balancer) tried to reach the backend and
got nothing usable. So I'd start at that boundary: is QuickNotes actually up and listening
(`lsof -iTCP:8080`)? Can the proxy reach it from where the proxy runs (`curl` to the backend
host:port from the proxy box)? Is the proxy's upstream address/port correct, and is the backend
answering before the proxy's timeout? Then I'd read both the proxy log and the app log. In short:
502 = "proxy ↔ backend" problem, so I verify the backend is listening and reachable from the
proxy before touching anything else.

---

## Task 2 — Outside-in debugging on a broken deploy

### Reproducing the break

QuickNotes was already on `:8080`. Starting a second instance on the same port fails:

```
$ ADDR=:8080 go run .
2026/06/16 18:11:20 listen: listen tcp :8080: bind: address already in use
exit status 1
```

That's the bug: **`bind: address already in use`**.

### Walking the chain (outside-in)

**1. Is it running?**
```
$ ps aux | grep -E 'exe/quicknotes|go run' | grep -v grep
29861  .../exe/quicknotes
```
One instance alive; the second exited with status 1. The server itself is fine — so this isn't a
"process died" problem.

**2. Is it listening?**
```
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
quicknote 29861 avlaptev  5u IPv6  TCP *:8080 (LISTEN)
```
One PID already owns `*:8080`. That's exactly why a second `bind()` can't succeed.

**3. Reachable from the host?**
```
$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/health
200
```
The surviving instance serves traffic. So the problem isn't reachability.

**4. Firewall?** (Linux: `iptables`/`nft`; macOS: `pfctl`, needs sudo)
Skipped — curl already returned 200 over loopback, so the firewall isn't blocking anything here.

**5. DNS?**
```
$ dig +short localhost
127.0.0.1
```
`localhost` resolves fine. Not DNS.

### Root cause + fix

Root cause: **a port conflict** — two processes both tried to bind `:8080`; the OS let the first
one win and rejected the second with `EADDRINUSE`. Fix is to free the port and start one clean
instance:

```
$ lsof -ti tcp:8080 | xargs kill
$ lsof -nP -iTCP:8080 -sTCP:LISTEN   # empty -> port free
$ ADDR=:8080 go run . &
$ curl -s http://localhost:8080/health
{"notes":5,"status":"ok"}
```

### Mini-postmortem (blameless)

Nobody "made a mistake" here — the OS did the right thing by refusing the second bind. The failure
is systemic: there was no single owner for the port and no guardrail to stop two copies from
starting. This is a whole class of incident (port/resource contention), and it shows up whenever
processes are started by hand without supervision. What actually prevents it isn't "be more
careful," it's tooling: a process supervisor (launchd/systemd) that guarantees one instance,
containers where each service gets its own network namespace so host ports can't clash, or a tiny
preflight check (`lsof -i :PORT`) before starting. The lesson is to make "one owner per port" a
property the platform enforces, instead of something a human has to remember. The error message
itself was good — it named the exact problem — which is the other half: failures should be loud
and specific, and this one was.

---

## Bonus — Decode the TLS handshake

QuickNotes is HTTP-only, so I put a TLS-terminating reverse proxy in front of it. I didn't use
Caddy (not installed); instead I wrote a tiny Go proxy (Go is already here) with a self-signed
cert, listening HTTPS on `:8443` and forwarding to `:8080`:

```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 7 -nodes \
  -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"
# tiny Go proxy: http.ListenAndServeTLS(":8443", cert, key, httputil.NewSingleHostReverseProxy(:8080))
```

Then I captured the handshake on `:8443` and decoded it with tshark (Wireshark's CLI):

```bash
sudo tcpdump -i lo0 -nn -s 0 'tcp port 8443' -w lab4-tls.pcap &
curl -vk https://localhost:8443/health
```

Raw capture: [lab4-tls.pcap](lab4-tls.pcap).

### ClientHello (curl → proxy)

```
Handshake Type: Client Hello
  Server Name Indication: localhost          # SNI
  legacy_version: TLS 1.2 (0x0303)           # frozen/ignored per RFC 8446
  Extension supported_versions: TLS 1.3, TLS 1.2, TLS 1.1, TLS 1.0
  Cipher suites offered (50+): TLS_CHACHA20_POLY1305_SHA256, TLS_AES_256_GCM_SHA384,
    TLS_AES_128_GCM_SHA256, ECDHE/DHE AES-GCM and CBC suites, ... down to legacy
    TLS_RSA_WITH_RC4_128_SHA and TLS_RSA_WITH_3DES_EDE_CBC_SHA
```

The client (curl/LibreSSL) is generous — it advertises everything from TLS 1.3 all the way down to
1.0, and even RC4/3DES, in case the server is old.

### ServerHello (proxy → curl)

```
Handshake Type: Server Hello
  legacy_version: TLS 1.2 (0x0303)           # again, ignored
  Extension supported_versions: TLS 1.3      # the real chosen version
  Cipher Suite: TLS_CHACHA20_POLY1305_SHA256 (0x1303)
```

`curl -vk` agrees: `SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256`, ALPN negotiated
`h2`.

### Certificate chain

```
$ openssl s_client -connect localhost:8443 -showcerts
 0 s:/CN=localhost
   i:/CN=localhost
Protocol  : TLSv1.3
Cipher    : AEAD-CHACHA20-POLY1305-SHA256
Verify return code: 18 (self signed certificate)
```

One cert, subject == issuer == `CN=localhost`, so it's self-signed (verify code 18). That's why
curl needs `-k` — there's no CA to trust it.

### Which step kills TLS 1.0 / 1.1 in 2026?

It's the **`supported_versions` extension** (RFC 8446). The old `legacy_version` field in both
ClientHello and ServerHello is pinned at `0x0303` (TLS 1.2) and explicitly ignored — version is
negotiated in the extension instead. In my capture the client offered 1.0–1.3 there, and the
server answered with `supported_versions: TLS 1.3`. The Go server is built with `MinVersion =
TLS 1.2`, so it will simply never select 1.0 or 1.1. I confirmed this directly — a client that
offers *only* the old versions gets refused:

```
$ for v in tls1 tls1_1 tls1_2 tls1_3; do echo | openssl s_client -connect localhost:8443 -$v; done
tls1     -> refused (handshake failed)
tls1_1   -> refused (handshake failed)
tls1_2   -> ACCEPTED
tls1_3   -> ACCEPTED
```

So 1.0/1.1 die at version negotiation: the server picks the highest version it allows from
`supported_versions`, and since its floor is 1.2, anything below that ends in `handshake_failure`.
## Files

- [lab4-trace.txt](lab4-trace.txt) — decoded HTTP capture (Task 1)
- [lab4-trace.pcap](lab4-trace.pcap) — raw HTTP capture
- [lab4-tls.pcap](lab4-tls.pcap) — raw TLS capture (Bonus)
