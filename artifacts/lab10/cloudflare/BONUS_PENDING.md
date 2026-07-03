# Lab 10 Cloudflare Bonus Pending

Status: not completed / not claimed yet.

Reason:
- QuickNotes local container works on http://127.0.0.1:8080/health.
- Cloudflare Quick Tunnel can request a temporary trycloudflare.com URL.
- However, cloudflared never reaches "Registered tunnel connection".
- Attempts failed with Cloudflare edge transport errors such as TLS handshake EOF and HTTP/2 connectivity precheck failures.
- Because the tunnel did not register and public /health was not verified from an outside network, the bonus must not be claimed yet.

Resume checklist:
1. Use an unrestricted network, phone hotspot, or VPN route that allows Cloudflare Tunnel edge transport.
2. Start local container:
   docker run -d --name quicknotes-cloudflare -p 8080:8080 ghcr.io/tivdzualubem/devops-intro/quicknotes:v0.1.0
3. Start tunnel:
   GODEBUG=http2client=0 cloudflared tunnel --edge-ip-version 4 --protocol http2 --url http://localhost:8080
4. Continue only after log shows:
   Registered tunnel connection
5. Verify /health from a different device/network.
6. Run 50 warm requests and compute p50/p95.
7. Add Cloudflare comparison to submissions/lab10.md.
