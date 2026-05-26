# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud (No Card Required)

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Cloud%20%2B%20Edge-blue)
![points](https://img.shields.io/badge/points-10%2B2-orange)
![tech](https://img.shields.io/badge/tech-HF%20Spaces%20%2B%20Cloudflare-informational)

> **Goal:** Push the QuickNotes image to a real registry via CI (Task 1). Deploy to **Hugging Face Spaces** so it serves at a public URL (Task 2). Bonus: expose a local copy via **Cloudflare Tunnel** and compare cold-start / warm latency.
> **Deliverable:** A PR from `feature/lab10` to the course repo with the release workflow + `cloud/` artifacts + `submissions/lab10.md`. Submit the PR link via Moodle.

---

## Why these platforms?

Cloud Run, Fly.io, AWS Lambda all require a credit card on signup — a real blocker for Innopolis students. This lab uses two platforms that are **truly free, no card required, no quotas surprise**:

| Platform | What it gives you | Card required? |
|----------|-------------------|:--------------:|
| **GitHub Container Registry (`ghcr.io`)** | Public OCI image hosting; OIDC-friendly from Actions | ❌ |
| **Hugging Face Spaces** (Docker SDK) | Hosted Docker container; auto-builds; public `https://<user>-<space>.hf.space` URL; sleeps after ~30 min idle (scale-to-zero with a slow cold start) | ❌ |
| **Cloudflare Tunnel** (`cloudflared`) | Exposes a local container at a public `https://<random>.trycloudflare.com` URL via Cloudflare's edge — zero account, zero card | ❌ |

You will deploy the **same image** to both HF Spaces and Cloudflare Tunnel and *measure* the difference.

---

## Overview

By the end:
- A tag on `main` triggers CI to push QuickNotes to `ghcr.io`
- The image runs on Hugging Face Spaces at a public URL
- Scale-to-zero (HF "sleep") demonstrated; cold-vs-warm latency measured
- *(Bonus)* The same image served via Cloudflare Tunnel from a local container, latency compared

You will not be handed the workflow, the Spaces config, or the Cloudflared commands.

---

## Project State

**Starting point:** Lab 6 image works locally; Lab 9 has hardened it; Lab 3 CI runs.

**After this lab:** Tagged release produces a publicly-reachable QuickNotes URL via automated CI.

---

## Prerequisites

- GitHub account (for ghcr.io, Lab 1 already)
- Hugging Face account ([huggingface.co/join](https://huggingface.co/join) — free, no card)
- *(Bonus)* `cloudflared` installed locally
- Lab 6 Dockerfile + Lab 3 CI workflow

---

## Task 1 — CI-Automated Push to `ghcr.io` (6 pts)

### 1.1: Requirements

Add a **new** CI workflow (e.g. `.github/workflows/release.yml`) that:

1. **Triggers on push of a Git tag** matching `v*` (semver)
2. **Builds** the QuickNotes image from `app/`
3. **Pushes** to **`ghcr.io/<your-org-or-user>/<repo>/quicknotes`**
4. Tags both `<your version>` and `latest`
5. **Permissions** scoped to the minimum — `packages: write` for ghcr is the bar
6. **All third-party actions pinned by 40-char SHA** (carrying forward from Lab 3)
7. Image is **publicly pullable** after the workflow succeeds — `docker pull <URL>` from a clean machine works without auth (you may need to flip the package's visibility to "public" once in the GH UI on first push)

### 1.2: Design questions

- a) **OIDC vs `GITHUB_TOKEN`** — for pushing to ghcr.io from the same repo, `GITHUB_TOKEN` with `packages: write` is enough. When would you reach for OIDC instead, and what does it give you that `GITHUB_TOKEN` doesn't?
- b) **`:latest` tag vs `:v0.1.0` immutable tag** — Lab 6 covered why `:latest` is mutable. So why do you still ship a `:latest` tag alongside the immutable one in production releases?
- c) **`packages: write` scope only** — what's the principle, and what concrete attack does the *narrow* scope prevent vs `write: all`?

### 1.3: Where to start

- 📖 [GitHub Container Registry — Working with the registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- 📖 [`docker/build-push-action`](https://github.com/docker/build-push-action)
- 📖 [GitHub Actions — Publishing Docker images](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)

### 1.4: Tag a release

```bash
git tag -a -s v0.1.0 -m "Lab 10 release"
git push origin v0.1.0
```

Workflow fires → builds → pushes. Verify by pulling on a clean machine (or your laptop after `docker rmi`).

### 1.5: Document

In `submissions/lab10.md`:
- Your release workflow (paste or link)
- The registry URL where the image lives + evidence of a successful clean pull
- A green CI release-run URL
- Design questions a-c answered

---

## Task 2 — Deploy to Hugging Face Spaces (4 pts)

### 2.1: Requirements

Create a **Hugging Face Space** with the **Docker SDK** that runs QuickNotes:

1. **Create the Space** at [huggingface.co/new-space](https://huggingface.co/new-space) — Docker SDK, public visibility
2. The Space is its own Git repository. Clone it locally; **add files** to make it run QuickNotes:
   - A small `Dockerfile` that pulls your `ghcr.io/...:v0.1.0` image *or* multi-stage builds from the `app/` source (your choice — document why)
   - A `README.md` whose **YAML frontmatter** declares the Space metadata: at minimum the SDK, the app port (HF defaults to 7860 — you need to set `app_port: 8080` since QuickNotes listens on 8080), and a title/emoji
3. Push to the Space's Git remote → HF builds and serves automatically
4. Public URL `https://<user>-<spacename>.hf.space` returns QuickNotes JSON for `/health`, `/notes`, etc.

> 💡 The Space's `README.md` frontmatter is a small YAML block at the top of the file enclosed by `---` lines. See [Spaces config reference](https://huggingface.co/docs/hub/spaces-config-reference) — figure out which keys you need from the spec.

### 2.2: Demonstrate "scale-to-zero" (HF "sleep")

HF Spaces on free tier **sleep** after ~30 minutes of inactivity. The wake-up is the cold start.

1. **Warm latency:** make 5 consecutive requests immediately; record p50 (`curl -w '%{time_total}' -o /dev/null -s`)
2. **Idle for 35+ minutes** (the Space sleeps)
3. **Cold latency:** single request; record total time
4. Repeat the cold measurement 3 times (sleep → wake → sleep)

### 2.3: Tear down

When done, delete the Space from your HF account settings — or leave it running, it costs nothing.

### 2.4: Design questions

- d) **HF Spaces "sleep" vs Cloud Run "scale to zero"** — same idea, different orders of magnitude. Why is HF's wake so much slower? What does the platform optimize for differently?
- e) **Why does the Space need `app_port: 8080`?** What's HF's default and why do they default to that?
- f) **You pulled the image from ghcr.io into the Space.** What's the trade-off vs building the Dockerfile inside the Space? (Hint: caching, reproducibility, debug-ability.)

### 2.5: Document

In `submissions/lab10.md`:
- Your Space URL + a `curl -v` against `/health`
- The Space repo's `Dockerfile` + `README.md` (paste or link)
- Warm p50 latency
- Cold latencies (3 measurements)
- Design questions d, e, f answered

---

## Bonus Task — Cloudflare Tunnel + Cross-Platform Comparison (2 pts)

### B.1: Goal

Expose the **same** QuickNotes image to the public internet via **Cloudflare Tunnel** (`cloudflared`) — *zero account*, *zero card*, edge-routed via Cloudflare's network. Then **compare** the resulting latency against your HF Space.

### B.2: Requirements

1. Install [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) on your local machine
2. Run QuickNotes locally (Lab 6 compose or `go run`)
3. Start a **quick tunnel** that exposes `http://localhost:8080` at a public `https://<random>.trycloudflare.com` URL — no Cloudflare account or domain needed for quick tunnels
4. Verify with `curl` from a *different* machine or your phone on cellular (proves it's really public)
5. Measure with `hyperfine` (or `wrk`): 50 runs, warm; record p50 and p95

> 💡 Quick tunnels give an **ephemeral** URL — it changes on each `cloudflared` restart. Named tunnels with stable URLs need a Cloudflare-managed domain (free Cloudflare account + you bring a domain). Quick tunnel is enough for this Bonus.

### B.3: Comparison table

Same QuickNotes, two delivery models. Build this table in `submissions/lab10.md`:

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50               |                  ? |                                  ? |
| Warm p95               |                  ? |                                  ? |
| Cold start             |                  ? |  N/A (continuously local)          |
| Public URL stability   |             stable |               ephemeral on restart |
| Cost                   |               free |                               free |

### B.4: Design questions

- g) **Architectural difference:** in HF Spaces your container runs in HF's datacenter; in Cloudflare Tunnel your container runs on *your laptop* and Cloudflare's edge proxies traffic in. Which one is "really cloud" — and does the distinction matter to your users?
- h) **Latency dominator** for each: in the HF case, what's the slow part of warm latency? In the Tunnel case, what's the slow part?
- i) **When would Cloudflare Tunnel actually be the right production pick?** (Hint: home labs, on-prem services exposed externally, dev URLs for stakeholder review.) When is it never the right pick?

---

## How to Submit

1. Release CI workflow + `cloud/` directory (containing the Space's Dockerfile + README and any tunnel config you wrote) in your fork
2. Tagged release exists on `origin`
3. `submissions/lab10.md` covers all attempted tasks
4. PR from `feature/lab10` → course repo's `main`
5. Submit the PR URL via Moodle

---

## Acceptance Criteria

### Task 1 (6 pts)
- ✅ Tagged release triggers the workflow
- ✅ Image is in `ghcr.io`, publicly pullable from a clean machine
- ✅ All third-party actions SHA-pinned
- ✅ Design questions a-c answered

### Task 2 (4 pts)
- ✅ HF Space serves QuickNotes at a public URL
- ✅ `app_port: 8080` correctly set; `/health` and `/notes` work
- ✅ Cold-vs-warm latency measured (3 cold samples)
- ✅ Design questions d-f answered

### Bonus Task (2 pts)
- ✅ Quick tunnel exposes QuickNotes publicly
- ✅ Verified reachable from a *different* network (cellular / different IP)
- ✅ Comparison table populated from real measurements
- ✅ Design questions g, h, i answered

---

## Rubric

| Task | Points | Criteria |
|------|-------:|----------|
| **Task 1** — Tag → CI → ghcr.io | **6** | Workflow correct, image pullable, design questions |
| **Task 2** — HF Spaces deploy | **4** | Public URL, scale-to-zero observed, design questions |
| **Bonus** — Cloudflare Tunnel + comparison | **2** | Tunnel reachable from outside, table, design questions |
| **Total** | **10 + 2 bonus** | |

---

## Common Pitfalls

- 🪤 **Image not public on ghcr.io** — first push creates a *private* package. Flip visibility to public via the package's GH UI once
- 🪤 **HF Space "build failed"** — read the build logs in the Space UI; usually the Dockerfile has a missing dependency or wrong base image platform (HF runs `linux/amd64`)
- 🪤 **HF Space "container exited"** — your app crashed; check Space logs. Most common cause: wrong `app_port`, app not listening on `0.0.0.0`
- 🪤 **HF cold start is *very* slow on first deploy** (image pull) — subsequent wakes are faster but still seconds, not ms
- 🪤 **Cloudflare quick tunnel URL changed** when you restarted `cloudflared` — that's by design. For a stable URL you'd need a named tunnel + a domain
- 🪤 **Tunnel "404"** — the quick tunnel only proxies to the *exact* path you set in `--url`. If you set `http://localhost:8080`, then the tunnel serves QuickNotes at `https://<random>.trycloudflare.com/health`
- 🪤 **Forgot to tear down** — both options cost $0, but leave a `cloud/teardown.md` documenting how anyway

---

## Guidelines

- Both deploy targets are **truly free, no card** — that's the design intent. If you find yourself adding a credit card, you've gone off the rails
- Treat this as production rehearsal: tag, build, push, sign (Cosign — Lecture 9), deploy. The platform changes; the workflow doesn't
- For the bonus, measure from a *different* machine than the one running the tunnel — the latency you care about is what *users* see, not localhost-to-localhost
- `app_port: 8080` is HF's escape hatch from their port-7860 default. Use it. Don't change QuickNotes itself

---

## Resources

- 📖 [Hugging Face Spaces — Docker Spaces overview](https://huggingface.co/docs/hub/spaces-sdks-docker)
- 📖 [Hugging Face Spaces — Config reference](https://huggingface.co/docs/hub/spaces-config-reference)
- 📖 [GitHub Container Registry docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- 📖 [`docker/build-push-action`](https://github.com/docker/build-push-action)
- 📖 [Cloudflare Tunnel — Quick tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/trycloudflare/)
- 📖 [Cloudflare Tunnel — Named tunnels (for later)](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/)
- 📝 [AWS us-east-1 December 2021 outage summary](https://aws.amazon.com/message/12721/) — even paid hyperscalers have bad days
- 🛠️ [`hyperfine`](https://github.com/sharkdp/hyperfine), [`cloudflared`](https://github.com/cloudflare/cloudflared)
