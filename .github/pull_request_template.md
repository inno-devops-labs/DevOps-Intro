## Goal
 Trace a live HTTP request end-to-end with tcpdump, walk an outside-in debug chain on a broken deploy, and decode a TLS 1.3 handshake via a Caddy reverse proxy.

## Changes:
 - Added `submissions/lab4.md` with annotated packet capture, five debugging command outputs, 502 reflection, outside-in debug chain, blameless postmortem, and TLS handshake decode
 - Added `lab4-trace.txt` with full tcpdump output of the POST /notes request captured on loopback
- 

## Testing:
 - Captured TCP three-way handshake, HTTP POST /notes request, 201 Created response, and graceful FIN teardown in lab4-trace.pcap
 - Ran all five debugging commands (ss, ip route, mtr, dig, journalctl) and documented output + reasoning
 - Reproduced port conflict (bind: address already in use) by launching two QuickNotes instances on :8080
 - Walked outside-in chain (ps -> ss -> curl -> iptables -> dig), identified root cause, killed conflicting process, and re-verified health
 - Captured TLS 1.3 handshake via Caddy reverse proxy on :8443; confirmed TLS_AES_128_GCM_SHA256 / X25519 negotiation
 - Extracted full three-cert chain (leaf + ECC intermediate + ECC root) with openssl s_client -servername localhost

## Checklist:
 - [x] Title is a clear sentence (≤ 70 chars)
 - [x] Commits are signed (`git log --show-signature`)
 - [x] `submissions/lab4.md` updated
 - [x] `lab4-trace.txt` included alongside submission
