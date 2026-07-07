# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud

## Task 1 — CI-Automated Push to `ghcr.io`

### 1.1 Release workflow

[`.github/workflows/release.yml`](../.github/workflows/release.yml):

```yaml
name: Release

permissions:
  contents: read

on:
  push:
    tags:
      - 'v*'

jobs:
  push-image:
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Compute image ref
        id: image
        run: |
          repo_lower="${GITHUB_REPOSITORY,,}"
          version="${GITHUB_REF_NAME#v}"
          echo "name=ghcr.io/${repo_lower}/quicknotes" >> "$GITHUB_OUTPUT"
          echo "version=${version}" >> "$GITHUB_OUTPUT"

      - uses: docker/login-action@af1e73f918a031802d376d3c8bbc3fe56130a9b0 # v4.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@53b7df96c91f9c12dcc8a07bcb9ccacbed38856a # v7.3.0
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ${{ steps.image.outputs.name }}:${{ steps.image.outputs.version }}
            ${{ steps.image.outputs.name }}:latest
```

Requirements checklist:
1. ✅ Triggers only on `v*` tag pushes (`on.push.tags`)
2. ✅ Builds from the repo root (`context: .`, `file: ./Dockerfile`) — the same `Dockerfile` Lab 6/9 use, which `COPY`s `app/` in
3. ✅ Pushes to `ghcr.io/<owner>/<repo>/quicknotes`, computed dynamically from `GITHUB_REPOSITORY` (lowercased — ghcr.io requires lowercase repo paths) so the workflow works unmodified on any fork
4. ✅ Tags both the version from the pushed tag (`v0.1.0` → `0.1.0`) and `latest`
5. ✅ Permissions scoped to `contents: read` + `packages: write` at the job level — nothing else
6. ✅ All third-party actions pinned by 40-char commit SHA (`actions/checkout`, `docker/login-action`, `docker/build-push-action`), resolved from each action's real tag via `git ls-remote --tags`, with the human-readable version kept as a trailing comment
7. ✅ Validated with `actionlint` (clean) and a local `docker build -f Dockerfile .` using the same context/file args before pushing

### 1.2 Tagging and pushing

```bash
git tag -a -s v0.1.0 -m "Lab 10 release"
git push origin v0.1.0
```

**Green run:** [`https://github.com/ilnarkhasanov/DevOps-Intro/actions/runs/28875009581`](https://github.com/ilnarkhasanov/DevOps-Intro/actions/runs/28875009581) — `push-image` job succeeded in 37s.

**Registry:** `ghcr.io/ilnarkhasanov/devops-intro/quicknotes`, tagged `0.1.0` and `latest` (the workflow strips the leading `v` from the git tag, so `v0.1.0` → image tag `0.1.0`).

**Clean-pull evidence** — package flipped to public in the GH UI, then pulled with no `docker login` at all (`docker logout ghcr.io` run first to prove it):

```
$ docker logout ghcr.io
Removing login credentials for ghcr.io

$ docker pull ghcr.io/ilnarkhasanov/devops-intro/quicknotes:latest
latest: Pulling from ilnarkhasanov/devops-intro/quicknotes
Digest: sha256:b1ae825a2c42a6cc66ca2dfd3fd3054270ea2ea143c8280a5e3cd108644c856a
Status: Downloaded newer image for ghcr.io/ilnarkhasanov/devops-intro/quicknotes:latest

$ docker pull ghcr.io/ilnarkhasanov/devops-intro/quicknotes:0.1.0
0.1.0: Pulling from ilnarkhasanov/devops-intro/quicknotes
Digest: sha256:b1ae825a2c42a6cc66ca2dfd3fd3054270ea2ea143c8280a5e3cd108644c856a
Status: Downloaded newer image for ghcr.io/ilnarkhasanov/devops-intro/quicknotes:0.1.0
```

Both tags resolve to the identical digest (`sha256:b1ae825a...`), confirming `:latest` and `:0.1.0` point at the same build, as intended. Ran the pulled image (`docker run ... ghcr.io/ilnarkhasanov/devops-intro/quicknotes:0.1.0`) and confirmed it serves correctly, including the Lab 9 security headers:

```
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'
Content-Type: application/json
Cross-Origin-Resource-Policy: same-origin
X-Content-Type-Options: nosniff

{"notes":0,"status":"ok"}
```

### 1.3 Design questions

**a) OIDC vs `GITHUB_TOKEN` — when would you reach for OIDC instead?**
For pushing to `ghcr.io` from a workflow running *in the same repository* it's pushing to, the ephemeral, repo-scoped `GITHUB_TOKEN` (with `packages: write`) is sufficient and simpler — GitHub mints and revokes it automatically per workflow run, so there's no long-lived secret to manage. OIDC earns its complexity when the *target* is a **different** trust domain that can't consume a GitHub-issued token directly — pushing to AWS ECR, Azure ACR, or GCP Artifact Registry, deploying to a cloud provider, or signing with an external KMS. There, the workflow exchanges its GitHub-issued OIDC token for short-lived cloud credentials via a trust relationship configured once on the cloud side, so you never store a static cloud access key as a GitHub secret at all. The win isn't security theater — it's removing a long-lived credential that could leak from Actions logs, forks, or a compromised dependency, in favor of a token that's scoped to *this run*, *this repo*, and expires when the job ends.

**b) Why ship `:latest` alongside the immutable `:v0.1.0` tag?**
`:latest` is for humans and tooling doing "give me whatever's current" without wanting to track version numbers — a quick `docker pull ghcr.io/.../quicknotes:latest` for local testing, a doc example, or a dev/staging manifest that intentionally always wants the newest build. It's never meant for anything that needs reproducibility or rollback — those pin `:v0.1.0` (or better, the immutable digest) so "what's actually running" is answerable months later even after ten more tags have shipped. Shipping both isn't a contradiction: `:latest` is a *convenience alias* pointed at whatever the most recent immutable tag is, not a substitute for it. Production deployments should always reference the immutable tag/digest; `:latest` rides along for everyone else.

**c) `packages: write` scope only — what attack does the narrow scope prevent?**
The principle is least privilege applied to the *ephemeral* `GITHUB_TOKEN`: a workflow run should only be able to do the one thing it's actually there to do. This workflow's job needs to push an image to `ghcr.io` and nothing else, so the job-level `permissions:` block grants exactly `contents: read` (to check out the repo) and `packages: write` (to push) — no `contents: write`, no `issues: write`, no `actions: write`. The concrete attack this blocks: if a dependency in the build step (or a malicious PR that somehow triggers this workflow) manages to run arbitrary code inside the job, the blast radius is capped at "can push a package" — it *cannot* rewrite repository contents, open/modify PRs, edit other workflows, or touch anything else `GITHUB_TOKEN` could reach under the repository's default (broader) permission set. `write-all` would hand a compromised build step every one of those capabilities simultaneously; scoping to exactly what's needed turns a potential full-repo-compromise into a much smaller, contained one.

---

## Task 2 — Deploy to Hugging Face Spaces

### 2.1 Space files

[`cloud/hf-space/Dockerfile`](../cloud/hf-space/Dockerfile):

```dockerfile
# Hugging Face Space (Docker SDK). Pulls the Lab 10 release image built and
# pushed by CI rather than rebuilding from app/ source — see submissions/lab10.md
# design question (f) for the trade-off.
FROM ghcr.io/ilnarkhasanov/devops-intro/quicknotes:0.1.0

# The base is FROM scratch (no shell, no pre-existing directories), so a /data
# directory can't be created with `RUN mkdir`. COPY --chown creates it instead,
# owned by the nonroot UID (65532) the binary runs as, so it's writable at runtime.
COPY --chown=65532:65532 data-placeholder /data

ENV DATA_PATH=/data/notes.json
```

[`cloud/hf-space/README.md`](../cloud/hf-space/README.md) frontmatter:

```yaml
---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: purple
sdk: docker
app_port: 8080
pinned: false
short_description: Minimal Go notes JSON API (DevOps-Intro Lab 10)
---
```

**Why pull from `ghcr.io` instead of multi-stage building from `app/` source:** the image is already built, tested (Lab 3 CI), scanned (Lab 9), and hardened (security-headers middleware) by the time it lands in the registry — rebuilding it inside the Space would duplicate that pipeline and risk drifting from what CI actually verified. Trade-offs are covered in design question (f) below.

**The `/data` permission problem:** the base image is `FROM scratch`, so it has no shell and no pre-existing directories — running the pulled image directly (`docker run ghcr.io/.../quicknotes:0.1.0`, no volume) fails with `mkdir /data: permission denied`, because the nonroot UID (65532) the binary runs as can't create new top-level directories on the container's root filesystem, and there's no `RUN mkdir` available since scratch has no `/bin/sh`. `COPY --chown=65532:65532 data-placeholder /data` sidesteps this: Docker creates `/data` (from an empty local directory) already owned by the right UID, no shell required. Verified locally — built `cloud/hf-space/Dockerfile`, ran it with **no** volumes or env overrides (exactly how HF would run it), and confirmed `/health` (200) and `POST /notes` (201, persisted) both work.

### 2.2 Deployed Space

**URL:** [`https://ilnarkhasanov-quicknotes.hf.space`](https://ilnarkhasanov-quicknotes.hf.space)

```
$ curl -v https://ilnarkhasanov-quicknotes.hf.space/health
...
* SSL certificate verify ok.
* using HTTP/2
> GET /health HTTP/2
> Host: ilnarkhasanov-quicknotes.hf.space
...
< HTTP/2 200
< content-type: application/json
< content-length: 26
< cache-control: no-store
< content-security-policy: default-src 'none'
< cross-origin-resource-policy: same-origin
< x-content-type-options: nosniff
< x-proxied-host: http://10.112.152.244
< x-proxied-replica: 0cpph7ro-67fdp
< link: <https://huggingface.co/spaces/ilnarkhasanov/quicknotes>;rel="canonical"
...
{"notes":0,"status":"ok"}
```

The Lab 9 security headers (`Content-Security-Policy`, `X-Content-Type-Options`, `Cross-Origin-Resource-Policy`, `Cache-Control`) ride through HF's proxy untouched — confirming the same image that passed Lab 9's ZAP re-scan is what's actually running here. `x-proxied-*` and `link` headers are added by HF's own reverse proxy in front of the container.

### 2.3 Scale-to-zero: warm/cold latency

**Warm p50** — 5 consecutive requests immediately after confirming the Space was awake:

```
$ for i in 1 2 3 4 5; do curl -s -o /dev/null -w "req $i: %{time_total}s\n" https://ilnarkhasanov-quicknotes.hf.space/health; done
req 1: 0.634s
req 2: 0.655s
req 3: 0.595s
req 4: 0.512s
req 5: 0.514s
```

Sorted: 0.512, 0.514, 0.595, 0.634, 0.655 → **p50 ≈ 0.595s**. (This is round-trip time from a residential connection to HF's AWS-hosted edge, not localhost — includes real network RTT, not just container processing.)

**Cold latencies (3 measurements):**

| # | Idle time before request | Latency |
|---|--------------------------|---------|
| 1 | ~35 min | 0.830s |
| 2 | ~35 min | 0.940s |
| 3 | ~35 min | 1.051s |

Mean cold latency: **≈0.94s**, vs. warm p50 of 0.595s — roughly +0.35s (+58%), and the three readings step up nearly linearly (0.83 → 0.94 → 1.05) rather than jumping unpredictably, which reads as measurement noise/network variance layered on a consistently small base, not three different cold-start regimes.

**Conclusion:** the data supports explanation (a), not (b). If the Space had simply never gone idle across all three ~35-minute windows, its warm latency should already have converged to something close to the 0.595s p50 measured earlier the same session — instead every cold reading is durably ~0.3–0.5s *above* warm, a small but repeatable gap consistent with a real (if modest) cold-start cost. What's notable is the *size* of that gap: HF's own docs warn cold starts are "seconds, not ms," implying multi-second wakes — QuickNotes' wake cost is sub-second. The explanation is the image: 5.87 MB, `FROM scratch`, one static Go binary, no interpreter boot, no model-weight load. A cold start here is "schedule a container, pull ~6 MB (likely still layer-cached on HF's node from the last run), exec one binary" — there's just very little work to do. HF's "seconds, not ms" framing describes the platform's typical workload (multi-GB ML images with heavyweight runtime init), not a hard platform floor; QuickNotes' cold start is fast *because the image is small*, not because HF's sleep/wake mechanism is unusually fast.

### 2.4 Design questions

**d) HF Spaces "sleep" vs Cloud Run "scale to zero" — why is HF's wake so much slower?**
Cloud Run is built for exactly this: it keeps container images warm in an internal registry close to the compute, uses a fast, purpose-built container runtime, and is engineered so a cold start is typically low-hundreds-of-milliseconds to a couple of seconds for a small image — the whole product's pitch is "scale to zero without you noticing." HF Spaces optimizes for something else entirely: hosting arbitrary, often large, ML-oriented Docker images (multi-gigabyte containers with CUDA layers, model weights, etc.) on a **free tier**, where cost containment matters far more than wake latency. Free-tier HF Spaces sit on shared, oversubscribed infrastructure, and a sleeping Space's container is fully torn down, not paused — waking means a fresh scheduler placement and a full image pull, which for a *typical* HF Space (multi-GB, Python interpreter boot, model-weight loading) adds up to seconds-to-tens-of-seconds, well past Cloud Run's sub-second-to-low-seconds.

That said, our own measurement in 2.3 didn't show that gap — QuickNotes' cold reads were ~0.83–1.05s, only a few hundred ms above warm. That's consistent with the mechanism above, not a contradiction of it: the "seconds to tens of seconds" cost is dominated by *image pull + runtime boot*, both of which scale with image size and runtime complexity. A 5.87 MB `FROM scratch` static binary has almost none of either to pay for, so the same "tear down and reschedule" mechanism that's slow for a multi-GB ML Space is fast here. The platform-level reason HF is slower than Cloud Run in general still holds; QuickNotes just doesn't have enough weight to expose it.

**e) Why does the Space need `app_port: 8080`?**
HF's Docker SDK defaults to `7860` because that's Gradio's traditional default port — Spaces originally existed to host Gradio demos, and Docker SDK inherited that convention even though a Docker Space can run anything. QuickNotes listens on `8080` (its own default, unrelated to HF), so without `app_port: 8080` in the README frontmatter, HF's reverse proxy would forward traffic to `7860` where nothing is listening, and the Space would report "container exited" / unreachable even though the app started fine. `app_port` is purely a routing hint to HF's proxy — it changes nothing inside the container.

**f) Trade-off: pulling the ghcr.io image vs. building the Dockerfile inside the Space**
Pulling (this submission's choice) means the Space always runs *exactly* the artifact CI built and Lab 9 hardened — no risk of the Space's build producing a subtly different image than what was tested, and HF's build step is fast since it's just a registry pull plus one tiny `COPY`. The cost: HF's build cache buys nothing for the actual app layers (they're baked into the pulled image already), and debugging an app-level bug from the Space's build logs is a dead end — you'd have to reproduce it against the `ghcr.io` image locally, not iterate inside the Space. Building from `app/` source directly inside the Space would give HF's own layer cache a chance to speed up iterative `go build` changes and put full build logs in one place, but at the cost of maintaining a second build path that could drift from the CI-verified Dockerfile, and duplicating work CI already did on every tag.
