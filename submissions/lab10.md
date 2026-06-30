# Lab 10 — Cloud: GHCR Release + Hugging Face Spaces

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + Docker + GitHub Actions + Hugging Face Spaces

---

## Task 1 — CI push to ghcr.io

### Release workflow

[`.github/workflows/release.yml`](../.github/workflows/release.yml) — triggers on `v*` tags, builds `app/Dockerfile`, pushes:

```text
ghcr.io/selysecr332/devops-intro/quicknotes:<tag>
ghcr.io/selysecr332/devops-intro/quicknotes:latest
```

Permissions: `contents: read`, `packages: write` only.

### Release

```bash
git tag -a v0.1.0 -m "Lab 10 release"
git push origin v0.1.0
```

> After first push: GitHub → **Packages** → `devops-intro/quicknotes` → **Package settings** → **Change visibility** → **Public**.

### Evidence

| Item | Value |
|------|-------|
| Registry URL | `ghcr.io/selysecr332/devops-intro/quicknotes:v0.1.0` |
| Digest | `sha256:4887e6d9ea54c73efda95a9f1cfba272d09294c3f4e6db6088160962b1764c8a` |
| Clean pull | See below — pull succeeded without login |
| Green release run | https://github.com/selysecr332/DevOps-Intro/actions/workflows/release.yml (run #2, tag `v0.1.0`, commit `362e64a`) |

```text
$ docker pull ghcr.io/selysecr332/devops-intro/quicknotes:v0.1.0
v0.1.0: Pulling from selysecr332/devops-intro/quicknotes
...
Status: Downloaded newer image for ghcr.io/selysecr332/devops-intro/quicknotes:v0.1.0
Digest: sha256:4887e6d9ea54c73efda95a9f1cfba272d09294c3f4e6db6088160962b1764c8a
```

### Design questions (Task 1)

**a) OIDC vs `GITHUB_TOKEN` for ghcr?**

For pushes from the **same repo**, `GITHUB_TOKEN` with `packages: write` is enough — no long-lived secret to store. **OIDC** is for federated trust to **external** clouds (AWS, GCP, Azure): short-lived tokens bound to workflow identity, no static PAT, and cross-repo/org policies. OIDC gives auditable, scoped federation that `GITHUB_TOKEN` cannot provide outside GitHub's own registry/API surface.

**b) Why ship `:latest` alongside `:v0.1.0`?**

`:v0.1.0` is **immutable** — the audit trail for rollbacks and HF Spaces pin. `:latest` is a **mutable pointer** for convenience (`docker pull` without looking up tags, dev/Spaces defaults). Production deploys should pin semver; `latest` is ergonomics, not the source of truth.

**c) `packages: write` only — what attack does narrow scope prevent?**

Principle of least privilege. If a compromised action or script exfiltrates the job token, `packages: write` limits blast radius to **container packages** — not rewriting `main`, deleting repos, modifying other workflows, or reading unrelated secrets with `contents: write` / admin scopes.

---

## Task 2 — Hugging Face Spaces

### Deploy (one-time)

```powershell
hf auth login
.\cloud\scripts\deploy-hf-space.ps1
# Space: https://selysecr-quicknotes-lab10.hf.space
```

Space files in repo:

- [`cloud/hf-space/Dockerfile`](../cloud/hf-space/Dockerfile) — `FROM ghcr.io/selysecr332/devops-intro/quicknotes:v0.1.0`
- [`cloud/hf-space/README.md`](../cloud/hf-space/README.md) — `sdk: docker`, `app_port: 8080`

HF account: `selysecr` (script auto-detects via `hf auth whoami`).

### Space URL

```text
https://selysecr-quicknotes-lab10.hf.space
```

Hub: https://huggingface.co/spaces/selysecr/quicknotes-lab10

### Health check

```bash
curl -v https://selysecr-quicknotes-lab10.hf.space/health
curl -s https://selysecr-quicknotes-lab10.hf.space/notes
```

```text
$ curl -v https://selysecr-quicknotes-lab10.hf.space/health
< HTTP/2 200
{"notes":0,"status":"ok"}

$ curl -s https://selysecr-quicknotes-lab10.hf.space/notes
[]
```

### Latency (scale-to-zero)

```powershell
.\cloud\scripts\measure-warm.ps1 -Url "https://selysecr-quicknotes-lab10.hf.space/health"
```

| Measurement | Value |
|-------------|------:|
| Warm p50 (5 runs) | 0.454 s |
| Warm p95 (5 runs) | 0.932 s |
| Cold #1 (after 36 min idle) | 1.034 s |
| Cold #2 (5 s later) | 0.322 s |
| Cold #3 (5 s later) | 0.392 s |

### Design questions (Task 2)

**d) HF sleep vs Cloud Run scale-to-zero?**

Same idea — no traffic → no running container — but **wake time differs by orders of magnitude**. HF free Spaces optimize for **cost and sharing ML demos**, not sub-second API SLAs: cold wake includes scheduler, image pull/resume, and shared infra. Cloud Run targets **production HTTP** with faster scale-from-zero and tighter CPU/memory billing.

**e) Why `app_port: 8080`?**

HF defaults to **7860** (Gradio/Streamlit convention). QuickNotes listens on **8080** (`ADDR=:8080` in compose/Dockerfile). `app_port` tells the HF router which container port to proxy — without it, health checks hit the wrong port and the Space shows "container exited."

**f) Pull from ghcr vs build in Space?**

**Pull (chosen):** same digest as CI release — reproducible, faster HF build (no compile), matches "tag → registry → deploy" pipeline. **Build in Space:** self-contained if registry is down, but duplicates CI, slower builds, and can drift from `v0.1.0` unless carefully pinned.

---

## Bonus — Cloudflare Tunnel

**Attempted** — quick tunnel blocked (same as Lab 8):

```text
cloudflared tunnel --url http://127.0.0.1:8080
failed to request quick Tunnel: Post "https://api.trycloudflare.com/tunnel": context deadline exceeded
```

Outbound connectivity to `api.trycloudflare.com` times out from this network. Documented; comparison table uses HF measurements only unless tunnel becomes reachable.

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | 0.454 s | N/A (tunnel blocked) |
| Warm p95 | 0.932 s | N/A |
| Cold start | 1.034 s (first request after idle) | N/A (continuously local) |
| Public URL stability | stable | ephemeral on restart |
| Cost | free | free |

### Design questions (Bonus)

**g) Which is "really cloud" — HF vs Tunnel?**

HF runs **your container in their datacenter** — classic PaaS. Tunnel runs the app **on your machine**; only the **proxy path** uses Cloudflare's edge. Users see a public URL either way; for ops, HF is hosted cloud, Tunnel is **hybrid** (local compute + cloud network).

**h) Latency dominator for each?**

**HF warm:** network RTT to HF region + Space proxy overhead. **HF cold:** container wake + possible image layer fetch (seconds). **Tunnel warm:** RTT to nearest Cloudflare PoP + tunnel backhaul to your laptop — often dominated by **last-mile upload** and home ISP, not app CPU.

**i) When is Tunnel right vs wrong?**

**Right:** dev demos, home lab exposure, on-prem services without public IP, stakeholder previews without deploying. **Wrong:** production APIs needing HA, predictable latency, compliance-bound data residency, or when the laptop sleeping kills availability.

Tear down: [`cloud/teardown.md`](../cloud/teardown.md)

---

## Lab 10 completion checklist

### Task 1 (6 pts)

- [x] `release.yml` on `feature/lab10`
- [x] Tag `v0.1.0` pushed; image public on ghcr.io
- [x] Design questions a–c answered

### Task 2 (4 pts)

- [x] HF Space live; `/health` and `/notes` work
- [x] Warm + cold latency measured
- [x] Design questions d–f answered

### Bonus (2 pts)

- [x] Quick tunnel blocked on this network — documented with comparison table (HF only)

### Submission

- [x] Course PR: https://github.com/inno-devops-labs/DevOps-Intro/pull/1251
- [x] Fork PR: https://github.com/selysecr332/DevOps-Intro/pull/11
- [x] Moodle URL submitted
