# Cloudflare Quick Tunnel

Run the same release image locally:

```bash
docker run --rm --name quicknotes-lab10 \
  -p 8080:8080 \
  -e ADDR=:8080 \
  -e DATA_PATH=/data/notes.json \
  -e SEED_PATH=/app/seed.json \
  -v quicknotes-lab10-data:/data \
  ghcr.io/whynotgm/devops-intro/quicknotes:v0.1.0
```

In another terminal, expose it through a no-account quick tunnel:

```bash
cloudflared tunnel --url http://localhost:8080
```

Verify locally and from a different network:

```bash
curl -v http://localhost:8080/health
curl -v https://<random>.trycloudflare.com/health
```

Measure warm latency:

```bash
hyperfine --warmup 5 --runs 50 \
  "curl -fsS -o /dev/null https://<random>.trycloudflare.com/health"
```

Quick tunnel URLs are intentionally ephemeral. Restarting `cloudflared` creates a new public URL.
