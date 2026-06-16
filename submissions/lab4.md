\# Lab 4 Submission



\## Task 1: Trace a Request End-to-End



\### QuickNotes request



I started QuickNotes locally on port `8080` and captured one request to `POST /notes` using `tcpdump` on the loopback interface.



The request was sent with:



```bash

curl -v -X POST http://localhost:8080/notes \\

&#x20; -H 'Content-Type: application/json' \\

&#x20; -d '{"title":"trace me","body":"in flight"}'

```



The application responded successfully:



```text

POST /notes HTTP/1.1

HTTP/1.1 201 Created

{"id":6,"title":"trace me","body":"in flight","created\_at":"2026-06-16T16:46:12.62574443Z"}

```



This confirms that the request reached QuickNotes, QuickNotes created the note, and the server returned a valid JSON response with status `201 Created`.



\---



\## Annotated Packet Capture



The full decoded capture is included in:



```text

submissions/lab4-assets/lab4-trace.txt

```



\### TCP three-way handshake



The TCP connection starts with the standard three-way handshake:



```text

19:46:12.625388 IP 127.0.0.1.39140 > 127.0.0.1.8080: Flags \[S], seq 4277809752, win 65495, options \[mss 65495,sackOK,TS val 2900709604 ecr 0,nop,wscale 7], length 0

19:46:12.625400 IP 127.0.0.1.8080 > 127.0.0.1.39140: Flags \[S.], seq 2244450212, ack 4277809753, win 65483, options \[mss 65495,sackOK,TS val 2900709604 ecr 2900709604,nop,wscale 7], length 0

19:46:12.625409 IP 127.0.0.1.39140 > 127.0.0.1.8080: Flags \[.], ack 1, win 512, options \[nop,nop,TS val 2900709604 ecr 2900709604], length 0

```



Annotation:



\* `SYN`: the client starts a TCP connection to `127.0.0.1:8080`.

\* `SYN/ACK`: the QuickNotes server accepts and acknowledges the connection.

\* `ACK`: the client confirms the connection is established.

\* After this point, HTTP data can be sent over the TCP connection.



\### HTTP request



The HTTP request line and body appear in the capture:



```text

19:46:12.625606 IP 127.0.0.1.39140 > 127.0.0.1.8080: Flags \[P.], seq 1:176, ack 1, win 512, options \[nop,nop,TS val 2900709604 ecr 2900709604], length 175: HTTP: POST /notes HTTP/1.1



POST /notes HTTP/1.1

Host: localhost:8080

User-Agent: curl/7.82.0

Accept: \*/\*

Content-Type: application/json

Content-Length: 39



{"title":"trace me","body":"in flight"}

```



Annotation:



This is the application-layer request. The client sends a `POST` request to `/notes` with a JSON body. The body contains the title and body of the note that should be created.



\### HTTP response



The server response appears in the capture:



```text

19:46:12.631249 IP 127.0.0.1.8080 > 127.0.0.1.39140: Flags \[P.], seq 1:206, ack 176, win 512, options \[nop,nop,TS val 2900709610 ecr 2900709604], length 205: HTTP: HTTP/1.1 201 Created



HTTP/1.1 201 Created

Content-Type: application/json

Date: Tue, 16 Jun 2026 16:46:12 GMT

Content-Length: 92



{"id":6,"title":"trace me","body":"in flight","created\_at":"2026-06-16T16:46:12.62574443Z"}

```



Annotation:



QuickNotes returned `201 Created`, which means the note was successfully created. The response body contains the generated note ID, original title/body, and creation timestamp.



\### Connection close



The capture ends with the TCP connection being closed:



```text

19:46:12.631448 IP 127.0.0.1.39140 > 127.0.0.1.8080: Flags \[F.], seq 176, ack 206, win 512, options \[nop,nop,TS val 2900709610 ecr 2900709610], length 0

19:46:12.631508 IP 127.0.0.1.8080 > 127.0.0.1.39140: Flags \[F.], seq 206, ack 177, win 512, options \[nop,nop,TS val 2900709610 ecr 2900709610], length 0

19:46:12.631522 IP 127.0.0.1.39140 > 127.0.0.1.8080: Flags \[.], ack 207, win 512, options \[nop,nop,TS val 2900709610 ecr 2900709610], length 0

```



Annotation:



The client sends `FIN`, the server responds with `FIN`, and the client sends the final `ACK`. This is the normal TCP connection teardown after the HTTP exchange completed.



\---



\## Five Debugging Commands



\### 1. Listening socket



Command:



```bash

ss -tlnp | grep :8080

```



Output:



```text

$ ss -tlnp | grep :8080

LISTEN 0      4096                \*:8080            \*:\*    users:(("quicknotes",pid=4337,fd=3))

```



Decision:



This confirms that QuickNotes is listening on TCP port `8080`. If this command returned no output, then nothing would be bound to the expected port.



\---



\### 2. Host routes



Command:



```bash

ip route show

```



Output:



```text

$ ip route show

default via 172.19.128.1 dev eth0 proto kernel

172.19.128.0/20 dev eth0 proto kernel scope link src 172.19.130.184

```



Decision:



This shows the host routing table inside WSL. The default route goes through `eth0`, while the QuickNotes request to `localhost` stays on loopback and does not need the external route.



\---



\### 3. Reachability to localhost



Command:



```bash

mtr -rwc 5 localhost

```



Output:



```text

$ mtr -rwc 5 localhost

Start: 2026-06-16T19:47:44+0300

HOST: DESKTOP-I0DHHPT Loss%   Snt   Last   Avg  Best  Wrst StDev

&#x20; 1.|-- localhost        0.0%     5    0.0   0.0   0.0   0.0   0.0

```



Decision:



This confirms that `localhost` is reachable with no packet loss. Since this is loopback traffic, the path is one hop and does not depend on the external network.



\---



\### 4. DNS check



Command:



```bash

dig +short example.com @1.1.1.1

```



Output:



```text

$ dig +short example.com @1.1.1.1

104.20.23.154

172.66.147.243

```



Decision:



This verifies that DNS resolution works through the resolver `1.1.1.1`. It is not directly required for `localhost`, but it confirms that DNS tools and outbound name resolution are working.



\---



\### 5. User service logs



Command:



```bash

journalctl --user -u quicknotes -n 20 || true

```



Output:



```text

$ journalctl --user -u quicknotes -n 20 || true

\-- No entries --

```



Decision:



This checks whether QuickNotes has user-level systemd logs. In my run, QuickNotes was started manually with `go run .`, so a missing `quicknotes` user service log is expected and not itself a failure.



\---



\## If QuickNotes Returned 502



If QuickNotes returned `502 Bad Gateway`, I would first check the component in front of QuickNotes, such as a reverse proxy, because `502` usually means the proxy could not successfully talk to the upstream service. I would verify whether QuickNotes is running with `ps`, whether it is listening on the expected port with `ss -tlnp`, and whether it is reachable directly with `curl http://localhost:8080/health`. If the direct health check works, I would inspect the proxy configuration and proxy logs. If the direct health check fails, I would debug the QuickNotes process, port binding, firewall rules, and application logs.



\---



\# Task 2: Outside-In Debugging on a Broken Deploy



\## Broken Instance Reproduction



I reproduced the broken deployment by starting one QuickNotes process on `:8080`, then trying to start a second QuickNotes process on the same address.



Commands:



```bash

cd app

ADDR=:8080 go run . \&

PID1=$!

sleep 1



ADDR=:8080 go run . 2>\&1 | tee ../submissions/lab4-assets/qn-broken.log \&

PID2=$!

sleep 2



ps -ef | grep "go run" | grep -v grep

```



Captured error:



```text

2026/06/16 19:48:27 quicknotes listening on :8080 (notes loaded: 6)

2026/06/16 19:48:28 quicknotes listening on :8080 (notes loaded: 6)

2026/06/16 19:48:28 listen: listen tcp :8080: bind: address already in use

exit status 1

```



Root cause:



```text

listen tcp :8080: bind: address already in use

```



The second QuickNotes instance failed because the first instance was already bound to TCP port `8080`.



\---



\## Outside-In Debugging Chain



\### 1. Is a process running?



Command:



```bash

ps -ef | grep quicknotes

```



Output:



```text

$ ps -ef | grep quicknotes

root        4535    4460  0 19:48 pts/0    00:00:00 /root/.cache/go-build/01/01b36d0cffeef160fa8af2f501e7375bd20c7b28a5467c110d6e43fef651f8f2-d/quicknotes

```



Decision:



This confirms that a QuickNotes process exists. Since the process is running, the next step is to check whether it is bound to the expected port.



\---



\### 2. Is anything listening on port 8080?



Command:



```bash

ss -tlnp | grep 8080

```



Output:



```text

$ ss -tlnp | grep 8080

LISTEN 0      4096                \*:8080            \*:\*    users:(("quicknotes",pid=4535,fd=3))

```



Decision:



This confirms that a process named `quicknotes` is listening on port `8080`. This explains why the second instance could not bind to the same port.



\---



\### 3. Is the service reachable from the host?



Command:



```bash

curl -s -o /dev/null -w "%{http\_code}\\n" http://localhost:8080/health

```



Output:



```text

$ curl -s -o /dev/null -w "%{http\_code}\\n" http://localhost:8080/health

200

```



Decision:



This confirms that something is serving HTTP traffic on `localhost:8080`. The existing instance is healthy, but the new instance failed to start because the port was already occupied.



\---



\### 4. Is a firewall blocking traffic?



Command:



```bash

sudo iptables -L -n -v 2>/dev/null || sudo nft list ruleset 2>/dev/null || true

```



Output:



```text

$ sudo iptables -L -n -v 2>/dev/null || sudo nft list ruleset 2>/dev/null || true

```



Decision:



This produced no blocking rule output. Since the service is reachable and returns HTTP `200`, the firewall is not the cause of the failure.



\---



\### 5. Does DNS resolve localhost?



Command:



```bash

dig +short localhost

```



Output:



```text

$ dig +short localhost

127.0.0.1

```



Decision:



This confirms that `localhost` resolves to `127.0.0.1`. DNS or host resolution is not the cause of the issue.



\---



\## Repair and Re-Verification



I killed the conflicting QuickNotes process and restarted QuickNotes on port `8080`.



Commands:



```bash

pkill -f "go run ." || true

pkill -f quicknotes || true

sleep 1



cd app

ADDR=:8080 go run . \&

PID\_FIXED=$!

sleep 1



curl -s http://localhost:8080/health

```



Output:



```text

{"notes":6,"status":"ok"}

```



After removing the conflicting process, QuickNotes was able to bind to port `8080` and respond to the health check.



\---



\## Mini-Postmortem



The failure was caused by a port conflict: one QuickNotes instance was already listening on `:8080`, so a second instance could not bind to the same address. This is a systemic deployment problem, not an individual mistake, because deployment scripts and service managers should prevent duplicate instances from silently competing for the same port. Better tooling would include systemd unit management, pre-flight port checks, health checks, and clearer startup failure logging. A deployment pipeline should also verify that the new process actually became healthy before treating the deployment as successful. This would turn the failure from a manual debugging exercise into an automatically detected startup error.



\---



\## Files Included



```text

submissions/lab4.md

submissions/lab4-assets/lab4-trace.pcap

submissions/lab4-assets/lab4-trace.txt

submissions/lab4-assets/curl-post.txt

submissions/lab4-assets/ss-8080.txt

submissions/lab4-assets/ip-route.txt

submissions/lab4-assets/mtr-localhost.txt

submissions/lab4-assets/dig-example.txt

submissions/lab4-assets/journalctl-quicknotes.txt

submissions/lab4-assets/qn-broken.log

submissions/lab4-assets/go-run-processes.txt

submissions/lab4-assets/outsidein-1-process.txt

submissions/lab4-assets/outsidein-2-listening.txt

submissions/lab4-assets/outsidein-3-health.txt

submissions/lab4-assets/outsidein-4-firewall.txt

submissions/lab4-assets/outsidein-5-dns.txt

submissions/lab4-assets/repair-health.txt

```



