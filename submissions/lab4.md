# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

> **Environment:** macOS.
> I have macos as primary machine, this OS is close to linux in some sense, so I hope it wont be problem. 
> Here is mapping of linux to macos:
> Loopback is `lo0` (not `lo`). \
> `ss` → `lsof`\
>  `ip route` → `netstat -rn`/`route`\
>  `journalctl` → process stderr / `log`\
> `iptables`/`nft` → `pfctl`.

---

What I have done?

## Task 1 — Trace a Request End-to-End


I started QuickNotes on `:8080`, captured loopback traffic with `tcpdump -i lo0`, fired one
`POST /notes`, then decoded the capture to `lab4-trace.txt`. Annotated excerpt:

```
# ── 1. TCP 3-way handshake  ──────────────────────────
18:22:34.449477 IP6 ::1.59868 > ::1.8080: Flags [S],  seq 1247080406                  # client SYN
18:22:34.449567 IP6 ::1.8080 > ::1.59868: Flags [S.], seq 3143961569, ack 1247080407  # server SYN+ACK
18:22:34.449587 IP6 ::1.59868 > ::1.8080: Flags [.],  ack 1                            # client ACK -> ESTABLISHED

# ── 2. HTTP request ────────────────────────────────────────────────────
18:22:34.449626 IP6 ::1.59868 > ::1.8080: Flags [P.], seq 1:175, length 174           # request pushed (PSH) to server
    POST /notes HTTP/1.1
    Host: localhost:8080
    User-Agent: curl/8.7.1
    Content-Type: application/json
    Content-Length: 39

    {"title":"trace me","body":"in flight"}
18:22:34.449658 IP6 ::1.8080 > ::1.59868: Flags [.],  ack 175                          # server ACKs the 174 bytes

# ── 3. HTTP response ───────────────────────────────────────────────────
18:22:34.451026 IP6 ::1.8080 > ::1.59868: Flags [P.], seq 1:203, length 202            # 201 Created, ~1.4 ms later
    HTTP/1.1 201 Created
    Content-Type: application/json
    Date: Tue, 16 Jun 2026 15:22:34 GMT
    Content-Length: 89

    {"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T15:22:34.45005Z"}
18:22:34.451050 IP6 ::1.59868 > ::1.8080: Flags [.],  ack 203                          # client ACKs the response

# ── 4. Connection close  ───────────────────────────────
18:22:34.451142 IP6 ::1.59868 > ::1.8080: Flags [F.], seq 175, ack 203                 # client FIN (curl done)
18:22:34.451174 IP6 ::1.8080 > ::1.59868: Flags [.],  ack 176                          # server ACKs client FIN
18:22:34.451195 IP6 ::1.8080 > ::1.59868: Flags [F.], seq 203, ack 176                 # server FIN
18:22:34.451232 IP6 ::1.59868 > ::1.8080: Flags [.],  ack 204                          # client ACK -> fully closed

# What I noticed:
#  - Transport is IPv6 loopback (::1 = the v6 form of 127.0.0.1); localhost resolved to IPv6.
#  - Client ephemeral port 59868  <->  server port 8080.
#  - Only the two [P.] packets carry data (174 bytes in, 202 out); every handshake/close packet is length 0.
```

Flags: `[S]`=SYN, `[S.]`=SYN+ACK, `[.]`=ACK, `[P.]`=PSH+ACK/data, `[F.]`=FIN:

- **TCP 3-way handshake** — `449477` `[S]` → `449567` `[S.]` → `449587` `[.]`: connection opens between ports `59868 ↔ 8080`.
- **HTTP request** — `449626` `[P.] length 174`: `POST /notes HTTP/1.1` + body `{"title":"trace me","body":"in flight"}`; server ACKs at `449658`.
- **HTTP response** — `451026` `[P.] length 202`: `HTTP/1.1 201 Created` + body `{"id":6,...}` (~1.4 ms after the request); client ACKs at `451050`.
- **Connection close** — `451142` `[F.]` (client FIN) → `451174` `[.]` → `451195` `[F.]` (server FIN) → `451232` `[.]`: 4-way teardown, fully closed.



**1. What's listening on :8080?**  *(Linux `ss -tlnp`-> macOS `lsof`)*
```
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
COMMAND    PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 9184 ephy    5u  IPv6 0x1c0e3c6a7630f30d      0t0  TCP *:8080 (LISTEN)
```

**2. Routes from this host**  *(Linux `ip route show` -> macOS `netstat -rn` / `route get default`)*
```
$ netstat -rn | head -15
Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
0/1                utun4              UScg                utun4       
default            10.240.16.1        UGScg                 en0       
10.8.1.1           10.8.1.1           UH                  utun4       
10.240.16/21       link#11            UCS                   en0      !
10.240.16.1/32     link#11            UCS                   en0      !
10.240.16.1        18:9c:5d:5f:73:40  UHLWIir               en0   1161
10.240.16.52       bc:d0:74:5f:2a:28  UHLWI                 en0   1064
10.240.16.63       7a:4f:bc:8d:6d:d7  UHLWI                 en0    918
10.240.16.74       22:7d:a4:fd:9:2c   UHLWI                 en0      !
10.240.16.94       ce:8a:92:6f:ec:b8  UHLWI                 en0   1124
10.240.16.116      de:cd:f0:85:5f:69  UHLWI                 en0   1173
```

**3. Reachability**  *(`mtr` over loopback)*
```
$ sudo mtr -rwzbc 5 localhost
HOST: Starless-night.local               Loss%   Snt   Last   Avg  Best  Wrst StDev
  1. AS???         localhost (::1)        0.0%     5    0.1   0.1   0.1   0.1   0.0
```

**4. DNS works**  *(`dig` — native on macOS)*
```
$ dig +short example.com @1.1.1.1
172.66.147.243
104.20.23.154
```

**5. Logs**  *(Linux `journalctl -u quicknotes` -> macOS: stderr)*
macOS has no systemd/journalctl. QuickNotes runs in the foreground and logs to **stderr**:
```
2026/06/16 18:20:33 quicknotes listening on :8080 (notes loaded: 5)
```

since QuickNotes logs only start-up and finish - there is no message even after post. There are no per-request logs, only lifecycle logs.

### QUICKNOTES RETURNED 502! WHAT SHOULD I DO?

> 
Well, a 502 error means a gateway or reverse proxy in front of QuickNotes received an invalid 
response from the app, so the fault is on the proxy→app link. 

I would debug in the following order: 
 - first confirm the process is up and actually bound to its port
(`lsof -iTCP:8080 -sTCP:LISTEN`)
 - If it is listening, I would d bypass the proxy and hit the app directly (`curl -v localhost:8080/health`) to
separate problem into; app os broken, proxy can not achive app.
 -  I would check the proxy's upstream
target/config and the app's stderr for a slow/closed connection. 

---

## Task 2 — Outside-In Debugging on a Broken Deploy

What I have done?


Started instance #1, then started instance #2 on the same port,
which failed immediately:
```
listen: listen tcp :8080: bind: address already in use
exit status 1
```



**1. Is it running?**  
```
$ ps aux | grep -E '[g]o run|[e]xe/'
ephy   9969   0.0  0.2 411958352  33040 s002  S+   6:47PM   0:00.24 go run .
```
→ the `go run .` process is up PID 9969. ✓

**2. Is it listening?**  
```
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
COMMAND    PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 9973 ephy    5u  IPv6 0xe0ceda0b0d976cb1      0t0  TCP *:8080 (LISTEN)
```

It listens port 8080(in fact it uses "child binary", since go run. creates wrapper process)

**3. Reachable from the host?**
```
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```
200 - definetly reachable

**4. Is a firewall blocking?**  
```
$ sudo pfctl -s rules ; sudo pfctl -s info | head -1
scrub-anchor "com.apple/*" all fragment reassemble
anchor "com.apple/*" all
anchor "amn/*" all
Status: Enabled for 0 days 00:44:49           Debug: Urgent
```
→ pf is **Enabled**, however,  the ruleset holds only the default Apple anchors  — nothing blocks `:8080`; the `200` above confirms it. 

**5. Is it DNS?**
```
$ dig +short localhost ; grep -i localhost /etc/hosts
127.0.0.1	localhost
::1		localhost
```
→ `dig +short localhost` prints nothing — `localhost` is obtained from `/etc/hosts` 

The second instance cannot bind because the first already owns `:8080` It is a host/OS resource conflict, not a network, firewall, or
DNS problem.



### Postmortem

> 
**What happened.** A second QuickNotes instance was launched while the first still held `:8080`;
it exited at once with `bind: address already in use`. 

**Why it's systemic, not a person's fault.** One OS invariant — a single listener per
`(address, port)`. The code isn't "wrong" -  the environment let two starts race for one port.

**What tooling prevents it.** A process supervisor (systemd/launchd) that enforces one unit and
stops the old instance before starting the new.
A startup port pre-check that fails fast with a
clear message. Make as a good habit: 
`lsof -i:PORT` The fix is to make somehow exactly one owner of the port a guarantee of the
deploy system rather than something developer must remember.
