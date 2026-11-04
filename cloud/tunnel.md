# Quick tunnel

The client is pinned to **cloudflared 2026.10.7**. It was obtained from the
[official release](https://github.com/cloudflare/cloudflared/releases/tag/2026.10.7).

Run the published image locally with disposable writable storage:

```sh
docker run -d --name quicknotes-lab10 -p 127.0.0.1:8081:8080 ghcr.io/4rni4ka/devops-intro/quicknotes:v0.1.3
cloudflared tunnel --url http://127.0.0.1:8081 --protocol http2 --no-autoupdate
```

The initial local control used the Lab 9 build. The final independent-network
comparison uses the GHCR v0.1.3 image, with the same digest deployed on Render.
Its quick URL is
`https://assured-opposed-leather-belief.trycloudflare.com` and will expire when
the tunnel process stops. Do not treat this URL as a permanent deployment.
The local benchmark uses hyperfine **2.0.0**, five warmups and 50 measured runs:

```powershell
hyperfine --warmup 5 --runs 50 --export-json tunnel-local-hyperfine.json 'curl.exe --fail --silent --show-error --max-time 120 --output NUL https://assured-opposed-leather-belief.trycloudflare.com/health'
```

The initial network diagnostics reported UDP/QUIC failure and partial regional
TCP reachability. HTTP/2 nevertheless served the public endpoint successfully;
no firewall or certificate validation setting was changed.

For independent-network verification and measurements, run:

```sh
gh workflow run tunnel-probe.yml --repo 4rni4ka/DevOps-Intro --ref main -f url=https://assured-opposed-leather-belief.trycloudflare.com -f render_url=https://quicknotes-4rni4ka.onrender.com
```

The hosted runner verifies JSON from `/health` without authentication and runs
50 hyperfine measurements against each origin. Its log includes the full timing JSON. Keep that log
as evidence; a benchmark from the tunnel's own host alone does not fulfill the
different-machine requirement. Hyperfine measures the whole curl process,
including process startup, DNS, TCP/TLS and response transfer, rather than only
server handler time. Percentiles are median and nearest-rank p95 of measured
wall times; warmups are excluded. Do not run this benchmark while measuring
Render idle/cold cycles, because the requests would reset its inactivity timer.
