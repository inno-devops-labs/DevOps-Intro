# Cloudflare Tunnel Bonus

Status: pending / not claimed.

We will return to this bonus after finishing Labs 11-12.

Current result:
- QuickNotes works locally on http://127.0.0.1:8080/health.
- cloudflared can request temporary trycloudflare.com hostnames.
- The tunnel did not reach Registered tunnel connection.
- The observed failures were Cloudflare edge transport errors such as TLS handshake EOF and HTTP/2 connectivity precheck failures.

Because the tunnel did not register and /health was not verified from a different network, this bonus is not claimed in submissions/lab10.md.

Resume later:
1. Use a network/VPN route that allows Cloudflare Tunnel edge transport.
2. Start the released image locally.
3. Start cloudflared quick tunnel.
4. Continue only after the log shows Registered tunnel connection.
5. Verify /health from another network.
6. Run 50 warm requests and compute p50/p95.
7. Update submissions/lab10.md.
