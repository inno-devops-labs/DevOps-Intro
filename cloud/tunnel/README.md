# Cloudflare Tunnel quick runbook

This bonus path exposes the same release image through a no-account quick tunnel.

Run QuickNotes locally:

```powershell
docker run --rm --name quicknotes-lab10-tunnel `
  -p 8080:8080 `
  -v quicknotes-lab10-data:/data `
  ghcr.io/bearax/devops-intro/quicknotes:v0.1.0
```

Start the quick tunnel:

```powershell
cloudflared tunnel --url http://localhost:8080
```

Verify from another network:

```powershell
curl https://<random>.trycloudflare.com/health
```

Measure warm latency with `hyperfine`:

```powershell
hyperfine --warmup 5 --runs 50 "curl -s -o NUL https://<random>.trycloudflare.com/health"
```

Quick tunnel URLs are ephemeral. Restarting `cloudflared` creates a new public URL.
