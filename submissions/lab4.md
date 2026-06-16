# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

**Student:** Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + **WSL2 Ubuntu** (required for `tcpdump`, `ss`, `dig`)

---

## Task 1 — Trace a request end-to-end

### 1.1 Capture setup

_Terminal layout (all inside WSL):_

```bash
cd /mnt/c/Users/Selysecr/Desktop/DevOps/My_DevOps-Intro/DevOps-Intro/app
```

| Terminal | Command |
|----------|---------|
| A | `go run .` |
| B | `sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap` |
| C | `curl -v -X POST http://localhost:8080/notes -H 'Content-Type: application/json' -d '{"title":"trace me","body":"in flight"}'` |

### 1.2 Annotated capture (`lab4-trace.txt`)

_TODO — paste excerpts after running:_

```
sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt
```

| Phase | Packet evidence | Notes |
|-------|-----------------|-------|
| TCP handshake (SYN → SYN/ACK → ACK) | _TODO_ | |
| HTTP request (`POST /notes HTTP/1.1` + JSON body) | _TODO_ | |
| HTTP response (`HTTP/1.1 201 Created` + JSON) | _TODO_ | |
| Connection close (FIN / RST) | _TODO_ | |

### 1.3 Five debugging commands

**1. What's listening?**

```bash
ss -tlnp | grep :8080
```

```
_TODO output_
```

**2. Routes from host**

```bash
ip route show
```

```
_TODO output_
```

**3. Reachability (loopback)**

```bash
mtr -rwc 5 localhost
```

```
_TODO output_
```

**4. DNS works**

```bash
dig +short example.com @1.1.1.1
```

```
_TODO output_
```

**5. Logs (if service installed)**

```bash
journalctl --user -u quicknotes -n 20 || true
```

```
_TODO output_
```

### 1.4 If QuickNotes returned 502 — what to check first?

_TODO — one paragraph._

---

## Task 2 — Outside-in debugging on a broken deploy

### 2.1 Reproduce broken instance

```bash
cd app/
ADDR=:8080 go run . &
PID1=$!
sleep 1
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &
PID2=$!
sleep 2
ps -ef | grep "go run" | grep -v grep
```

**Bind error captured:**

```
_TODO — paste exact error from /tmp/qn-broken.log_
```

### 2.2 Outside-in chain

| Step | Command | Output | Decision |
|------|---------|--------|----------|
| 1 — process running? | `ps -ef \| grep quicknotes` | _TODO_ | _TODO_ |
| 2 — listening? | `ss -tlnp \| grep 8080` | _TODO_ | _TODO_ |
| 3 — reachable? | `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health` | _TODO_ | _TODO_ |
| 4 — firewall? | `sudo iptables -L -n -v` or `sudo nft list ruleset` | _TODO_ | _TODO_ |
| 5 — DNS? | `dig +short localhost` | _TODO_ | _TODO_ |

### 2.3 Repair + re-verify

```bash
kill $PID1
sleep 1
ADDR=:8080 go run . &
sleep 1
curl -s http://localhost:8080/health
```

```
_TODO — health response after fix_
```

### 2.4 Mini-postmortem (≤ 200 words)

_TODO — blameless: systemic cause + tooling that could prevent port conflicts._

---

## Bonus — TLS handshake (optional)

_Not started._

---

## Submission — Pull requests

| PR | URL |
|----|-----|
| **Course** (`feature/lab4` → `inno-devops-labs/main`) | _TODO_ |
| **Fork** (`feature/lab4` → `selysecr332/main`) | _TODO_ |

**Moodle:** submit both URLs before the deadline.

---

## Lab 4 completion checklist

### Task 1 (6 pts)

- [ ] `lab4-trace.pcap` / annotated `lab4-trace.txt`
- [ ] TCP handshake, HTTP req/resp, close identified
- [ ] Five debug commands with output
- [ ] 502 reflection paragraph

### Task 2 (4 pts)

- [ ] Broken deploy reproduced (`bind: address already in use`)
- [ ] Outside-in chain documented
- [ ] Repair verified
- [ ] Mini-postmortem written

### Submission

- [ ] Course PR opened
- [ ] Fork PR opened
- [ ] Both URLs on Moodle

### Bonus (2 pts)

- [ ] Not attempted
