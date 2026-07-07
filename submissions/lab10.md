# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud

## Overview

This lab ships QuickNotes as a real public service. A signed Git tag triggers GitHub Actions, the workflow builds the QuickNotes Docker image from `app/`, pushes it to GitHub Container Registry, and tags it with both the release version and `latest`.

The same released image is then deployed to Hugging Face Spaces using the Docker SDK. For the bonus, the same local QuickNotes service is exposed through Cloudflare Tunnel and compared with the hosted Hugging Face deployment.

---

## Task 1 — CI-Automated Push to GHCR

### Release workflow

Workflow file:

```text
.github/workflows/release.yml
```

The workflow triggers on Git tags matching `v*`, builds the image from `app/`, and pushes it to GHCR with both the immutable release tag and `latest`.

```yaml
name: Release QuickNotes Image

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

env:
  IMAGE_NAME: ghcr.io/mysteri0k1ng/devops-intro/quicknotes

jobs:
  build-and-push:
    name: Build and push QuickNotes image
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@8d2750c68a42422c14e847fe6c8ac0403b4cbd6f

      - name: Log in to GHCR
        uses: docker/login-action@c94ce9fb468520275223c153574b00df6fe4bcc9
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push image
        uses: docker/build-push-action@10e90e3645eae34f1e60eeb005ba3a3d33f178e8
        with:
          context: ./app
          push: true
          platforms: linux/amd64
          tags: |
            ${{ env.IMAGE_NAME }}:${{ github.ref_name }}
            ${{ env.IMAGE_NAME }}:latest
```

The actual repository workflow uses 40-character SHA pins for all third-party actions. The first release attempts failed because of an incorrect action pin and then an incorrect GHCR owner spelling. After fixing both issues, the release workflow succeeded for tag `v0.1.2`.

### Release tag

```text
v0.1.2
```

### GHCR image

```text
ghcr.io/mysteri0k1ng/devops-intro/quicknotes:v0.1.2
ghcr.io/mysteri0k1ng/devops-intro/quicknotes:latest
```

### Clean pull evidence

Commands:

```bash
docker pull ghcr.io/mysteri0k1ng/devops-intro/quicknotes:v0.1.2
docker pull ghcr.io/mysteri0k1ng/devops-intro/quicknotes:latest
```

Output excerpt:

```text
v0.1.2: Pulling from mysteri0k1ng/devops-intro/quicknotes
Digest: sha256:6e4d4b9603afbeaca8a1b23cb7b1f949d39b43495bd217eb0ae2a513f01bb8141
Status: Downloaded newer image for ghcr.io/mysteri0k1ng/devops-intro/quicknotes:v0.1.2
ghcr.io/mysteri0k1ng/devops-intro/quicknotes:v0.1.2

latest: Pulling from mysteri0k1ng/devops-intro/quicknotes
Digest: sha256:6e4d4b9603afbeaca8a1b23cb7b1f949d39b43495bd217eb0ae2a513f01bb8141
Status: Downloaded newer image for ghcr.io/mysteri0k1ng/devops-intro/quicknotes:latest
ghcr.io/mysteri0k1ng/devops-intro/quicknotes:latest
```

This confirms that both the immutable release tag and `latest` are pullable.

---

## Task 1 — Design Questions

### a) OIDC vs `GITHUB_TOKEN`

For pushing to GHCR from the same repository, `GITHUB_TOKEN` with `packages: write` is enough because the workflow only needs to publish a package owned by the same GitHub project. I would use OIDC when the workflow needs to authenticate to an external cloud provider such as AWS, GCP, or Azure without storing long-lived cloud credentials in GitHub secrets. OIDC gives short-lived identity-based credentials scoped to the workflow run. This reduces the risk of leaked static credentials and allows the cloud provider to verify which repository, branch, or tag is requesting access.

### b) `latest` tag vs immutable version tag

The immutable tag such as `v0.1.2` is used for reproducible deployments because it points to a specific release. The `latest` tag is mutable, so it should not be the only reference for production rollouts. However, it is still useful as a convenience tag for humans, demos, and simple consumers who want the newest stable image without checking the exact version. In production, I would deploy the immutable tag, but still publish `latest` as a pointer to the newest release.

### c) Why `packages: write` only?

This follows the principle of least privilege. The workflow only needs to read repository contents and write packages, so it should not receive broad write access to issues, pull requests, actions, secrets, or repository settings. If the workflow or a third-party action were compromised, the narrow scope would limit the attacker to package publishing instead of giving write access to the whole repository.

---

## Task 2 — Hugging Face Spaces Deployment

### Space URL

```text
https://mysteri0king-quicknotes-lab10.hf.space
```

### Public health check

Command:

```bash
curl -v https://mysteri0king-quicknotes-lab10.hf.space/health
```

Output excerpt:

```text
HTTP/1.1 200 OK
Content-Type: application/json
cache-control: no-store
content-security-policy: default-src 'none'
pragma: no-cache
x-content-type-options: nosniff

{"notes":4,"status":"ok"}
```

The public Hugging Face URL successfully returned the QuickNotes `/health` JSON response.

### Space Dockerfile

File in the Space repository and copied into this repository under `cloud/hf-space/Dockerfile`:

```dockerfile
FROM ghcr.io/mysteri0k1ng/devops-intro/quicknotes:v0.1.2

ENV ADDR=:8080
ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/seed.json

EXPOSE 8080
```

### Space README metadata

File in the Space repository and copied into this repository under `cloud/hf-space/README.md`:

```yaml
---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
pinned: false
---
```

### Why pull from GHCR instead of building inside the Space?

I chose to pull the released GHCR image because it uses the same artifact produced by CI. This improves reproducibility: the image tested and pushed by GitHub Actions is the same image deployed on Hugging Face Spaces. Building inside the Space could be useful for debugging, but it creates a second build path and can make releases less predictable.

---

## Hugging Face Latency Measurements

### Warm latency

Five warm requests were measured with:

```bash
for i in {1..5}; do
  curl -o /dev/null -s -w "%{time_total}\n" "$HF_URL/health"
done | tee reports/lab10/hf-warm-latency.txt
```

Measurements:

```text
0.810268
0.900130
0.984481
0.795467
0.658464
```

Warm p50:

```text
0.810268 s
```

Warm p95:

```text
0.984481 s
```

### Cold latency

Cold requests were measured after idle windows before making exactly one request.

```text
Cold request 1: 0.839204 s
Cold request 2: 1.697966 s
Cold request 3: 1.295025 s
```

Cold measurement artifact:

```text
reports/lab10/hf-cold-latency.txt
```

---

## Task 2 — Design Questions

### d) HF Spaces sleep vs Cloud Run scale to zero

Both systems stop unused workloads and restart them when traffic arrives, but they optimize for different use cases. Hugging Face Spaces is optimized for free demos, ML apps, and community projects, so cold wake-up can be slower and less production-oriented. Cloud Run is designed as a serverless production platform, so it usually optimizes more heavily for fast autoscaling, traffic routing, and predictable startup behavior. HF Spaces is good for free public demos, while Cloud Run is closer to production serverless infrastructure.

### e) Why does the Space need `app_port: 8080`?

Hugging Face Spaces needs to know which port inside the container should receive public traffic. QuickNotes listens on port 8080, so the Space README declares `app_port: 8080`. Without this setting, the platform may route traffic to the wrong default port and the app would appear unavailable even if the container is running correctly.

### f) Pulling the GHCR image vs building in the Space

Pulling from GHCR makes the deployment use the same versioned artifact that CI produced. This is good for reproducibility and release discipline. Building in the Space can be simpler for quick experiments, but it creates another build environment and can hide differences between local, CI, and production. For this lab, using GHCR is better because Task 1 already produced a release image.

---

## Bonus — Cloudflare Tunnel Comparison

### Cloudflare Tunnel setup

QuickNotes was run locally and exposed with Cloudflare Tunnel:

```bash
docker compose up --build -d quicknotes
docker run --rm -it cloudflare/cloudflared:latest tunnel --url http://host.docker.internal:8080
```

The quick tunnel generated an ephemeral `trycloudflare.com` URL. The exact URL is temporary and changes when `cloudflared` restarts.

Tunnel URL:

```text
ephemeral trycloudflare.com URL used during measurement
```

Public health check:

```bash
curl -v "$TUNNEL_URL/health"
```

The tunnel was also verified externally from a phone on a cellular network to confirm that it was reachable outside the local machine.

### Cloudflare warm measurements

50 warm requests were measured with:

```bash
for i in {1..50}; do
  curl -o /dev/null -s -w "%{time_total}\n" "$TUNNEL_URL/health"
done | tee reports/lab10/cloudflare-warm-latency.txt
```

Cloudflare Tunnel warm p50:

```text
0.552730 s
```

Cloudflare Tunnel warm p95:

```text
0.757801 s
```

### Comparison table

| Metric               |                 HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
| -------------------- | ---------------------------------: | ---------------------------------: |
| Warm p50             |                         0.810268 s |                         0.552730 s |
| Warm p95             |                         0.984481 s |                         0.757801 s |
| Cold start           | 0.839204 s, 1.697966 s, 1.295025 s |            N/A, continuously local |
| Public URL stability |                             stable |               ephemeral on restart |
| Cost                 |                               free |                               free |

### Bonus design questions

### g) Which one is really cloud?

HF Spaces is more directly “cloud” because the container runs in Hugging Face infrastructure. Cloudflare Tunnel is different: the application still runs on my laptop, while Cloudflare provides the public edge proxy. For users, the distinction matters only when it affects reliability, latency, availability, and whether the service stays online when my laptop is off. From an operations perspective, the distinction matters a lot because HF hosts the workload, while Cloudflare Tunnel only exposes my local workload.

### h) Latency dominator for each

For HF Spaces, warm latency is dominated by the network path to the hosted container, Hugging Face routing, and the platform’s runtime overhead. Cold latency is dominated by waking the sleeping Space and starting or reactivating the container. For Cloudflare Tunnel, the app is already running locally, so latency is dominated by the user-to-Cloudflare edge path, the Cloudflare-to-local tunnel path, and the quality of the local network.

### i) When is Cloudflare Tunnel the right production pick?

Cloudflare Tunnel can be a good production choice for home labs, internal tools, on-prem services, demos, and stakeholder review links where the service must stay on private infrastructure but still be reachable from outside. It is not a good production choice when the service depends on a student laptop, unstable Wi-Fi, or a temporary quick tunnel URL. For a serious public service, I would use a stable named tunnel with managed infrastructure or a hosted platform instead of an ephemeral local quick tunnel.

---

## Artifacts

```text
.github/workflows/release.yml
cloud/hf-space/Dockerfile
cloud/hf-space/README.md
reports/lab10/hf-health-curl.txt
reports/lab10/hf-warm-latency.txt
reports/lab10/hf-cold-latency.txt
reports/lab10/cloudflare-health-curl.txt
reports/lab10/cloudflare-warm-latency.txt
submissions/lab10.md
```
