# Lab 4 Submission — OS & Networking: Trace, Debug, and Read the Substrate

## Task 1 — Trace a Request End-to-End

### 1.1 Capture setup

QuickNotes was started locally from the `app/` directory using:

    go run .

A packet capture was started on loopback for TCP port 8080:

    sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap

Then one request was sent:

    curl -v -X POST http://localhost:8080/notes \
      -H 'Content-Type: application/json' \
      -d '{"title":"trace me","body":"in flight"}'

The request returned:

    HTTP/1.1 201 Created

Response body:

    {"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-09T20:21:16.071257766Z"}

### 1.2 Annotated packet trace

The decoded trace was saved in:

    lab4-trace.txt

TCP three-way handshake:

    23:21:16.065482 IP6 ::1.32966 > ::1.8080: Flags [S]
    23:21:16.066930 IP6 ::1.8080 > ::1.32966: Flags [S.]
    23:21:16.067406 IP6 ::1.32966 > ::1.8080: Flags [.]

This shows SYN, SYN/ACK, and ACK.

HTTP request:

    POST /notes HTTP/1.1
    Host: localhost:8080
    User-Agent: curl/8.5.0
    Accept: */*
    Content-Type: application/json
    Content-Length: 39

    {"title":"trace me","body":"in flight"}

HTTP response:

    HTTP/1.1 201 Created
    Content-Type: application/json
    Content-Length: 93

    {"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-09T20:21:16.071257766Z"}

Connection close:

    23:21:16.090747 IP6 ::1.32966 > ::1.8080: Flags [F.]
    23:21:16.091016 IP6 ::1.8080 > ::1.32966: Flags [F.]
    23:21:16.091238 IP6 ::1.32966 > ::1.8080: Flags [.]

The connection closed with FIN/FIN/ACK.

### 1.3 Five debugging commands

#### 1. What is listening?

Command:

    ss -tlnp | grep :8080

Output:

    LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=9136,fd=3))

Decision:

    QuickNotes is listening on TCP port 8080.

#### 2. What routes does the host have?

Command:

    ip route show

Output:

    default via 192.168.240.1 dev eth0 proto kernel
    192.168.240.0/20 dev eth0 proto kernel scope link src 192.168.254.234

Decision:

    The host has a default route through eth0 and a directly connected local subnet route.

#### 3. Can localhost be reached?

Command:

    mtr -rwc 5 localhost

Output:

    HOST: DESKTOP-U1R4GKD Loss% Snt Last Avg Best Wrst StDev
      1.|-- localhost 0.0% 5 0.1 0.3 0.1 1.4 0.6

Decision:

    Localhost is reachable with 0% packet loss over the loopback path.

#### 4. Does DNS work?

Command:

    dig +short example.com @1.1.1.1

Output:

    8.47.69.0
    8.6.112.0

Decision:

    DNS resolution works using Cloudflare resolver 1.1.1.1.

#### 5. Are there user service logs?

Command:

    journalctl --user -u quicknotes -n 20 || true

Output:

    -- No entries --

Decision:

    QuickNotes was run manually with `go run .`, not installed as a user systemd service, so there are no journald unit logs for `quicknotes`.

### 1.4 502 debugging reflection

If QuickNotes returned 502, I would debug outside-in. First I would check whether the service process is running, then whether it is listening on the expected port with `ss -tlnp`. Next I would test local reachability with `curl localhost:8080/health`. If the application is healthy locally, I would check the reverse proxy or load balancer path, firewall rules, and DNS resolution. This order separates application failure from transport, routing, firewall, and name-resolution problems.

## Task 2 — Broken Deploy Debugging

### 2.1 Broken instance reproduction

I started one QuickNotes instance on port 8080:

    ADDR=:8080 go run . &
    PID1=$!

Then I started a second instance on the same port:

    ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &

The second instance failed with:

    2026/06/09 23:35:11 quicknotes listening on :8080 (notes loaded: 6)
    2026/06/09 23:35:11 listen: listen tcp :8080: bind: address already in use
    exit status 1

Root cause:

    listen tcp :8080: bind: address already in use

Only one process can bind to TCP port 8080 at a time. The first QuickNotes process was already listening, so the second instance failed.

### 2.2 Outside-in debugging chain

#### 1. Is the service/process running?

Command:

    ps -ef | grep quicknotes | grep -v grep || true
    ps -ef | grep "go run" | grep -v grep || true

Output:

    teeroyce 9382 9319 0 23:35 pts/2 00:00:00 /home/teeroyce/.cache/go-build/.../quicknotes
    teeroyce 9319 3091 0 23:35 pts/2 00:00:00 go run .

Decision:

    A QuickNotes compiled child process was running, and the `go run .` wrapper was also present.

#### 2. Is the service listening?

Command:

    ss -tlnp | grep 8080

Output:

    LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=9382,fd=3))

Decision:

    Port 8080 was already occupied by the first QuickNotes instance.

#### 3. Is the application reachable locally?

Command:

    curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health

Output:

    200

Decision:

    The existing QuickNotes instance was healthy and reachable locally.

#### 4. Is the firewall blocking traffic?

Command:

    sudo iptables -L -n -v 2>/dev/null || sudo nft list ruleset 2>/dev/null || true

Output:

    No blocking firewall rule was shown in the captured output.

Decision:

    The failure was not caused by firewall blocking because the local health check returned HTTP 200.

#### 5. Does localhost resolve?

Command:

    dig +short localhost

Output:

    127.0.0.1

Decision:

    Localhost name resolution works.

### 2.3 Repair

First I tried killing `PID1`, but this only terminated the `go run` wrapper. The compiled QuickNotes child process continued listening on port 8080:

    LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=9382,fd=3))

I then killed the actual listener:

    kill 9382

After that, port 8080 became free:

    8080 is free after killing actual listener

Then I restarted QuickNotes:

    ADDR=:8080 go run . &

The health check passed:

    {"notes":6,"status":"ok"}

The repaired listener was visible:

    LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=9617,fd=3))

### 2.4 Mini-postmortem

The failure happened because two QuickNotes instances tried to bind to the same TCP port, `:8080`. The first instance already owned the port, so the second instance failed immediately with `bind: address already in use`. The outside-in checks showed that DNS and local reachability were working, the existing application was healthy, and the real fault was at the process/socket layer. A useful prevention is to check port ownership before deployment using `ss -tlnp | grep 8080`, stop the existing service cleanly, and prefer a process manager such as systemd so service lifecycle is explicit.

## Bonus — HTTPS Reverse Proxy and TLS Inspection

### B.1 Caddy reverse proxy

Caddy was installed using:

    sudo apt install -y caddy

Version:

    2.6.2

Caddy was configured with `/etc/caddy/Caddyfile`:

    localhost:8443 {
        reverse_proxy localhost:8080
    }

The configuration validated successfully:

    Valid configuration

Caddy service status showed:

    Active: active (running)
    certificate obtained successfully
    identifier="localhost"

### B.2 HTTPS request through Caddy

Command:

    curl -vk https://localhost:8443/health

Important TLS handshake evidence:

    TLSv1.3 (OUT), TLS handshake, Client hello (1)
    TLSv1.3 (IN), TLS handshake, Server hello (2)
    TLSv1.3 (IN), TLS handshake, Certificate (11)
    SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256 / X25519 / id-ecPublicKey

HTTP result:

    HTTP/2 200
    {"notes":6,"status":"ok"}

### B.3 TLS packet capture

TLS traffic was captured using:

    sudo tcpdump -U -i lo -nn -s 0 -w lab4-tls.pcap 'tcp port 8443'

Capture result:

    20 packets captured
    40 packets received by filter
    0 packets dropped by kernel

Decoded packet summary showed:

    SYN
    SYN/ACK
    ACK
    encrypted TLS application data
    FIN/RST close

The plaintext HTTP request is not visible in the packet capture because it is encrypted inside TLS.

### B.4 Certificate chain

OpenSSL initially failed without SNI, so I reran it with `-servername localhost`:

    openssl s_client -connect localhost:8443 -servername localhost -showcerts

The certificate chain showed:

    Certificate chain
    issuer=CN = Caddy Local Authority - ECC Intermediate
    New, TLSv1.3, Cipher is TLS_AES_128_GCM_SHA256
    Protocol  : TLSv1.3
    Cipher    : TLS_AES_128_GCM_SHA256

The certificate is issued by Caddy's local CA, which is expected for localhost automatic HTTPS.

### B.5 TLS 1.0 and TLS 1.1 deprecation evidence

TLS 1.0 test:

    openssl s_client -connect localhost:8443 -servername localhost -tls1

Result:

    tls_setup_handshake:no protocols available
    no peer certificate available
    New, (NONE), Cipher is (NONE)

TLS 1.1 test:

    openssl s_client -connect localhost:8443 -servername localhost -tls1_1

Result:

    tls_setup_handshake:no protocols available
    no peer certificate available
    New, (NONE), Cipher is (NONE)

TLS 1.2 still works:

    New, TLSv1.2, Cipher is ECDHE-ECDSA-AES128-GCM-SHA256
    Protocol  : TLSv1.2

TLS 1.3 works and was used by curl:

    SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256 / X25519 / id-ecPublicKey

Conclusion:

    TLS 1.0 and TLS 1.1 are deprecated and unavailable in this environment. Caddy successfully serves modern HTTPS on localhost:8443 using TLS 1.2/1.3.

### B.6 Wireshark screenshots

The following Wireshark screenshots are included as bonus evidence:

- `lab4-wireshark-clienthello.png` — ClientHello showing SNI `localhost`, TLS version field, and offered cipher suites.
- `lab4-wireshark-serverhello.png` — ServerHello showing the selected TLS version and cipher suite.
- `lab4-wireshark-certchain.png` — OpenSSL certificate chain evidence showing Caddy local CA certificates and TLSv1.3 cipher information.

TLS 1.0 and TLS 1.1 are not negotiated. The working connection uses modern TLS, and the successful curl/OpenSSL evidence shows TLSv1.3 with `TLS_AES_128_GCM_SHA256`.
