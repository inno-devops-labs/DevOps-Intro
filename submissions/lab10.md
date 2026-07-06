# Lab 10 Submission

## Task 1

### GitHub Actions Release Workflow

```yaml
name: Release to GHCR

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: docker/login-action@343f7c4344506bcbf9b4de18042ae17996df046d
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - id: meta
        uses: docker/metadata-action@96383f45573cb7f253c731d3b3ab81c87ef81934
        with:
          images: ghcr.io/${{ github.repository }}/quicknotes
          tags: |
            type=semver,pattern={{version}}
            type=raw,value=latest

      - uses: docker/build-push-action@0565240e2d4ab88bba5387d719585280857ece09
        with:
          context: ./app
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

### Evidence of successful pull:
```PlaintextPS 
C:\Users\Alina\PycharmProjects\DevOps-Intro> docker pull ghcr.io/alinkapestoletik/devops-intro/quicknotes:0.1.2

0.1.2: Pulling from alinkapestoletik/devops-intro/quicknotes
1c193acf1cd1: Pull complete 
5b3013706a46: Pull complete 
8029962f461f: Pull complete 
9cd8e28f1c22: Pull complete 
9d2753d762cc: Pull complete 
2780920e5dbf: Pull complete 
7c12895b777b: Pull complete 
3214acf345c0: Pull complete 
52630fc75a18: Pull complete 
dd64bf2dd177: Pull complete 
b839dfae01f6: Pull complete 
411e1c946a02: Pull complete 
77964957095d: Pull complete 
1faf7e1089a7: Pull complete 
Digest: sha256:9b9a9d7942165872812b52135a29fd104bc44d95817b3380bc9cf23642750ea7
Status: Downloaded newer image for ghcr.io/alinkapestoletik/devops-intro/quicknotes:0.1.2
ghcr.io/alinkapestoletik/devops-intro/quicknotes:0.1.2
```
### Green CI url run

https://github.com/alinkaPestoletik/DevOps-Intro/actions/runs/28615390336/job/84857832912

### Design Questions
**a) OIDC vs GITHUB_TOKEN — when to reach for OIDC?**
```
GITHUB_TOKEN is sufficient for interacting with GitHub's own ecosystem. You reach for OIDC when you need to authenticate with external cloud providers (like AWS, GCP, or Azure) from GitHub Actions. OIDC provides short-lived, dynamically generated credentials, meaning you don't have to store long-lived static secrets in GitHub, eliminating the risk of credential leakage.
```
**b) :latest tag vs :v0.1.0 immutable tag**
```
Shipping :latest alongside the immutable tag is to provide a floating pointer for users or systems that always want the most recent stable version without tracking specific version numbers. However, production deployments should always pin to the immutable :v0.1.0 tag to guarantee reproducibility and ensure safe rollbacks.
```
**c) packages: write scope only** 
```
It follows the principle of least privilege. If a malicious pull request or compromised third-party action compromises the CI runner, the attacker only gains permission to modify packages. If the scope was write, the attacker could rewrite repository code, modify releases, or read sensitive secrets. Narrowing the scope minimizes the blast radius.
```

## Task 2 
### URL: 
https://alinapestova-quicknotes.hf.space

### Evidence of public reachability
```
* Host alinapestova-quicknotes.hf.space:443 was resolved.
* IPv6: (none)
* IPv4: 52.208.30.199, 108.133.38.41, 52.48.128.222
*   Trying 52.208.30.199:443...
* Connected to alinapestova-quicknotes.hf.space (52.208.30.199) port 443
* schannel: disabled automatic use of client certificate
* ALPN: curl offers http/1.1
* ALPN: server accepted http/1.1
* using HTTP/1.x
> GET /health HTTP/1.1
> Host: alinapestova-quicknotes.hf.space
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Date: Thu, 02 Jul 2026 20:11:50 GMT
< Content-Type: application/json
< Content-Length: 26
< Connection: keep-alive
< x-proxied-host: http://10.112.54.224
< x-proxied-replica: glcyac3i-4n82t
< x-proxied-path: /health
< link: <https://huggingface.co/spaces/alinapestova/quicknotes>;rel="canonical"
< x-request-id: jgPQR9
< vary: origin, access-control-request-method, access-control-request-headers
< access-control-expose-headers: *
< 
{"notes":0,"status":"ok"}
* Connection #0 to host alinapestova-quicknotes.hf.space left intact
```

### Hugging Face Space Files
README.md
```
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
---
# QuickNotes Space
This is a hosted instance of QuickNotes.
```
Dockerfile
```
FROM ghcr.io/alinkapestoletik/devops-intro/quicknotes:0.1.2
```
### Latency Measurements
**Warm p50:** 91ms (0.091s)

**Cold start 1:** 13.54 seconds

**Cold start 2:** 12.81 seconds

**Cold start 3:** 14.10 seconds

### Design Questions

**d) HF Spaces "sleep" vs Cloud Run "scale to zero"**
```
Cloud Run optimizes for production enterprise traffic, utilizing advanced micro-VMs and pre-warmed networking to achieve cold starts in ~1-2 seconds. Hugging Face Spaces optimizes for free community hosting where resources are heavily shared to keep costs at zero. Waking up an HF space involves re-provisioning a heavy machine and pulling images on slower infrastructure, resulting in cold starts taking tens of seconds.
```
**e) Why does the Space need app_port: 8080?**
```
Since QuickNotes explicitly listens on 8080, we must override default to route incoming HTTP traffic correctly.
```
**f) Trade-off of pulling image from ghcr.io vs building inside the Space** 
```
Pulling the pre-built image from ghcr.io guarantees artifact immutability—the exact same code tested in your CI is running in production. Building the Dockerfile inside the Space forces the platform to re-download dependencies and re-compile the Go app, which wastes time on every startup, risks breaking if a remote dependency goes down, and makes debugging difficult if the HF build environment differs from your CI runner.
```

## Bonus Task

### Comparison Table

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50                 |               91ms | *Blocked by ISP (API Timeout)* |
| Warm p95                 |              110ms | *Blocked by ISP (API Timeout)* |
| Cold start             |             ~13.5s |  N/A (continuously local)          |
| Public URL stability   |             stable |                ephemeral on restart |
| Cost                   |               free |                                 free |

> **Note:** The `cloudflared` quick tunnel failed to provision a URL due to a context deadline exceeded error.

### Design Questions

**g) Architectural difference?**
```
Both provide cloud-like accessibility, but technically HF is Compute as a Service hosted in a remote datacenter, whereas Cloudflare Tunnel is an Edge overlay network. To the end-user, the distinction doesn't matter - they just hit a public URL and get JSON back. Here, Cloudflare provides the reliable edge ingress, even if the compute is running locally.
```
**h) Latency dominator**
```
HF Spaces: The warm latency is dominated by geographic network routing to the HF datacenter and their internal load balancer overhead.
Cloudflare Tunnel: The latency is dominated by your local ISP's uplink speed and the physical distance between your laptop and the nearest Cloudflare Edge PoP.
```
**i) When is Cloudflare Tunnel the right (or wrong) production pick?**
```
Right pick: Exposing internal on-prem tools without opening firewall ports, local webhooks for dev testing, or IoT edge deployments.
Wrong pick: High-availability user-facing production applications. If the tunnel runs on your laptop and your laptop goes to sleep or your home Wi-Fi drops, the service goes down instantly.
```