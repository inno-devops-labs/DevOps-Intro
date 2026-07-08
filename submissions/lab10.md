# Lab 10 Submission - Cloud Computing: Ship QuickNotes to a Real Cloud

> Registry: **ghcr.io** - Hosted platform: **Hugging Face Spaces** (Docker SDK) - Bonus: **Cloudflare Tunnel**

---

## Task 1 - CI-Automated Push to ghcr.io

### 1.1 Release workflow (`.github/workflows/release.yml`)

```yaml
name: release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read      # least privilege
  packages: write     # push to GHCR — nothing else

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      # All third-party actions pinned by 40-char commit SHA (comment = version).
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4
      - uses: docker/setup-buildx-action@8d2750c68a42422c14e847fe6c8ac0403b4cbd6f # v3
      - uses: docker/login-action@c94ce9fb468520275223c153574b00df6fe4bcc9 # v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: meta
        uses: docker/metadata-action@c299e40c65443455700f0fdfc63efafe5b349051 # v5
        with:
          images: ghcr.io/${{ github.repository }}/quicknotes
          tags: |
            type=semver,pattern={{version}}
            type=raw,value=latest
      - uses: docker/build-push-action@10e90e3645eae34f1e60eeb005ba3a3d33f178e8 # v6
        with:
          context: ./app
          platforms: linux/amd64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

### 1.2 Trigger + registry

```text
$ git tag -a v0.1.0 -m "Lab 10 release"
$ git push origin v0.1.0
# -> workflow "release" runs green (Actions run: release #1, commit 87a70a3)
```

Image published to: **`ghcr.io/blacktree-lab/devops-intro/quicknotes`**, tags `0.1.0` + `latest`.

### 1.3 Clean, unauthenticated pull (proof it's public)

```text
$ docker logout ghcr.io
Removing login credentials for ghcr.io
$ docker pull ghcr.io/blacktree-lab/devops-intro/quicknotes:0.1.0
...
Digest: sha256:f00df24cce80ea2698330aedbed911763630ffa0ade8d53caeff58615d1135f2
Status: Downloaded newer image for ghcr.io/blacktree-lab/devops-intro/quicknotes:0.1.0

$ docker run --rm -d -p 127.0.0.1:8081:8080 ghcr.io/.../quicknotes:0.1.0
$ curl -s http://127.0.0.1:8081/health
{"notes":0,"status":"ok"}
```
Pulls with **no login** -> publicly pullable from any clean machine.

### 1.4 Design Questions

**a) OIDC vs `GITHUB_TOKEN` for pushing to ghcr.io.**
For pushing to the **same repo's** GHCR, the built-in `GITHUB_TOKEN` with `packages: write` is enough, it authenticates to GitHub's own services. You reach for **OIDC** when the workflow must authenticate to an **external** system (AWS/GCP/Azure, another registry) *without storing long-lived secrets*: the job exchanges a short-lived, cryptographically-verifiable identity token for cloud credentials. OIDC gives you **keyless, short-lived, auditable** federation and fine-grained trust policies (which repo/branch/environment may assume which cloud role) — none of which `GITHUB_TOKEN` provides, because it only talks to GitHub.

**b) `:latest` vs immutable `:v0.1.0` — why ship both?**
`:v0.1.0` is **immutable** - deploys and rollbacks reference an exact, reproducible artifact (ideally by digest). `:latest` is **mutable** and moves each release. You still ship `:latest` as a convenience pointer for humans, docs, demos, and "just give me the newest" pulls where reproducibility doesn't matter. The discipline: **pin the immutable tag/digest in production**, use `:latest` only where convenience beats determinism. Shipping both serves both audiences.

**c) `packages: write` scope only - principle + concrete attack prevented.**
Principle: **least privilege**. A broad `write: all` token can modify repo contents, releases, issues/PRs, deployments, and workflows. Scoping to `packages: write` (+ `contents: read`) means that if a **compromised third-party action** running in the job is exploited, the token can only push packages, it **cannot commit a backdoor to the repo, open/merge a malicious PR, or rewrite CI** to persist. The narrow scope caps the blast radius to the registry.

---

## Task 2 - Deploy to Hugging Face Spaces

### 2.1 The Space (Docker SDK)

Space: **`https://huggingface.co/spaces/BarberryML/quicknotes`** — public, Docker SDK, free CPU-basic hardware. Two files:

```dockerfile
# Dockerfile — pull the immutable GHCR image published by Task 1's CI
FROM ghcr.io/blacktree-lab/devops-intro/quicknotes:0.1.0
# HF runs Space containers as UID 1000, which can't write the image's /data
# (owned by distroless uid 65532), so persist notes in world-writable /tmp.
ENV ADDR=":8080" DATA_PATH="/tmp/notes.json" SEED_PATH="/seed.json"
EXPOSE 8080
```

```yaml
# README.md frontmatter
---
title: QuickNotes
emoji: 📝
sdk: docker
app_port: 8080     # QuickNotes listens on 8080; HF defaults to 7860
pinned: false
---
```

Public URL: **`https://barberryml-quicknotes.hf.space`**

```text
$ curl -s https://barberryml-quicknotes.hf.space/health
{"notes":4,"status":"ok"}
$ curl -s https://barberryml-quicknotes.hf.space/notes
[{"id":2,...},{"id":3,...},{"id":4,...},{"id":1,...}]   # 4 seeded notes
```

### 2.2 Scale-to-zero (HF "sleep")  cold vs warm latency

Free-tier Spaces sleep after ~30 min idle; the wake-up is the cold start.

| Measurement | time_total |
|-------------|-----------:|
| Warm p50 (50 consecutive requests) | 2.65 s |
| Cold start #1 (confirmed "Sleeping" first) | 4.54 s |
| Cold start #2 | `<FILL>` s |
| Cold start #3 | `<FILL>` s |

Command: `curl -w '%{time_total}\n' -o /dev/null -s https://barberryml-quicknotes.hf.space/health`

### 2.3 Design Questions

**d) HF "sleep" vs Cloud Run "scale to zero" — why is HF's wake so much slower?**
Both deallocate when idle to save resources. **Cloud Run** is engineered for production request-serving: images are pre-distributed on its fleet, the cold-start path is highly optimized, and a tiny Go image boots in ~1–2 s, billed per request. **HF Spaces free tier** optimizes for *cheap shared hosting of demos/ML apps*, not latency: after ~30 min it fully **stops the Space and releases the node**, so waking means **re-scheduling onto a node, pulling/loading the image, and starting the container** — tens of seconds. HF trades wake latency for cost/fairness on shared free infrastructure (and ML images are often huge); Cloud Run trades cost for fast, predictable cold starts.

**e) Why `app_port: 8080`? What's HF's default and why?**
HF defaults to **port 7860** — the historic **Gradio** default, and most Spaces are Gradio/Streamlit apps. QuickNotes listens on **8080**, so `app_port: 8080` tells HF's reverse proxy to forward public traffic to 8080. Without it, HF would proxy to 7860 where nothing listens and the Space would never become reachable.

**f) Pull the ghcr image vs build the Dockerfile inside the Space - trade-off.**
**Pulling the pre-built image** (what we did): fast Space builds (just a pull), and crucially **reproducibility + provenance**: the Space runs the *exact* immutable artifact that CI built, scanned, and could sign (single source of truth). Cost: the Space repo has no source, so it's **less debuggable/editable in place**, and you depend on the registry being reachable and the image public. **Building from source in the Space**: self-contained and editable, HF caches layers — but slower, and it rebuilds in a less-controlled environment that can **drift from CI**, losing the "deploy the exact tested artifact" guarantee. For production-style deploys, pulling the CI artifact wins; for rapid in-place iteration, building in the Space is handier.

---

## Bonus Task - Cloudflare Tunnel + Cross-Platform Comparison

Local QuickNotes exposed via a Cloudflare **quick tunnel**:
`https://airline-carlos-chair-declaration.trycloudflare.com` (ephemeral — changes on each `cloudflared` restart). Verified reachable from a **phone on cellular** (a different network) — screenshot `screenshots/lab10-tunnel-phone.jpg`. Latency from a 50-run `curl` loop.

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | **2.65 s** | **1.67 s** |
| Warm p95 | **3.01 s** | **3.10 s** |
| Cold start | `<FILL — 3 samples>` | N/A (continuously local) |
| Public URL stability | stable | ephemeral on restart |
| Cost | free | free |

Tunnel latency = 50 `curl` runs from the host against the `trycloudflare.com` URL: p50 **1.665 s**, p95 **3.096 s** (min 1.45 / max 3.30). Each request traverses host -> Cloudflare edge -> back down the tunnel to the *same* laptop — i.e. the residential uplink **twice** — which is why it's slower and more variable than a datacenter-based prober (Checkly saw ~0.78 s p50 to the same tunnel from Frankfurt/Singapore, because edge↔datacenter is fast and only the edge->Melbourne leg is over the slow link).

**Surprising result:** the *hosted* HF Space (warm p50 **2.65 s**) was actually **slower** than the *local-via-edge* tunnel (**1.67 s**) from Melbourne — HF's datacenter is geographically distant (plus free-tier reverse-proxy overhead), while the tunnel exits through a nearby Cloudflare edge. Being "in the cloud" doesn't guarantee lower latency; **distance and platform overhead dominate**.

**g) Which is "really cloud", and does it matter to users?**
**HF Spaces is the real cloud deployment** — HF runs the container on *their* datacenter infrastructure, independent of my machine. With **Cloudflare Tunnel the compute runs on my own laptop**; Cloudflare only supplies the edge that proxies public traffic in. To a user hitting the URL *right now*, both look identical — a public HTTPS endpoint returning JSON. But the distinction reaches users over time as **availability**: the HF version stays up when my laptop is asleep/off and doesn't depend on my home internet, whereas the tunnel dies the instant I close the lid, lose power, or restart `cloudflared` (and its URL changes). "Really cloud" = someone else runs the compute and keeps it available — and that reliability difference is what users ultimately feel.

**h) Latency dominator for each.**
- **HF Spaces (warm):** the round-trip network distance client ↔ HF datacenter. **(cold):** the wake-up — re-schedule + image pull/load + container start — tens of seconds, dwarfing the network time.
- **Cloudflare Tunnel:** the **double traversal of my residential uplink** — client -> nearest Cloudflare edge -> *back down the tunnel over my home connection* to the laptop -> back out. My home upload bandwidth and the edge↔laptop leg dominate (measured p50 1.67 s / p95 3.10 s from the same laptop, crossing that link twice). A datacenter prober sees far less (Checkly ~0.78 s) because only the edge->Melbourne leg is over the slow link.

**i) When is Cloudflare Tunnel the right production pick, and when never?**
**Right** when the thing you're exposing genuinely lives outside a normal cloud and you want secure inbound access without opening ports: **home-lab / self-hosted services, on-prem or legacy systems** bridged to the internet, **internal tools behind zero-trust** (a *named* tunnel + Cloudflare Access with SSO), and quick **dev / stakeholder-review** URLs. **Never** as the primary host for a scalable public app: all traffic funnels through one machine-to-edge pipe (a bottleneck and single point of failure), availability equals that one box's uptime, and quick tunnels are ephemeral. For a real public app you want actual hosted compute (Cloud Run / HF / etc.) that scales and stays up independently of any single machine.
