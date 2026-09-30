# Lab 4 — OS & Networking

## Task 1 — OS & Networking Basics

### 1.1 QuickNotes and localhost traffic

QuickNotes was started locally on port `8080`.

The application reported:

```text
quicknotes listening on :8080 (notes loaded: 5)
```

A TCP capture was performed on the macOS loopback interface `lo0`:

```bash
sudo tcpdump -i lo0 -nn -s 0 -w lab4-trace.pcap 'tcp port 8080'
```

A POST request was sent to the application:

```bash
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

The request successfully returned:

```text
HTTP/1.1 201 Created
```

with the created note:

```json
{"id":6,"title":"trace me","body":"in flight","created_at":"2026-09-17T20:31:37.976126Z"}
```

The capture contained 12 packets.

The observed sequence was:

1. TCP SYN
2. TCP SYN/ACK
3. TCP ACK
4. Additional ACK
5. HTTP POST request
6. ACK
7. HTTP 201 response
8. ACK
9. Client FIN
10. Server ACK
11. Server FIN
12. Final ACK

The traffic used IPv6 loopback address `::1` and the macOS `lo0` interface.

The decoded HTTP request contained:

```text
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.7.1
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

The response contained:

```text
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 90

{"id":6,"title":"trace me","body":"in flight","created_at":"2026-09-17T20:31:37.976126Z"}
```

This demonstrates the path from the application layer (HTTP) to TCP and the IPv6 loopback interface.

---

### 1.2 Network inspection

The listening process was inspected with:

```bash
sudo lsof -nP -iTCP:8080 -sTCP:LISTEN
```

The result showed:

```text
COMMAND     PID USER   FD   TYPE   NAME
quicknote 39809 alsu    5u  IPv6   TCP *:8080 (LISTEN)
```

The routing table was inspected with:

```bash
netstat -rn
```

Relevant entries included:

```text
127                127.0.0.1          UCS                   lo0
127.0.0.1          127.0.0.1          UH                    lo0
192.168.0          link#11            UCS                   en0
```

For IPv6:

```text
::1                                     ::1                                     UHL                   lo0
```

This shows that localhost traffic is routed through `lo0`, while the normal local network uses `en0`.

The requested `mtr` command was not available on this macOS system:

```text
zsh: command not found: mtr
```

As a fallback, connectivity was tested with:

```bash
ping -c 5 localhost
```

Result:

```text
5 packets transmitted, 5 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 0.883/1.377/1.842/0.330 ms
```

DNS was checked with:

```bash
dig +short example.com @1.1.1.1
```

Result:

```text
172.66.147.243
104.20.23.154
```

`journalctl` was also checked:

```bash
command -v journalctl || echo "journalctl is not available on macOS"
```

Result:

```text
journalctl is not available on macOS
```

`journalctl` is a Linux/systemd tool and is not normally available on macOS.

---

### 1.3 502 reflection

A `502 Bad Gateway` generally means that a gateway or reverse proxy was unable to obtain a valid response from its upstream service.

An outside-in debugging process should therefore check:

1. Client request
2. Proxy/gateway
3. Network connectivity and DNS
4. Target port
5. Application process
6. Application health endpoint

In this lab, the QuickNotes listener was active, the `/health` endpoint returned `200`, and localhost networking worked correctly. Therefore, if a 502 occurred in front of this application, the next place to inspect would be the proxy/upstream configuration and the address/port it uses to reach QuickNotes.

---

# Task 2 — Debugging a Port Conflict

## 2.1 Reproducing the failure

The first QuickNotes instance was started on port `8080`:

```bash
ADDR=:8080 go run . &
PID1=$!
sleep 1
echo "PID1=$PID1"
```

The process started successfully:

```text
PID1=45105
quicknotes listening on :8080 (notes loaded: 6)
```

A second instance was then started using the same port:

```bash
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &
PID2=$!
sleep 2
echo "PID2=$PID2"
```

The second instance failed:

```text
quicknotes listening on :8080 (notes loaded: 6)
listen: listen tcp :8080: bind: address already in use
exit status 1
```

This demonstrates that two processes cannot bind to the same TCP listening address and port under the same configuration.

---

## 2.2 Outside-in debugging

The running `go run` process was checked with:

```bash
ps -ef | grep "go run" | grep -v grep
```

Result:

```text
501 45105 39312 0 11:53PM ttys009 0:00.18 go run .
```

The actual listening process was identified with:

```bash
sudo lsof -nP -iTCP:8080 -sTCP:LISTEN
```

Result:

```text
COMMAND     PID USER   FD   TYPE   NAME
quicknote 45151 alsu    5u   IPv6  TCP *:8080 (LISTEN)
```

The health endpoint was tested:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
```

Result:

```text
200
```

The macOS firewall equivalent was inspected with:

```bash
sudo pfctl -sr
```

The output contained the standard macOS anchors:

```text
scrub-anchor "com.apple/*" all fragment reassemble
anchor "com.apple/*" all
```

There was no obvious rule blocking port `8080`.

DNS lookup for `localhost` using:

```bash
dig +short localhost
```

returned no result. This is expected because `localhost` is normally resolved locally rather than through public DNS.

---

## 2.3 Repair

Initially, the `go run` parent process was terminated:

```bash
kill 45105
```

However, the compiled QuickNotes child process continued listening on port `8080`.

The child process was therefore terminated:

```bash
kill 45151
```

Verification showed that PID `45151` no longer existed:

```bash
ps -p 45151
```

The listening-port check then returned no process:

```bash
sudo lsof -nP -iTCP:8080 -sTCP:LISTEN
```

QuickNotes was then restarted successfully:

```bash
ADDR=:8080 go run .
```

Result:

```text
quicknotes listening on :8080 (notes loaded: 6)
```

The important lesson is that `go run` creates and runs a compiled child binary. Killing the `go run` parent does not necessarily terminate the child that owns the listening socket.

---

# Mini-postmortem

The main failure in Task 2 was a port conflict on TCP port `8080`. The second QuickNotes instance could not start because another process was already listening on the same port. The debugging process followed an outside-in approach: first checking the process, then identifying the process actually owning the socket with `lsof`, testing the application through `/health`, and checking the firewall configuration. The most important finding was that `go run` had a parent process and a compiled child process. Killing only the parent did not free the port. After terminating the child process, port `8080` became available and QuickNotes started normally. This demonstrates why identifying the process that owns the listening socket is more reliable than only inspecting the original command that launched the application.

---

# Bonus — TLS with Caddy

Caddy was installed and configured as a local HTTPS reverse proxy.

The lab configuration was:

```caddyfile
https://localhost:8443 {
    tls internal
    reverse_proxy localhost:8080
}
```

Caddy successfully started an HTTPS listener on port `8443` and generated a local certificate.

HTTPS was tested with:

```bash
curl -vk https://localhost:8443/health
```

The TLS handshake reported:

```text
TLS handshake, Client hello (1)
TLS handshake, Server hello (2)
TLS handshake, Certificate (11)
TLS handshake, CERT verify (15)
TLS handshake, Finished (20)
```

The negotiated protocol was:

```text
TLSv1.3
```

The cipher suite was:

```text
AEAD-CHACHA20-POLY1305-SHA256
```

The certificate issuer was:

```text
CN=Caddy Local Authority - ECC Intermediate
```

ALPN negotiation selected HTTP/2:

```text
ALPN: server accepted h2
using HTTP/2
```

The HTTPS request successfully reached QuickNotes through Caddy:

```text
HTTP/2 200
via: 1.1 Caddy

{"notes":6,"status":"ok"}
```

---

## TLS packet capture

TLS traffic was captured on the macOS loopback interface:

```bash
sudo tcpdump -i lo0 -nn -s 0 -w lab4-tls.pcap 'tcp port 8443'
```

The capture contained:

```text
33 packets captured
1059 packets received by filter
0 packets dropped by kernel
```

The capture was decoded with:

```bash
sudo tcpdump -r lab4-tls.pcap -nn -X | tee lab4-tls.txt
```

The capture showed the TCP connection to:

```text
::1:8443
```

followed by TLS handshake records.

The ClientHello packet contained the SNI value:

```text
localhost
```

and advertised:

```text
h2
http/1.1
```

The server responded with TLS handshake data, followed by encrypted TLS records.

The packet capture therefore demonstrates the TCP connection and TLS handshake at the packet level, while `curl -vk` provides the decoded TLS handshake information and certificate details.

After the handshake, the HTTPS request was successfully processed and returned HTTP `200`.

---

# Conclusion

Lab 4 demonstrated:

* localhost networking and the macOS `lo0` interface;
* TCP connection establishment and termination;
* HTTP traffic captured with `tcpdump`;
* process and listening-port inspection with `lsof`;
* routing-table inspection with `netstat`;
* connectivity and DNS diagnostics;
* debugging and repairing a TCP port conflict;
* the difference between a `go run` parent process and its compiled child process;
* HTTPS reverse proxying with Caddy;
* TLS 1.3 handshake inspection;
* HTTP/2 negotiation;
* local certificate generation;
* packet capture of encrypted TLS traffic.
