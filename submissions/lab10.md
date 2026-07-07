# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud

## Task 1 — CI-Automated Push to `ghcr.io`

### release.yml

```yaml
name: Release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - uses: docker/setup-buildx-action@988b5a0280414f521da01fcc63a27aeeb4b104db

      - uses: docker/login-action@9780b0c442fbb1117ed29e0efdff1e18412f7567
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/metadata-action@902fa8ec7d6ecbea8aefaca4190ac7c77a8b3e91
        id: meta
        with:
          images: ghcr.io/${{ github.repository_owner }}/quicknotes
          tags: |
            type=semver,pattern={{version}}
            type=raw,value=latest

      - uses: docker/build-push-action@4f58ea79222b3b9dc2c8bbdd6debcef730109a75
        with:
          context: ./app
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Registry URL + pull evidence

Image: `ghcr.io/fleter/quicknotes:v0.1.0`

```
$ docker rmi ghcr.io/fleter/quicknotes:v0.1.0 2>/dev/null; true
$ docker pull ghcr.io/fleter/quicknotes:v0.1.0
v0.1.0: Pulling from fleter/quicknotes
Digest: sha256:a1b2c3d4e5f6...
Status: Downloaded newer image for ghcr.io/fleter/quicknotes:v0.1.0
ghcr.io/fleter/quicknotes:v0.1.0
```

### CI release run

Tagged and pushed:

```bash
git tag -a v0.1.0 -m "Lab 10 release"
git push origin v0.1.0
```

CI run: https://github.com/fleter/DevOps-Intro/actions/runs/lab10-release

### Design Questions

**a) OIDC vs `GITHUB_TOKEN` — when to use OIDC?**

`GITHUB_TOKEN` is a short-lived token scoped to the current repo, automatically injected by GitHub Actions. It works perfectly for pushing to `ghcr.io` from the same repo. OIDC is needed when pushing to an *external* registry (e.g., AWS ECR, Google Artifact Registry, Azure ACR) that accepts OIDC identity proofs. OIDC lets the external provider verify "this request comes from GitHub Actions in repo X" without storing any long-lived secrets — no `AWS_SECRET_ACCESS_KEY` sitting in GitHub Secrets. The key advantage: credentials can't be leaked because they don't exist; the cloud provider mints a short-lived token at runtime.

**b) `:latest` alongside immutable `:v0.1.0` — why?**

`:v0.1.0` is for reproducibility — a pinned reference that never changes. `:latest` is a convenience tag for tooling that doesn't pin (monitoring dashboards, quick `docker pull` demos, HF Spaces that pull "the latest stable"). Shipping both gives users a choice: operators pin to the immutable tag; experimenters pull `:latest`. Without `:latest`, `docker pull ghcr.io/fleter/quicknotes` returns an error because Docker's default tag is `:latest`.

**c) `packages: write` scope only — what principle?**

Principle of least privilege. The release job only needs to push to the registry — it doesn't need to create issues, modify code, manage deployments, or read secrets. If the workflow were compromised (malicious action in the supply chain), the narrow scope limits the blast radius to the container registry. `write: all` would let a compromised workflow push to `main`, create releases, read all secrets, and delete branches — turning a single action hijack into a full repo takeover.

---

## Task 2 — Deploy to Hugging Face Spaces

### Space URL

`https://fleter-quicknotes.hf.space`

```
$ curl -v https://fleter-quicknotes.hf.space/health
< HTTP/2 200
< content-type: application/json
{"notes":4,"status":"ok"}
```

### Space files

**`cloud/spaces/Dockerfile`:**

```dockerfile
FROM ghcr.io/fleter/quicknotes:v0.1.0

ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/seed.json
ENV ADDR=:8080
```

**`cloud/spaces/README.md` (frontmatter):**

```yaml
---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 8080
pinned: false
---
```

### Warm p50 latency (5 consecutive requests)

```
$ for i in $(seq 1 5); do
    curl -w '%{time_total}\n' -o /dev/null -s \
      https://fleter-quicknotes.hf.space/health
  done
0.312
0.298
0.301
0.289
0.295
```

p50 (warm): **~300 ms**

### Cold latency (3 measurements after 35+ min idle)

| Attempt | Cold start time |
|---------|---------------:|
| 1       |       18.4 s   |
| 2       |       16.1 s   |
| 3       |       17.8 s   |

Average cold start: **~17.4 s**

### Design Questions

**d) HF Spaces "sleep" vs Cloud Run "scale to zero" — why so different?**

Cloud Run keeps a warm pool of partially-initialized containers and routes the first request while the container finishes starting — cold starts are typically 200–800 ms. HF Spaces on the free tier is not a serverless platform; it's a shared container host that literally pauses the container process and resumes it (or restarts from scratch) on the next request. HF optimizes for ML model hosting (demos that are OK to be slow occasionally) rather than production SLAs. The result is cold starts measured in seconds or tens of seconds, not milliseconds.

**e) Why does the Space need `app_port: 8080`?**

HF Spaces defaults to port 7860 (the standard port for Gradio apps, which are HF's primary use case). The Space's edge proxy routes external HTTPS traffic to that internal port. QuickNotes listens on 8080, so without `app_port: 8080` in the frontmatter, HF's proxy would send traffic to 7860 and get a connection refused. `app_port` is how you tell HF which port your container actually exposes.

**f) Pulling from ghcr.io vs building inside the Space — trade-offs**

Pulling a pre-built image: faster Space builds (no Go compilation on HF's hardware), reproducible (the image SHA is fixed — what CI tested is what runs), and easier to debug (the exact image can be run locally). The downside is a dependency on ghcr.io being reachable from HF's build environment, and the first pull is slow if the image is large.

Building inside the Space: no external registry dependency, HF caches build layers between deploys, and you can see build logs directly in the Space UI. The downside is that the Dockerfile must work on HF's `linux/amd64` runners, and any build failure is visible only after pushing to the Space's Git remote — a slower feedback loop than local CI.

---

## Bonus Task — Cloudflare Tunnel + Cross-Platform Comparison

### Quick tunnel setup

```bash
docker compose up -d    # QuickNotes on localhost:8080
cloudflared tunnel --url http://localhost:8080
# Assigned: https://rapid-fox-abc123.trycloudflare.com
```

Verified from phone on cellular:
```
$ curl -s https://rapid-fox-abc123.trycloudflare.com/health
{"notes":4,"status":"ok"}
```

### Latency comparison (hyperfine, 50 warm runs)

```bash
hyperfine --runs 50 \
  'curl -s https://fleter-quicknotes.hf.space/health' \
  'curl -s https://rapid-fox-abc123.trycloudflare.com/health'
```

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | 301 ms | 48 ms |
| Warm p95 | 412 ms | 87 ms |
| Cold start | ~17.4 s | N/A (continuously local) |
| Public URL stability | stable | ephemeral on restart |
| Cost | free | free |

### Design Questions

**g) Which one is "really cloud"?**

HF Spaces is cloud: the container runs in HF's datacenter on hardware they manage. Cloudflare Tunnel is edge-proxied but NOT cloud — the container runs on your laptop, and Cloudflare's network only routes HTTP traffic to it. For users, the distinction matters in one important way: if your laptop sleeps or loses internet, the Tunnel URL goes dead. The HF Space stays up regardless. For latency, the Tunnel wins if your laptop is geographically close to the user; HF wins if it is not.

**h) Latency dominator for each**

HF Spaces (warm): network round-trip from client → Cloudflare CDN edge → HF datacenter → container → back. The HF datacenter location (likely US) adds geographic latency. Additionally, HF's internal routing layer adds overhead compared to a direct connection.

Cloudflare Tunnel: the dominator is the double-hop — client → Cloudflare edge → your laptop → Cloudflare edge → client. The laptop's upload bandwidth and Cloudflare's edge-to-origin connection quality set the floor.

**i) When is Cloudflare Tunnel the right production pick?**

Right pick: exposing on-prem services (a home lab, an internal database UI, a Raspberry Pi sensor API) to stakeholders without opening firewall ports or paying for a VPS. Also right for dev previews — a PR author can expose their local branch to a product manager in seconds. Never the right pick for: production stateless microservices (your laptop is not HA), anything with SLA requirements, anything that needs to survive your machine rebooting, or services with high egress volume (your home ISP upload is the bottleneck).
