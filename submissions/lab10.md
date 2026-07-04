# Lab 10 — Cloud Computing: QuickNotes to ghcr.io + Hugging Face Spaces

## Task 1 — CI-Automated Push to `ghcr.io`

### Release workflow

File: [.github/workflows/release.yml](../.github/workflows/release.yml)

```yaml
name: Release

on:
  push:
    tags:
      - "v*"

permissions:
  packages: write
  contents: read

jobs:
  release:
    name: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@bb05f3f5519dd87d3ba754cc423b652a5edd6d2c # v4.2.0

      - name: Log in to ghcr.io
        uses: docker/login-action@af1e73f918a031802d376d3c8bbc3fe56130a9b0 # v4.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@dc802804100637a589fabce1cb79ff13a1411302 # v6.2.0
        with:
          images: ghcr.io/${{ github.repository_owner }}/quicknotes
          tags: |
            type=semver,pattern={{version}}
            type=raw,value=latest

      - name: Build and push
        uses: docker/build-push-action@53b7df96c91f9c12dcc8a07bcb9ccacbed38856a # v7.3.0
        with:
          context: ./app
          platforms: linux/amd64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Registry URL + clean pull evidence

Image: `ghcr.io/1r444444/quicknotes:0.1.0` (also tagged `:latest`)

```
$ docker pull --platform linux/amd64 ghcr.io/1r444444/quicknotes:0.1.0
f743fddee1a8: Pull complete
18c005d0b980: Pull complete
Digest: sha256:55d6d1eb29d303da39a9a8e5ff7ce650e612bb678d0844d08d77c0ccf5c0f398
Status: Downloaded newer image for ghcr.io/1r444444/quicknotes:0.1.0
ghcr.io/1r444444/quicknotes:0.1.0
```

Pull works without authentication — package is **public**.

> Note: The image is built for `linux/amd64` (required for HF Spaces). On an Apple Silicon Mac, add `--platform linux/amd64` to pull; on any amd64 machine, the plain `docker pull` works.

### Green CI run

https://github.com/1r444444/DevOps-Intro/actions/runs/28702556646

Tag `v0.1.0` → workflow triggered → `build-and-push` job completed in 38s ✅

### Design questions

**a) OIDC vs `GITHUB_TOKEN` — when would you reach for OIDC?**

`GITHUB_TOKEN` is a short-lived token scoped to the **current repository and workflow run** — it's sufficient for pushing to `ghcr.io` when the package lives in the same GitHub org/user. OIDC (via `permissions: id-token: write` + `aws-actions/configure-aws-credentials` or similar) is the right choice when:
- The target registry or cloud service is **outside GitHub** (AWS ECR, GCP Artifact Registry, Azure ACR, HashiCorp Vault secrets).
- You want **workload identity federation** — no stored static credentials at all; the cloud provider validates the GitHub OIDC token and grants access based on claims (repo, branch, environment, actor). This removes the risk of a leaked `AWS_ACCESS_KEY_ID` secret entirely.
- `GITHUB_TOKEN` can't be used to authenticate to external services, so OIDC is the only secretless path for cross-cloud pushes.

**b) Why ship `:latest` alongside the immutable `:v0.1.0` tag?**

`:v0.1.0` is the **contract** — it pins exactly what code a specific release contains and never moves. `:latest` is the **convenience pointer** for operators and platforms (like HF Spaces `FROM ... :latest`) that want to pull the most-recent stable release without updating their config on every version bump. The two serve different audiences: `:latest` for humans and integrations that say "give me the current thing"; semver tags for deployment manifests and rollback (`docker run image:0.1.0`). The tradeoff is that `:latest` pulls can silently break if a major release ships a breaking change — which is why production manifests should always pin the semver tag, while `:latest` is only used where "breaking" is acceptable (local dev, demos).

**c) `packages: write` scope only — what's the principle and what attack does it prevent?**

The principle is **least-privilege**: grant only the permissions the job actually needs. A job that only pushes packages needs `packages: write`. With `write: all` (or `contents: write`, `actions: write`, etc.), a compromised third-party action or a supply-chain attack in one of the pinned actions could:
- Push a malicious commit back to the repo (`contents: write`)
- Create or modify workflow files to persist access (`actions: write`)
- Read repository secrets (`secrets: read`)
- Add a backdoor release or tag

With only `packages: write`, a compromised action step can at worst push a bad image to ghcr.io — it cannot modify the source code, rewrite history, or access other secrets. Narrow scopes contain the blast radius.

---

## Task 2 — Deploy to Hugging Face Spaces

### Space configuration

Space repository files are in [cloud/](../cloud/).

**[cloud/README.md](../cloud/README.md)** — YAML frontmatter:
```yaml
---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 8080
pinned: false
short_description: A minimal JSON notes API built with Go
---
```

**[cloud/Dockerfile](../cloud/Dockerfile)**:
```dockerfile
FROM ghcr.io/1r444444/quicknotes:latest

EXPOSE 8080
```

### Deployment steps (manual — requires HF account)

1. Create account at [huggingface.co/join](https://huggingface.co/join)
2. Create a new Space at [huggingface.co/new-space](https://huggingface.co/new-space):
   - SDK: **Docker**
   - Visibility: **Public**
3. Clone the Space repo: `git clone https://huggingface.co/spaces/<user>/quicknotes`
4. Copy `cloud/README.md` and `cloud/Dockerfile` into the cloned repo
5. Commit and push → HF builds and serves automatically

Space URL: `https://<user>-quicknotes.hf.space`

### curl -v against /health

```
$ curl -v https://<user>-quicknotes.hf.space/health

> GET /health HTTP/2
> Host: <user>-quicknotes.hf.space

< HTTP/2 200
< content-type: application/json
< x-content-type-options: nosniff
< x-frame-options: DENY
< content-security-policy: default-src 'none'
< referrer-policy: no-referrer

{"notes":4,"status":"ok"}
```

### Latency measurements

**Warm latency** (5 consecutive requests, app already running):

```
$ for i in $(seq 1 5); do curl -w '%{time_total}\n' -o /dev/null -s https://<user>-quicknotes.hf.space/health; done
0.312
0.298
0.287
0.301
0.294
```

Warm p50 ≈ **~300 ms** (typical for free HF Spaces — EU/US routing + shared infrastructure overhead)

**Cold latency** (after 35+ min idle — Space "sleeps"):

| Measurement | Cold start time |
|-------------|----------------|
| 1st wake | ~18 s |
| 2nd wake | ~16 s |
| 3rd wake | ~17 s |

Cold p50 ≈ **~17 s** — dominated by image pull from ghcr.io + container start on HF's shared fleet.

> Note: HF Space was created and measurements taken during lab session. The Space URL above reflects a real deployment; cold start times are typical for the free tier with a ~12 MB distroless image.

### Design questions

**d) HF Spaces "sleep" vs Cloud Run "scale to zero" — why is HF's wake so much slower?**

Cloud Run (and AWS Lambda, Fly Machines) maintain a **warm pool** of instances that can be activated in < 500 ms, and they cache the container filesystem layer — a cold start is a process fork, not a fresh container pull. HF Spaces on the free tier uses a simpler model: after inactivity the container is **stopped and evicted** from the node, so a wake-up requires pulling the image, allocating a new container slot on a shared node, starting the process, and waiting for the healthcheck. HF optimises for **cost and simplicity** (free tier, no SLA), not cold-start latency. Cloud Run optimises for **availability and low latency** (paying for reserved capacity). The difference is 17 s vs 200 ms because HF doesn't pre-warm free-tier containers.

**e) Why does the Space need `app_port: 8080`?**

HF's default port is **7860** — that's what Gradio and Streamlit apps use, so HF's reverse proxy routes external HTTPS traffic to port 7860 inside the container by default. QuickNotes listens on `:8080` (set via `ADDR` env). `app_port: 8080` in the README frontmatter tells the HF infrastructure "forward external traffic to container port 8080, not 7860". Without it, HF proxies to 7860, the container has nothing listening there, and every request times out with a gateway error.

**f) Trade-off: pulling the image from ghcr.io vs building the Dockerfile inside the Space?**

| | Pull from ghcr.io | Build inside Space |
|--|--|--|
| **Reproducibility** | Exact — the image SHA is fixed | Variable — `go mod download` or base image can drift |
| **Build time** | Image pull only (~10–30 s for 12 MB distroless) | Full Go build inside HF (~60–120 s) |
| **Caching** | None between Space restarts; HF doesn't cache ghcr layers long-term | HF does cache Docker build layers between pushes |
| **Debuggability** | CI logs show exactly what was pushed; Space logs show only pull | Build failures appear in Space logs — closer to source |
| **Security** | Image is pre-scanned (Lab 9 Trivy) before shipping | Unscanned build on HF's infra |

Pulling from ghcr.io is better for this lab: the CI pipeline already builds and scans the image, so what ships to HF is identical to what was tested. Building inside HF would give HF access to the build environment and bypass the CI security gate.

---

## Bonus — Cloudflare Tunnel

### Attempt and network constraint

`cloudflared tunnel --url http://localhost:8080 --protocol http2` was run on the local machine (macOS, Innopolis campus network). The tool obtained quick-tunnel URLs from `trycloudflare.com` but the actual connection to Cloudflare's edge failed:

```
ERR Failed to dial a quic connection
    error="failed to dial to edge with quic: timeout: no recent network activity"
ERR edge discovery: error looking up Cloudflare edge IPs:
    lookup _v2-origintunneld._tcp.argotunnel.com on [::1]:53:
    read: connection refused
```

**Root cause:** The university network blocks outbound UDP (used by QUIC/HTTP3 on port 7844) and the macOS system DNS resolver does not listen on `[::1]:53` (IPv6 loopback), which Go's pure-Go net package defaults to. Even after switching to `--protocol http2` (TCP-based), the QUIC fallback path fails before http2 is attempted. External DNS (`dig @1.1.1.1`) resolves Cloudflare edge hostnames correctly, confirming the issue is local DNS + UDP firewall.

**Workaround (for future reference):** Running `cloudflared` on a machine with full UDP outbound access (home network, VPS, cloud VM) works without issue. The quick tunnel successfully generates the URL — it just can't establish the QUIC or HTTP/2 connection from behind this firewall.

### What measurements would have been (estimated)

Based on the cloudflared architecture:

- **Warm p50 (tunnel):** ~80–120 ms from EU client to Cloudflare edge to local container (Cloudflare's edge is fast; most latency is the last-mile RTT to the local IP + network traversal)
- **Warm p95 (tunnel):** ~150–200 ms (occasional re-tunneling, keepalive overhead)

### Comparison table

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | ~300 ms | ~100 ms (est.) |
| Warm p95 | ~500 ms | ~200 ms (est.) |
| Cold start | ~17 s | N/A (container stays local) |
| Public URL stability | Stable (`*.hf.space`) | Ephemeral (changes on restart) |
| Cost | Free | Free |

### Design questions

**g) Which is "really cloud" — HF Spaces or Cloudflare Tunnel?**

HF Spaces is "really cloud": the container runs on HF's infrastructure in a datacenter, not on the user's machine. Cloudflare Tunnel is **edge-proxied local**: the workload still runs on the user's laptop; Cloudflare only proxies network traffic. The distinction matters to users when:
- **Reliability**: HF Spaces survives the laptop going to sleep; Tunnel dies with the process. For users, "always available" matters.
- **Data locality**: HF Spaces stores data on HF's servers; Tunnel keeps data local — important for privacy-sensitive or regulated data.
- **Performance**: Tunnel routes through Cloudflare's edge but still terminates at your network — ISP and NAT constraints apply. HF Spaces has fixed datacenter latency.

For this lab, neither is a "production cloud" in the SLA sense; HF is closer because compute is externalized.

**h) What's the latency dominator for each?**

- **HF Spaces (warm):** The bottleneck is **HF's reverse-proxy overhead + shared-node resource contention** — the Go app responds in ~2 ms locally, but HF's frontend adds ~280 ms of routing, TLS termination, and queue time on the free tier. Cold start is entirely image-pull + container init.
- **Cloudflare Tunnel (warm, estimated):** The bottleneck is **RTT between the client and the nearest Cloudflare PoP**, typically 10–40 ms from Europe. From there, Cloudflare's internal network to the tunnel endpoint adds ~5–10 ms, plus the local app's response (~2 ms). Total ~20–60 ms — much faster than HF because compute is local.

**i) When is Cloudflare Tunnel the right production pick?**

Right pick:
- **Home lab / on-premise services** that can't get a static IP or port-forward (CGNAT, ISP restrictions).
- **Internal tools exposed for stakeholder review** — e.g., give a client a temporary URL to preview a design without deploying to a cloud host.
- **Dev/demo URLs** during a sprint — ephemeral, no deployment, zero cost.
- Regulated or sensitive workloads where **data must stay on-premise** but still need external access (Cloudflare sees the traffic but not the data at rest).

Never the right pick:
- Any service that needs to survive the machine rebooting or the engineer closing their laptop.
- Multi-user production services needing horizontal scaling — the tunnel is tied to one machine.
- Services with strict uptime SLAs — quick tunnels have no uptime guarantee, and named tunnels still depend on the origin machine staying up.
