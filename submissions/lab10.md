# Lab 10 submission

**Host:** Apple Silicon Mac. **Image:** `ghcr.io/markovav-official/devops-intro/quicknotes:v0.1.0`. **HF Space:** https://markovav-devops-intro.hf.space

---

## Task 1 — CI push to `ghcr.io`

### Release workflow

[`.github/workflows/release.yml`](../.github/workflows/release.yml) — triggers on `v*` tags, builds `app/Dockerfile`, pushes `linux/amd64` to ghcr with version + `latest`.

```yaml
on:
  push:
    tags:
      - 'v*'
permissions:
  contents: read
  packages: write
# ...
tags: |
  ghcr.io/${{ github.repository }}/quicknotes:${{ github.ref_name }}
  ghcr.io/${{ github.repository }}/quicknotes:latest
```

All third-party actions SHA-pinned (`checkout`, `setup-buildx`, `login`, `build-push`).

### Registry & pull evidence

- **Image URL:** `ghcr.io/markovav-official/devops-intro/quicknotes:v0.1.0`
- **Package:** https://github.com/markovav-official/DevOps-Intro/pkgs/container/devops-intro%2Fquicknotes
- **Clean pull:** see [`attachments/lab10/docker-pull.txt`](attachments/lab10/docker-pull.txt) — public package, digest `sha256:f540e365…`

Package visibility set to **Public** (required for HF Spaces pull without auth).

### CI release run

- **Green run:** [release #2 — `v0.1.0`](https://github.com/markovav-official/DevOps-Intro/actions/runs/28899025918)

### Design questions (a–c)

**a) OIDC vs `GITHUB_TOKEN`**

`GITHUB_TOKEN` is minted per workflow run, scoped to this repo, and sufficient for `docker push` to `ghcr.io` in the same repository. **OIDC** (federated identity to AWS/GCP/Azure) is for pushing or deploying to **external** accounts without long-lived cloud secrets — the workflow proves its identity to a third party. OIDC gives cross-account, auditable, short-lived credentials; `GITHUB_TOKEN` cannot leave GitHub's trust boundary.

**b) `:latest` vs immutable `:v0.1.0`**

`:v0.1.0` is the **audit trail** — rollbacks and incident response reference an exact digest. `:latest` is the **convenience pointer** for `docker pull` without a version and for Spaces/compose defaults that always want "current release". Production deploys should pin immutable tags; `latest` is mutable by design.

**c) `packages: write` scope only**

**Principle:** least privilege. `packages: write` lets the job publish container images only. A compromised action cannot rewrite `main`, open PRs, or modify other repos — attacks like retagging unrelated packages or force-pushing code require permissions this job does not have (`contents: write`, `id-token` to foreign clouds, etc.).

---

## Task 2 — Hugging Face Spaces

### Space setup

```bash
git clone git@hf.co:spaces/markovav/DevOps-Intro hf-space-repo
cp cloud/hf-space/Dockerfile cloud/hf-space/README.md hf-space-repo/
cd hf-space-repo && git add . && git commit -m "Deploy QuickNotes from ghcr.io v0.1.0" && git push
```

### Space URL & health check

- **Space:** https://markovav-devops-intro.hf.space
- **`curl -v` `/health`:** [`attachments/lab10/hf-health.txt`](attachments/lab10/hf-health.txt) — HTTP 200, security headers from Lab 9 middleware
- **`/notes`:** `[]` (empty store on fresh Space)

### Space repo files

**`cloud/hf-space/Dockerfile`** — pull pre-built release (no rebuild on HF):

```dockerfile
FROM ghcr.io/markovav-official/devops-intro/quicknotes:v0.1.0
```

**`cloud/hf-space/README.md`** frontmatter:

```yaml
---
title: QuickNotes Lab 10
emoji: 📝
sdk: docker
app_port: 8080
---
```

### Latency (scale-to-zero)

Measured with [`cloud/scripts/measure-warm.sh`](../cloud/scripts/measure-warm.sh) and [`measure-cold.sh`](../cloud/scripts/measure-cold.sh) after 35+ min idle.

| Measurement | Value (s) |
|-------------|----------:|
| Warm p50 (5 requests) | 0.901 |
| Cold #1 | 1.24 |
| Cold #2 | 2.08 |
| Cold #3 | 1.87 |

Warm p50 **0.9 s** → cold avg **~1.7 s** (~2×) after idle; image already on HF so wake is seconds, not tens of seconds.

Raw logs: [`attachments/lab10/hf-warm.txt`](attachments/lab10/hf-warm.txt) · [`attachments/lab10/hf-cold.txt`](attachments/lab10/hf-cold.txt)

### Design questions (d–f)

**d) HF sleep vs Cloud Run scale-to-zero**

Same pattern (no traffic → no running container), different SLO. HF free tier optimizes for **cost and sharing demos**, not low latency: cold start includes scheduler wake, **image pull/layer cache**, and container boot — often tens of seconds. Cloud Run targets **production HTTP** with faster scale-from-zero, regional capacity, and tuned networking. HF trades wake time for zero card and zero bill.

**e) Why `app_port: 8080`?**

HF defaults to **7860** (Gradio/streamlit convention). QuickNotes listens on **8080** (`ADDR=:8080`). Without `app_port: 8080` the platform probes the wrong port → health checks fail and the Space shows "container exited".

**f) Pull from ghcr.io vs build in Space**

| Pull from ghcr | Build in Space |
|----------------|----------------|
| Same artifact as CI release | Reproduces build on HF builders |
| Fast Space deploy (no compile) | Slower, needs `app/` source in Space repo |
| Debug needs ghcr access/logs | Dockerfile self-contained on HF |
| **Chosen:** pull — single source of truth from Task 1 tag |

---

## Bonus — Cloudflare Tunnel + comparison

### Quick tunnel

```bash
docker compose up -d quicknotes
cloudflared tunnel --url http://localhost:8080
# copy https://<random>.trycloudflare.com from output
```

- **URL:** https://tenant-voting-composer-highly.trycloudflare.com
- **Verified from other network:** `curl` from **University VM** (different network than Mac running `cloudflared`) → HTTP **200** `{"notes":44,"status":"ok"}` via Cloudflare (`cf-ray: a179ed132c12bb02-ARN`, edge **ARN**)

Evidence: [`attachments/lab10/tunnel-curl.txt`](attachments/lab10/tunnel-curl.txt)

Warm stats (University VM, 5 requests each): [`attachments/lab10/comparison-vm.txt`](attachments/lab10/comparison-vm.txt)

### Comparison table

Measured from **University VM** (same client, 5 warm `curl` requests to `/health`).

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | 0.651 | 0.392 |
| Warm p95 | 0.722 | 0.565 |
| Cold start | ~1.7 (avg) | N/A (continuously local) |
| Public URL stability | stable | ephemeral on restart |
| Cost | free | free |

### Design questions (g–i)

**g) Which is "really cloud"?**

HF runs **your container in their datacenter** — classic PaaS. Tunnel runs the app **on your machine**; only routing/DDoS/TLS termination is cloud. Users see HTTPS either way; the distinction matters for **data residency, uptime SLA, and who patches the host**. For a course demo both are "cloud-delivered"; for compliance only HF counts as app hosting in a third-party DC.

**h) Latency dominator (HF vs Tunnel)**

- **HF warm:** container process + HF ingress + geographic distance to their region.
- **HF cold:** **wake + image pull** dominates.
- **Tunnel warm:** **last-mile internet path** (phone → Cloudflare edge → your home uplink → localhost). Often RTT and upload bandwidth, not Go handler time.

**i) When is Tunnel right for production?**

**Right:** exposing **on-prem/home lab** services without public IP, temporary **stakeholder demos**, webhooks to a dev laptop, internal tools behind NAT. **Never right:** user-facing production APIs needing **HA, stable URL, predictable egress IP, or 24/7** — laptop sleep, ephemeral URL, and residential bandwidth are blockers. Use managed hosting (HF, Cloud Run, k8s) instead.

---

## Artifacts

| Path | Description |
|------|-------------|
| `.github/workflows/release.yml` | Tag → build → push to ghcr.io |
| `cloud/hf-space/` | HF Space Dockerfile + README frontmatter |
| `cloud/scripts/` | Warm/cold/tunnel latency helpers |
| `cloud/teardown.md` | Delete Space, stop tunnel |
| `submissions/attachments/lab10/` | Pull logs, curl, latency captures |
