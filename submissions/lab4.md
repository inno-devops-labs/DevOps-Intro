# Lab 4 Submission

## Environment Note

I ran this lab on macOS, not Linux:

```text
Darwin Tatyanas-MacBook-Air.local 25.0.0 Darwin Kernel Version 25.0.0: Wed Sep 17 21:42:08 PDT 2025; root:xnu-12377.1.9~141/RELEASE_ARM64_T8132 arm64
```

Some Linux commands from the lab are not available on macOS (`ss`, `ip`, `mtr`, `journalctl`). I captured their exact result and used macOS equivalents where needed.

## Task 1 - Trace A Request End-To-End

### QuickNotes Start

I started QuickNotes on port `8080` with a temporary data file, so the lab request did not modify the tracked `app/data/notes.json`.

```text
$ ADDR=:8080 DATA_PATH=/tmp/qn-lab4-notes.json SEED_PATH=seed.json go run .
2026/06/16 13:51:15 quicknotes listening on :8080 (notes loaded: 4)
```

### Packet Capture

Capture files included in this PR:

- `lab4-trace.pcap`
- `lab4-trace.txt`

Capture and decode commands:

```text
$ sudo tcpdump -i lo0 -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap
$ sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt
```

The trace uses IPv6 loopback (`::1`) because `curl` resolved `localhost` to both `::1` and `127.0.0.1`, then connected to `::1` first.

### Annotated Packet Decode

#### TCP Three-Way Handshake

```text
13:59:19.566174 IP6 ::1.62996 > ::1.8080: Flags [S], seq 3300640900, length 0
13:59:19.566309 IP6 ::1.8080 > ::1.62996: Flags [S.], seq 1608285852, ack 3300640901, length 0
13:59:19.566340 IP6 ::1.62996 > ::1.8080: Flags [.], ack 1, length 0
```

The client opened a TCP connection from ephemeral port `62996` to QuickNotes on `8080`. The server replied with `SYN/ACK`, and the client completed the handshake with `ACK`.

#### HTTP Request

```text
13:59:19.566381 IP6 ::1.62996 > ::1.8080: Flags [P.], seq 1:175, ack 1, length 174: HTTP: POST /notes HTTP/1.1
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.7.1
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

This is the application payload. TCP carried one HTTP request with method `POST`, path `/notes`, JSON content type, and a 39-byte JSON body.

#### HTTP Response

```text
13:59:19.568815 IP6 ::1.8080 > ::1.62996: Flags [P.], seq 1:204, ack 175, length 203: HTTP: HTTP/1.1 201 Created
HTTP/1.1 201 Created
Content-Type: application/json
Date: Tue, 16 Jun 2026 10:59:19 GMT
Content-Length: 90

{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T10:59:19.567826Z"}
```

QuickNotes accepted the note and returned `201 Created`. The response JSON includes the new note id and timestamp.

#### Connection Close

```text
13:59:19.568970 IP6 ::1.62996 > ::1.8080: Flags [F.], seq 175, ack 204, length 0
13:59:19.569000 IP6 ::1.8080 > ::1.62996: Flags [.], ack 176, length 0
13:59:19.569022 IP6 ::1.8080 > ::1.62996: Flags [F.], seq 204, ack 176, length 0
13:59:19.569073 IP6 ::1.62996 > ::1.8080: Flags [.], ack 205, length 0
```

The client started a graceful close with `FIN`. The server acknowledged it, sent its own `FIN`, and the client sent the final `ACK`.

### HTTP Request Evidence From `curl -v`

This is not a replacement for the packet capture, but it proves the L7 request and response before the packet-level decode.

```text
$ curl -v -X POST http://localhost:8080/notes -H 'Content-Type: application/json' -d '{"title":"trace me","body":"in flight"}'
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> POST /notes HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.7.1
> Accept: */*
> Content-Type: application/json
> Content-Length: 39
>
* upload completely sent off: 39 bytes
< HTTP/1.1 201 Created
< Content-Type: application/json
< Date: Tue, 16 Jun 2026 10:59:19 GMT
< Content-Length: 90
<
{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T10:59:19.567826Z"}
```

### Five Debugging Commands

#### 1. What is listening?

The Linux command is unavailable:

```text
$ ss -tlnp | grep :8080
zsh:1: command not found: ss
```

macOS equivalent:

```text
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
COMMAND     PID    USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 44179 tatyana    5u  IPv6 0xec0b65e3ef560135      0t0  TCP *:8080 (LISTEN)
```

QuickNotes is listening on TCP port `8080`.

#### 2. Routes from the host

The Linux command is unavailable:

```text
$ ip route show
zsh:1: command not found: ip
```

macOS equivalent:

```text
$ netstat -rn | egrep '(^default|^127|^::1|Destination)'
Destination        Gateway            Flags               Netif Expire
default            192.168.1.1        UGScg                 en0
127                127.0.0.1          UCS                   lo0
127.0.0.1          127.0.0.1          UH                    lo0
Destination                             Gateway                                 Flags               Netif Expire
default                                 fe80::%utun0                            UGcIg               utun0
::1                                     ::1                                     UHL                   lo0

$ route -n get 127.0.0.1
route to: 127.0.0.1
destination: 127.0.0.1
interface: lo0
flags: <UP,HOST,DONE,LOCAL>
```

localhost traffic goes through the loopback interface `lo0`.

#### 3. Reachability

The Linux command is unavailable:

```text
$ mtr -rwc 5 localhost
zsh:1: command not found: mtr
```

macOS equivalent:

```text
$ ping -c 5 localhost
PING localhost (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.066 ms
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.179 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.141 ms
64 bytes from 127.0.0.1: icmp_seq=3 ttl=64 time=0.211 ms
64 bytes from 127.0.0.1: icmp_seq=4 ttl=64 time=0.123 ms

--- localhost ping statistics ---
5 packets transmitted, 5 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 0.066/0.144/0.211/0.049 ms
```

Local reachability is healthy.

#### 4. DNS works

```text
$ dig +short example.com @1.1.1.1
104.20.23.154
172.66.147.243
```

Public DNS resolution works.

#### 5. Logs

The Linux command is unavailable:

```text
$ journalctl --user -u quicknotes -n 20 || true
zsh:1: command not found: journalctl
```

macOS equivalent: QuickNotes was run in the foreground, so the process log came from the terminal:

```text
2026/06/16 13:51:15 quicknotes listening on :8080 (notes loaded: 4)
```

There is no `systemd` user service on this machine. For this local run, foreground logs are the source of truth.

### If QuickNotes Returned 502

I would start outside-in. First, I would check whether the reverse proxy or caller can reach QuickNotes at all. Then I would check whether QuickNotes is listening on the expected address and port, because a 502 often means the upstream connection failed. After that, I would inspect the app logs for startup errors, panics, or bind failures. If the listener and app logs look healthy, I would check routing, firewall rules, and DNS between the proxy and the app.

## Task 2 - Outside-In Debugging On A Broken Deploy

### Broken Instance

I reproduced the failure by keeping one QuickNotes instance on `:8080`, then starting a second instance on the same address.

```text
$ ADDR=:8080 DATA_PATH=/tmp/qn-lab4-broken-notes.json SEED_PATH=seed.json go run .
2026/06/16 13:51:53 quicknotes listening on :8080 (notes loaded: 4)
2026/06/16 13:51:53 listen: listen tcp :8080: bind: address already in use
exit status 1
```

Root cause: the second process could not bind to `:8080` because the first process already owned that port.

### Outside-In Chain

#### 1. Is it running?

```text
$ ps -ef | grep quicknotes | grep -v grep
501 44179 44167   0  1:51PM ttys000    0:00.01 /Users/tatyana/Library/Caches/go-build/78/78618fa489040d9117ca596e8fb238d7fa7c3960b5d0ea09e47bb62518ad3028-d/quicknotes
```

One QuickNotes process is running.

#### 2. Is it listening?

```text
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
COMMAND     PID    USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 44179 tatyana    5u  IPv6 0xec0b65e3ef560135      0t0  TCP *:8080 (LISTEN)
```

Port `8080` is already occupied by the first process.

#### 3. Is it reachable from host?

```text
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```

The first instance is healthy, but that does not help the second instance start.

#### 4. Is a firewall blocking it?

The Linux firewall commands are not available on this macOS host. I checked the macOS application firewall:

```text
$ /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
Firewall is enabled. (State = 1)
```

The failure is not a firewall symptom. The bind error happens before a network packet needs to pass through the firewall.

#### 5. DNS?

```text
$ dig +short localhost
# no output

$ dscacheutil -q host -a name localhost
name: localhost
ipv6_address: ::1

name: localhost
ip_address: 127.0.0.1
```

`localhost` resolves through the local host resolver, not public DNS. DNS is not the root cause.

### Repair And Re-Verify

I stopped the conflicting first instance, then started one clean instance on `:8080`.

```text
^C2026/06/16 13:52:48 shutting down

$ ADDR=:8080 DATA_PATH=/tmp/qn-lab4-notes.json SEED_PATH=seed.json go run .
2026/06/16 13:53:01 quicknotes listening on :8080 (notes loaded: 5)

$ curl -s http://localhost:8080/health
{"notes":5,"status":"ok"}

$ lsof -nP -iTCP:8080 -sTCP:LISTEN
COMMAND     PID    USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 44442 tatyana    5u  IPv6 0x9b4d70de5c880a06      0t0  TCP *:8080 (LISTEN)
```

### Mini-Postmortem

This was not a code bug in the request handler. It was a coordination failure around ownership of a shared resource: TCP port `8080`. This kind of failure is systemic because local scripts, service managers, and developers can all try to start the same service without checking if the port is already in use. Good tooling can prevent it by using a process manager, clear service lifecycle commands, health checks, and preflight checks such as `lsof -i :8080` before startup. In production, the same idea should be enforced by orchestration: one owner for the port, explicit readiness checks, and logs that make bind failures visible immediately.

## Bonus Task - TLS Handshake Decode

### HTTPS Layer

I installed Caddy and Wireshark command-line tools with Homebrew:

```text
$ brew install caddy wireshark
```

Then I kept QuickNotes running on `:8080` and started Caddy as a local HTTPS reverse proxy on `:8443`.

```text
$ ADDR=:8080 DATA_PATH=/tmp/qn-lab4-bonus-notes.json SEED_PATH=seed.json go run .
2026/06/16 14:12:30 quicknotes listening on :8080 (notes loaded: 4)

$ caddy reverse-proxy --from localhost:8443 --to localhost:8080 --internal-certs --disable-redirects --access-log
server running
caddy proxying from https://localhost:8443 to localhost:8080
```

Caddy tried to install its local root CA into the macOS trust store, but that step needs `sudo`. I did not install the CA globally. Instead, I used `curl -k` only for this local lab request.

### Capture Files

Bonus files included in this PR:

- `lab4-tls.pcap`
- `lab4-tls.txt`
- `lab4-curl-tls.txt`
- `lab4-tcpdump-tls.txt`
- `lab4-openssl-s_client.txt`

Capture command and packet count:

```text
$ sudo tcpdump -i lo0 -nn -s 0 -c 20 -w lab4-tls.pcap 'tcp port 8443'
tcpdump: listening on lo0, link-type NULL (BSD loopback), snapshot length 524288 bytes
20 packets captured
121 packets received by filter
0 packets dropped by kernel
```

HTTPS verification:

```text
$ curl -vk https://localhost:8443/health
* SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256 / [blank] / UNDEF
* ALPN: server accepted h2
< HTTP/2 200
{"notes":4,"status":"ok"}
```

### ClientHello

I decoded the capture with Wireshark CLI (`tshark`). The ClientHello is frame `5`.

```text
$ tshark -r lab4-tls.pcap -Y 'tls.handshake.type == 1' -V
Frame Number: 5
Source Address: ::1
Destination Address: ::1
Source Port: 63686
Destination Port: 8443
Handshake Type: Client Hello (1)
Version: TLS 1.2 (0x0303)
Cipher Suites (49 suites)
Cipher Suite: TLS_CHACHA20_POLY1305_SHA256 (0x1303)
Cipher Suite: TLS_AES_256_GCM_SHA384 (0x1302)
Cipher Suite: TLS_AES_128_GCM_SHA256 (0x1301)
Extension: supported_versions (len=9) TLS 1.3, TLS 1.2, TLS 1.1, TLS 1.0
Supported Version: TLS 1.3 (0x0304)
Supported Version: TLS 1.2 (0x0303)
Supported Version: TLS 1.1 (0x0302)
Supported Version: TLS 1.0 (0x0301)
Extension: server_name (len=14) name=localhost
Server Name: localhost
ALPN Next Protocol: h2
ALPN Next Protocol: http/1.1
```

The client offered SNI `localhost`, HTTP/2 through ALPN, and several cipher suites. The important field is not the legacy `Version: TLS 1.2`; it is the `supported_versions` extension.

### ServerHello

The ServerHello is frame `7`.

```text
$ tshark -r lab4-tls.pcap -Y 'tls.handshake.type == 2' -V
Frame Number: 7
Source Address: ::1
Destination Address: ::1
Source Port: 8443
Destination Port: 63686
Handshake Type: Server Hello (2)
Version: TLS 1.2 (0x0303)
Cipher Suite: TLS_CHACHA20_POLY1305_SHA256 (0x1303)
Extension: supported_versions (len=2) TLS 1.3
Supported Version: TLS 1.3 (0x0304)
```

The server selected TLS 1.3 and `TLS_CHACHA20_POLY1305_SHA256`. After this point, most TLS 1.3 handshake data is encrypted, so Wireshark shows it as encrypted application data.

### Certificate Chain

```text
$ openssl s_client -connect localhost:8443 -showcerts -servername localhost </dev/null
Certificate chain
 0 s:
   i:CN=Caddy Local Authority - ECC Intermediate
   a:PKEY: EC, (prime256v1); sigalg: ecdsa-with-SHA256
   v:NotBefore: Jun 16 11:13:22 2026 GMT; NotAfter: Jun 16 23:13:22 2026 GMT
 1 s:CN=Caddy Local Authority - ECC Intermediate
   i:CN=Caddy Local Authority - 2026 ECC Root
   a:PKEY: EC, (prime256v1); sigalg: ecdsa-with-SHA256
   v:NotBefore: Jun 16 11:13:21 2026 GMT; NotAfter: Jun 23 11:13:21 2026 GMT
New, TLSv1.3, Cipher is TLS_AES_128_GCM_SHA256
Protocol: TLSv1.3
Verify return code: 20 (unable to get local issuer certificate)
```

The verification warning is expected because this is Caddy's local CA and I did not install it into the macOS trust store. It is not a problem for this controlled local test.

### TLS 1.0 And TLS 1.1 Deprecation

The negotiation step that removes TLS 1.0 and TLS 1.1 is the protocol-version negotiation in the `supported_versions` extension. The ClientHello listed TLS 1.3, 1.2, 1.1, and 1.0, but the ServerHello selected only TLS 1.3. In a modern configuration, a server should reject a client that only offers TLS 1.0 or TLS 1.1 because there is no acceptable shared protocol version. This happens before normal HTTP traffic is exchanged.
