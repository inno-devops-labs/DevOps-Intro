# Lab 10 teardown

## Codespaces

Keep the graded Codespace available until grading. After grading, stop and delete it:

```bash
gh codespace stop -c quicknotes-lab10-verified-xj5jj5797p4c9qr7
gh codespace delete -c quicknotes-lab10-verified-xj5jj5797p4c9qr7
```

The earlier setup Codespace `quicknotes-lab10-x5r7p5x9wwg3vjrp` is already stopped. It can also be deleted after grading. A stopped Codespace still uses storage quota, so deletion is appropriate when no longer needed.

## Cloudflare

Stop the `cloudflared tunnel --protocol http2 --url http://127.0.0.1:18081` process after the bonus measurements. A Quick Tunnel URL expires when the process stops.

## Local Docker

Remove only the Lab 10 container:

```bash
docker rm -f quicknotes-lab10-tunnel
```

The local host port is `127.0.0.1:18081` because port 8080 was occupied by another service. The container itself still listens on 8080.

## GHCR and tag

Leave `ghcr.io/sanyalikeit/devops-intro/quicknotes:v0.1.1` public and leave the signed `v0.1.1` tag on `origin` until grading.
