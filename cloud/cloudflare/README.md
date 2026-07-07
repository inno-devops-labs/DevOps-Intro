# Cloudflare Tunnel Bonus Notes

The bonus uses a Cloudflare quick tunnel, so no Cloudflare account, domain, or
secret token is stored in this repository. Quick tunnels produce ephemeral
`trycloudflare.com` URLs that change on every restart.

## Run QuickNotes locally

```bash
docker run --rm --name quicknotes-lab10 -p 8080:8080 \
  ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
```

If the GHCR image is not public yet, use the local image while waiting for the
GitHub package visibility step:

```bash
docker build -t quicknotes:lab10 ./app
docker run --rm --name quicknotes-lab10 -p 8080:8080 quicknotes:lab10
```

## Start a quick tunnel

```bash
cloudflared tunnel --url http://localhost:8080 --protocol http2 --no-autoupdate
```

The `--protocol http2` flag avoids relying on outbound QUIC/UDP. In this lab
environment, the first QUIC quick tunnel registered but the generated hostname
did not resolve reliably; forcing HTTP/2 produced a stable reachable quick URL.

Copy the generated `https://<random>.trycloudflare.com` URL and verify it from a
different network, for example a phone on cellular data:

```bash
curl -v https://<random>.trycloudflare.com/health
```

## Measure warm latency

```bash
cloud/scripts/measure-curl-latency.sh https://<random>.trycloudflare.com/health 50
```
