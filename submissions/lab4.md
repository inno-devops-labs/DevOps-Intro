# Lab 4 submission

## Task 1 — Trace a Request End-to-End (6 pts)

### 1.1: Packet capture

Started QuickNotes, captured on lo0 with tcpdump, sent a POST:

```
❯ curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'
```

### 1.2: Decode the capture

Full trace file: `submissions/artifacts/lab4/lab4-trace.txt`

Three-way handshake: SYN → SYN/ACK → ACK

```
23:15:00.951933 IP6 ::1.62124 > ::1.8080: Flags [S]
23:15:00.952099 IP6 ::1.8080 > ::1.62124: Flags [S.]
23:15:00.952132 IP6 ::1.62124 > ::1.8080: Flags [.]
```

HTTP request + JSON body:

```
23:15:00.952180 IP6 ::1.62124 > ::1.8080: Flags [P.]: HTTP: POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.7.1
Content-Type: application/json
{"title":"trace me","body":"in flight"}
```

HTTP response 201:

```
23:15:00.954467 IP6 ::1.8080 > ::1.62124: Flags [P.]: HTTP: HTTP/1.1 201 Created
{"id":6,"title":"trace me","body":"in flight","created_at":"..."}
```

Connection close:

```
23:15:00.954620 IP6 ::1.62124 > ::1.8080: Flags [F.]
23:15:00.954671 IP6 ::1.8080 > ::1.62124: Flags [F.]
```

### 1.3: Five debugging commands

**1) What's listening?** (macOS: lsof instead of ss)

```
❯ lsof -i :8080
COMMAND    PID     USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
quicknote 8095 moflotas    5u  IPv6 0x65f819a730ae6f93      0t0  TCP *:http-alt (LISTEN)
```

**2) Routes** (macOS: netstat -rn instead of ip route)

```
❯ netstat -rn
Internet:
Destination        Gateway            Flags       Netif Expire
default            192.168.0.1        UGScg         en0
127                127.0.0.1          UCS           lo0
127.0.0.1          127.0.0.1          UH            lo0
```

**3) Reachability**

```
❯ sudo mtr -rwc 5 localhost
HOST: Timofeys-MacBook-Pro.local Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost                   0.0%     5    0.2   0.2   0.1   0.2   0.0
```

**4) DNS**

```
❯ dig +short example.com @1.1.1.1
8.47.69.0
8.6.112.0
```

**5) Logs** (journalctl not available on macOS)

```
❯ journalctl --user -u quicknotes -n 20 || true
zsh: command not found: journalctl
```

### 1.4: 502-debug reflection

First check with lsof or ss if the process is alive on :8080. If yes, curl localhost directly to see if the app
responds — 200 means the problem is upstream (proxy, DNS, firewall), anything else means the app is the issue and I'd
check its logs. A 502 is always a symptom, not the root cause.

## Task 2 — Outside-In Debugging (4 pts)

### 2.1: Reproduce the broken deploy

```
❯ cd app/
❯ ADDR=:8080 go run . &
PID1=$!
❯ sleep 1
❯ ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &
PID2=$!
❯ sleep 2
```

Second instance failed:

```
❯ cat /tmp/qn-broken.log
2026/06/16 23:27:50 quicknotes listening on :8080 (notes loaded: 6)
2026/06/16 23:27:50 listen: listen tcp :8080: bind: address already in use
exit status 1
```

```
❯ ps -ef | grep "go run" | grep -v grep
  501  8179  8177   0 11:27PM ??         0:00.34 go run .
```

### 2.2: Outside-in debug chain

1) Is the process running?

```
❯ ps -ef | grep quicknotes | grep -v grep
  501  8095  8090   0 11:26PM ??         0:00.00 quicknotes
```

Running.

2) Is it listening?

```
❯ lsof -i :8080
quicknote 8095 moflotas  5u  IPv6 ... TCP *:http-alt (LISTEN)
```

Yes, bound to :8080.

3) App responding?

```
❯ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```

Returns 200.

4) Firewall?

```
❯ sudo iptables -L -n -v 2>/dev/null || sudo nft list ruleset 2>/dev/null || true
not available on macOS
```

Not applicable on localhost.

5) DNS?

```
❯ dig +short localhost
127.0.0.1
```

Resolves.

### 2.3: Repair + re-verify

```
❯ kill $PID1
❯ sleep 1
❯ ADDR=:8080 go run . &
❯ sleep 1
❯ curl -s http://localhost:8080/health
{"notes":6,"status":"ok"}
```

### 2.4: Root cause

`bind: address already in use` — two instances on the same port.

### 2.5: Mini-postmortem

When you start services manually you can easily forget another process is already on the same port, and the second
instance just dies without a visible message. The systemic fix is a pre-start check — `lsof -i :8080 && exit 1` in the
launch script, or systemd with `ExecStartPre=`. In container environments the orchestrator handles this, but for manual
deploys you need either tooling or discipline. Knight Capital's deploy script also lacked a simple sanity check before
going to production.
