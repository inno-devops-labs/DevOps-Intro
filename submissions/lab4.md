# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

## Task 1 — Trace a Request End-to-End

### Packet Capture

The capture was performed using tcpdump on the loopback interface while sending a POST request to the QuickNotes application running on port 8080. The captured packets reveal the complete TCP and HTTP conversation.

**TCP Three-Way Handshake:**

```
20:17:01.030154 IP 127.0.0.1.41476 > 127.0.0.1.8080: Flags [S], seq 1141123524
20:17:01.030169 IP 127.0.0.1.8080 > 127.0.0.1.41476: Flags [S.], seq 885947186, ack 1141123525
20:17:01.030177 IP 127.0.0.1.41476 > 127.0.0.1.8080: Flags [.], ack 1
```

**HTTP POST Request:**

```
POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/7.81.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
```

**HTTP 201 Response:**

```
HTTP/1.1 201 Created
Content-Type: application/json
Date: Tue, 16 Jun 2026 17:17:01 GMT
Content-Length: 93

{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T17:17:01.030364093Z"}
```

**Connection Close:**

```
20:17:01.030628 IP 127.0.0.1.41476 > 127.0.0.1.8080: Flags [F.], seq 176, ack 207
20:17:01.030654 IP 127.0.0.1.8080 > 127.0.0.1.41476: Flags [F.], seq 207, ack 177
20:17:01.030666 IP 127.0.0.1.41476 > 127.0.0.1.8080: Flags [.], ack 208
```

![lab4-trace.txt capture](image.png)

### System State Verification

The following commands confirmed the system state: ss -tlnp | grep :8080 showed the process listening on port 8080 with PID 11533. ip route show displayed the routing table with loopback, default route via 192.168.0.1, and Docker bridge networks. mtr -rwc 5 localhost showed 0% packet loss with 0.1 ms latency. dig +short example.com @1.1.1.1 returned 8.47.69.0 confirming DNS resolution. journalctl --user -u quicknotes -n 20 returned no entries as the service was running manually.

![Five debugging commands](image-1.png)

### 502 Error Diagnosis

For a 502 error, the diagnostic approach would follow an outside-in progression: verify the process is running with ps, confirm the port is listening with ss, test local connectivity with curl, and check application logs for startup failures or crashes. If the process is running but not listening, this indicates a bind failure or runtime crash. If listening but unreachable, firewall rules or network policies are likely blocking traffic.

## Task 2 — Outside-In Debugging on a Broken Deploy

### Reproducing the Failure

A second instance was started while the first was already bound to port 8080, producing the following error:

```
listen tcp :8080: bind: address already in use
```

![Bind error](image-2.png)

### Debugging Chain

The outside-in chain produced the following findings: ps -ef showed no go run processes (the first instance was running from a previous session). ss -tlnp showed port 8080 in LISTEN state owned by PID 11533. curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health returned 200, confirming the instance was functional. dig +short localhost returned 127.0.0.1. The error log cat /tmp/qn-broken.log confirmed the bind failure.

![Debugging commands](image-3.png)

### Root Cause

The failure occurred because the second process attempted to bind to a port already occupied by the first instance (PID 11533). The Go runtime's net.Listen returns EADDRINUSE immediately, causing process termination with exit status 1.

### Prevention

This issue could be prevented through PID file management, pre-flight port checks, service supervisors like systemd, or automatic cleanup of stale processes. The error itself is clear and actionable, but automation would improve the development workflow.

![Health check after fix](image-4.png)
