# Lab 10 Submission
## Task 1 — CI-Automated Push to ghcr.io

### 1.1 Release Workflow

Workflow: `.github/workflows/release.yml`
Trigger: push of `v*` tag
Actions pinned by SHA digest.

Registry URL: `ghcr.io/linxel/devops-intro/quicknotes:v0.1.0`

Evidence:
- `docker pull ghcr.io/linxel/devops-intro/quicknotes:v0.1.0` — public
- CI run: https://github.com/linxel/DevOps-Intro/actions/runs/<RUN_ID>

### 1.2 Design Questions

**a) OIDC vs GITHUB_TOKEN — when OIDC?**

`GITHUB_TOKEN` with `packages: write` works for pushing to ghcr.io in the same repo. OIDC is needed when pushing to external registries (AWS ECR, Docker Hub) or across repos/orgs. OIDC gives short-lived tokens without storing secrets — GitHub Actions exchanges its identity for a cloud credential. It eliminates long-lived secret rotation.

**b) Why ship :latest alongside :v0.1.0?**

`:latest` is mutable — it's a convenience tag so users can `docker pull` without knowing the current version. `:v0.1.0` is immutable — it pins a specific build for reproducibility and rollback. Production deploys use the immutable tag; `:latest` is for documentation and quick demos.

**c) packages: write only — what attack does narrow scope prevent?**

Principle of least privilege. With `write: all`, a compromised workflow could push to any package, modify releases, or write to the repo itself. With only `packages: write`, even if the workflow is compromised, the attacker cannot modify source code or releases — they can only push containers.

---

## Task 2 — Hugging Face Spaces

### 2.1 Space URL

https://ksunia-quicknotes.hf.space

- `/health` → `{"notes":2,"status":"ok"}`
- `/notes` → returns notes array

Space Dockerfile builds from source (Go multi-stage build).
README.md includes `app_port: 8080`.

### 2.2 Latency Measurements

**Warm (p50):** ~0.75s (5 consecutive requests)
**Cold start (estimated):** HF Spaces sleep after ~30 min idle. Wake-up is 3-5s based on HF free tier behavior.

### 2.3 Design Questions

**d) HF Spaces sleep vs Cloud Run scale-to-zero**

HF free tier sleeps after ~30 min of inactivity. Wake-up involves pulling the container image + starting the process — seconds, not milliseconds. Cloud Run scale-to-zero happens per-request and wakes in ms because it keeps warm instances pre-allocated. HF optimizes for cost (free GPU demos); Cloud Run optimizes for latency.

**e) Why app_port: 8080?**

HF defaults to port 7860 (Gradio convention). QuickNotes listens on 8080. Without `app_port: 8080`, HF probes port 7860, gets no response, and marks the Space as unhealthy.

**f) Pull vs build in Space — trade-off**

Building from source: self-contained, no external registry dependency, HF caches layers. Pulling from ghcr.io: faster first build (no compilation), but HF couldn't authenticate to ghcr.io even for public images. For this lab, building from source was chosen.

---

## Bonus Task

Not attempted.

---

## Files

- `.github/workflows/release.yml`
- `cloud/` directory (Space Dockerfile + README)
- `submissions/lab10.md`
