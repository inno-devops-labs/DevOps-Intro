# Lab 4 Submission

## Task 1 - Trace a Request End-to-End

### 1.1-1.2: Packet capture and decode

I start the docker container that I've created in lab 1, then I ran tcpdump on the loopback interface, fired one POST request, then stopped the capture and decoded it:

```bash
sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w lab4-trace.pcap &
TCPDUMP_PID=$!

curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}'

sudo kill $TCPDUMP_PID
wait $TCPDUMP_PID 2>/dev/null
sudo tcpdump -r lab4-trace.pcap -nn -A | tee lab4-trace.txt
```

Full decoded output is in `lab4-trace.txt`. Key parts annotated below.

**TCP three-way handshake:**

```
14:06:39.565539 IP6 ::1.40026 > ::1.8080: Flags [S]   <- SYN: client starts connection
14:06:39.565592 IP6 ::1.8080 > ::1.40026: Flags [S.]  <- SYN/ACK: server accepts
14:06:39.565627 IP6 ::1.40026 > ::1.8080: Flags [.]   <- ACK: connection established
```

**HTTP request:**

```
14:06:39.565856 IP6 ::1.40026 > ::1.8080: Flags [P.], length 175: HTTP: POST /notes HTTP/1.1
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.15.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

**HTTP response:**

```
14:06:39.567803 IP6 ::1.8080 > ::1.40026: Flags [P.], length 206: HTTP: HTTP/1.1 201 Created
HTTP/1.1 201 Created
Content-Type: application/json
Date: Fri, 12 Jun 2026 11:06:39 GMT
Content-Length: 93

{"id":5,"title":"trace me","body":"in flight","created_at":"2026-06-12T11:06:39.566932769Z"}
```

**Connection close:**

```
14:06:39.567992 IP6 ::1.40026 > ::1.8080: Flags [F.]  <- FIN: client done sending
14:06:39.568154 IP6 ::1.8080 > ::1.40026: Flags [F.]  <- FIN: server done sending
14:06:39.568175 IP6 ::1.40026 > ::1.8080: Flags [.]   <- ACK: connection fully closed
```

The traffic went over IPv6 loopback (::1) because curl picked IPv6 on this machine.

---

### 1.3: Five debugging commands

**1. What is listening on :8080?**

```bash
$ ss -tlnp | grep :8080
LISTEN 0  4096  0.0.0.0:8080  0.0.0.0:*
LISTEN 0  4096     [::]:8080     [::]:*
```

Port 8080 is bound on all interfaces (IPv4 and IPv6). No process name shown because Docker's proxy runs as root and I ran ss without sudo.

**2. Routes from the host:**

```bash
$ ip route show
default via 192.168.0.1 dev wlo1 proto dhcp src 192.168.0.144 metric 600
10.8.0.0/24 dev VPN proto kernel scope link src 10.8.0.5 metric 50
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1
192.168.0.0/24 dev wlo1 proto kernel scope link src 192.168.0.144 metric 600
```

Four routes: default via WiFi router, a VPN interface, the Docker bridge subnet (172.17.0.0/16 via docker0), and the local LAN.

**3. Reachability to localhost:**

```bash
$ mtr -rwc 5 localhost
Start: 2026-06-12T14:10:50+0300
HOST: fedora    Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.2   0.2   0.1   0.3   0.1
```

Single hop, 0% packet loss, average RTT 0.2 ms. Loopback is healthy.

**4. DNS check:**

```bash
$ dig +short example.com @1.1.1.1
172.66.147.243
104.20.23.154
```

DNS resolution works fine. Cloudflare resolver returned two A records.

**5. Service logs:**

```bash
$ journalctl --user -u quicknotes -n 20
-- No entries --
```

QuickNotes runs as a Docker container, not a systemd unit, so journald has nothing for it. Logs are available via `docker logs funny_lumiere`.

```
$ docker ps
CONTAINER ID   IMAGE              COMMAND          CREATED        STATUS        PORTS                                         NAMES
6af4b98778a8   quicknotes:local   "./quicknotes"   22 hours ago   Up 22 hours   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp   funny_lumiere


$ docker logs funny_lumiere
2026/06/12 10:59:31 quicknotes listening on :8080 (notes loaded: 4)
```

Logs show that quicknotes is up and running on port 8080.

---

### 1.4: What would I check first if QuickNotes returned 502?

A 502 means a proxy got a bad or no response from the upstream app. I would work outside-in through these steps. First, check if the process is still running at all with `docker ps` or `systemctl status quicknotes`. If it is gone, read the logs (`docker logs` or `journalctl -u quicknotes`) to find why it crashed. If the process is up, check whether it is actually listening with `ss -tlnp | grep 8080`. A live process that lost its port binding is a common failure after a restart. Next, try `curl http://localhost:8080/health` directly to bypass the proxy and confirm the app itself responds. If that returns 200 then the problem is in the proxy config, not the app. If it hangs or errors, the app is broken regardless of the proxy. After that I would check the firewall with `sudo iptables -L -n` or `sudo nft list ruleset` to rule out a rule that blocks traffic between the proxy and the backend. Finally, if a domain name is involved, `dig +short quicknotes.example.com` to confirm DNS still points to the right IP, because a stale DNS record after a server move is a classic cause of 502.

---

## Task 2 - Outside-In Debugging on a Broken Deploy

### 2.1: Run a broken instance

The app is already running as a Docker container (`funny_lumiere`) on host port 8080. I tried to start a second container mapped to the same port:

```bash
$ docker run -d -p 8080:8080 --name qn-broken quicknotes:local
docker: Error response from daemon: failed to set up container networking: driver failed
programming external connectivity on endpoint qn-broken: Bind for 0.0.0.0:8080 failed:
port is already allocated
exit: 125
```

The second instance failed to start. Root cause: `port is already allocated` - same as `bind: address already in use`.

### 2.2: Outside-in debugging chain

**Step 1: Is it running?**

```bash
$ ps -ef | grep quicknotes | grep -v grep
tend   1941692  ...  docker run -it -p 8080:8080 quicknotes:local
root   1941736  ...  ./quicknotes
```

Decision: one instance is running (the original). The second one never became a process because Docker rejected it before it could start.

**Step 2: Is it listening?**

```bash
$ ss -tlnp | grep 8080
LISTEN 0  4096  0.0.0.0:8080  0.0.0.0:*
LISTEN 0  4096     [::]:8080     [::]:*
```

Decision: port 8080 is already bound. Something is holding it, which is exactly why the second instance could not start.

**Step 3: Reachable from host?**

```bash
$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
200
```

Decision: the first instance is alive and responding. The port conflict only blocked the new deploy, not the existing one.

**Step 4: Firewall blocking?**

```bash
$ sudo iptables -L -n -v || sudo nft list ruleset || true
```

No blocking rules found. Traffic reaches the app fine. Firewall is not the issue here.

**Step 5: DNS?**

```bash
$ dig +short localhost
127.0.0.1
```

Decision: `localhost` resolves correctly to 127.0.0.1. DNS is not the problem.

### 2.3: Repair + re-verify

The broken container never actually started, so there is nothing to kill. I removed the failed container and confirmed the original instance still works:

```bash
$ docker rm qn-broken
qn-broken

$ docker ps
CONTAINER ID   IMAGE              COMMAND          CREATED        STATUS        PORTS                                         NAMES
6af4b98778a8   quicknotes:local   "./quicknotes"   22 hours ago   Up 22 hours   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp   funny_lumiere

$ curl -s http://localhost:8080/health
{"notes":5,"status":"ok"}
```

The service is healthy. In a real broken scenario the fix would be to stop the old instance first (`docker stop funny_lumiere`) and then start the new one.

### 2.4: Mini-postmortem

**Root cause:** `Bind for 0.0.0.0:8080 failed: port is already allocated`. A new deploy tried to bind to a port already held by the running instance.

**What is systemic:** The deploy script and the running service have no coordination. Each assumes it owns the port. This happens in any environment where the deployment tool does not stop the old instance before starting the new one, and it is hard to catch because from the outside the service looks fine (the old container keeps running).

**What tooling could prevent it:** A pre-deploy `ss -tlnp | grep 8080` would catch it immediately. In Docker, the fix is `docker stop` before `docker run`, or Docker Compose which owns the full container lifecycle automatically.
