# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud (No Card Required)

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Cloud%20%2B%20Edge-blue)
![points](https://img.shields.io/badge/points-10%2B2-orange)
![tech](https://img.shields.io/badge/tech-Render%20%2B%20Cloudflare-informational)

> **Goal:** Push the QuickNotes image to a real registry via CI (Task 1). Deploy to **Render** so it serves at a public URL (Task 2). Bonus: expose a local copy via **Cloudflare Tunnel** and compare cold-start / warm latency.
> **Deliverable:** A PR from `feature/lab10` to the course repo with the release workflow + `cloud/` artifacts + `submissions/lab10.md`. Submit the PR link via Moodle.

---

## Why these platforms?

> **Changed in September 2026:** Hugging Face now requires a paid plan to create Docker Spaces ([Spaces overview](https://huggingface.co/docs/hub/spaces-overview)), so Task 2 moved to Render. Render asks some new accounts to verify a card, and Russian cards fail there: if that happens to you, use **GitHub Codespaces** (Option B in Task 2). If you already finished Task 2 on an HF Space, it is still accepted.

Cloud Run, Fly.io, AWS Lambda all require a credit card on signup — a real blocker for Innopolis students. This lab uses two platforms that are **truly free, no card required, no quotas surprise**:

| Platform | What it gives you | Card required? |
|----------|-------------------|:--------------:|
| **GitHub Container Registry (`ghcr.io`)** | Public OCI image hosting; OIDC-friendly from Actions | ❌ |
| **Render** (free web service) | Runs your `ghcr.io` image; public `https://<service>.onrender.com` URL; spins down after 15 min idle (scale-to-zero, about 1 min to wake) | ❌ |
| **GitHub Codespaces** (fallback) | Cloud VM from your GitHub account, 120 compute hours/month free; a public port gets `https://<codespace>-8080.app.github.dev`; stops when idle, does not wake on requests | ❌ |
| **Cloudflare Tunnel** (`cloudflared`) | Exposes a local container at a public `https://<random>.trycloudflare.com` URL via Cloudflare's edge — zero account, zero card | ❌ |

You will deploy the **same image** to Render (or Codespaces) and Cloudflare Tunnel and *measure* the difference.

---

## Overview

By the end:
- A tag on `main` triggers CI to push QuickNotes to `ghcr.io`
- The image runs on Render at a public URL
- Scale-to-zero (Render spin-down) demonstrated; cold-vs-warm latency measured
- *(Bonus)* The same image served via Cloudflare Tunnel from a local container, latency compared

You will not be handed the workflow, the Render settings, or the Cloudflared commands.

---

## Project State

**Starting point:** Lab 6 image works locally; Lab 9 has hardened it; Lab 3 CI runs.

**After this lab:** Tagged release produces a publicly-reachable QuickNotes URL via automated CI.

---

## Prerequisites

- GitHub account (for ghcr.io, Lab 1 already)
- Render account ([dashboard.render.com/register](https://dashboard.render.com/register), sign in with GitHub; free, no card)
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

## Task 2 — Deploy to Render or Codespaces (4 pts)

Use **Option A (Render)**. If Render asks you for a card, switch to **Option B (Codespaces)**. Say which one you used and why.

### 2.1: Option A, Render: requirements

Create a **Render free web service** that runs QuickNotes:

1. In the Render dashboard: **New > Web Service**, instance type **Free** (the form pre-selects a paid plan: switch it), region closest to you (Frankfurt for most of you)
2. Pick the source (your choice, document why):
   - **Existing Image**: `ghcr.io/<you>/<repo>/quicknotes:v0.1.0` from Task 1 (public, no credentials), or
   - **your fork's Git repo** with the Lab 6 Dockerfile, so Render builds the image itself
3. **Make the port explicit.** Render routes to the port in its `PORT` variable (default `10000`). QuickNotes listens on `ADDR` (default `:8080`). If they differ, Render detects the real port and restarts the deploy (`New primary port detected` in the deploy log). Set environment variables so both agree from the first boot, without editing QuickNotes
4. Set the **health check path** to `/health`
5. Public URL `https://<service>.onrender.com` returns QuickNotes JSON for `/health`, `/notes`, etc.
6. **Deploy from CI:** add a step to your Task 1 release workflow that calls the service's **deploy hook** after the push, so a new tag redeploys Render. The hook URL is a secret: store it as a GitHub Actions secret, never in the repo

> Hint: for an image-backed service the deploy hook accepts an `imgURL` query parameter to pick the tag. See [Deploy hooks](https://render.com/docs/deploy-hooks).

Save what you configured in `cloud/render.md` (source, env vars, health check path, region), or as a `render.yaml` Blueprint if you prefer config as code.

### 2.1b: Option B, GitHub Codespaces: requirements

A codespace is a cloud VM for development. GitHub's terms allow it for testing your project, not for hosting production traffic, which is what this task does.

1. Add `.devcontainer/devcontainer.json` to your fork so that every codespace start runs your `ghcr.io/<you>/<repo>/quicknotes:v0.1.0` image and forwards port `8080`. Docker is not in every base image: pick an image or feature that provides it
2. Create a codespace on your fork (**Code > Codespaces**, or `gh codespace create`; the CLI needs `gh auth refresh -h github.com -s codespace` once)
3. Make port `8080` **public** (Ports tab, or `gh codespace ports visibility 8080:public -c <name>`). Visibility cannot be set in `devcontainer.json`
4. `https://<codespace>-8080.app.github.dev` returns QuickNotes JSON for `/health`, `/notes`, etc., from a machine that is not logged in to GitHub

Save `devcontainer.json` in the fork and copy it to `cloud/devcontainer.md` with the commands you ran.

### 2.2: Demonstrate scale-to-zero (Render spin-down)

Free web services **spin down** after 15 minutes without traffic. The next request wakes the service; that wait is the cold start.

1. **Warm latency:** make 5 consecutive requests immediately; record p50 (`curl -w '%{time_total}' -o /dev/null -s`)
2. **Idle for 20+ minutes** (the service spins down)
3. **Cold latency:** single request; record total time
4. Repeat the cold measurement 3 times (spin down, wake, spin down)
5. `POST` a note, let the service spin down, then `GET /notes` again. Record what happened to your note

**Option B:** a stopped codespace does not wake on a request, so measure a manual start instead. Record warm p50 as above, then 3 times: `gh codespace stop -c <name>`, curl the public URL (record what a stopped codespace returns), start it again from [github.com/codespaces](https://github.com/codespaces) (or `gh codespace ssh -c <name>`), and time until `/health` returns 200. Do step 5 too.

### 2.3: Tear down

When done, suspend or delete the service in its **Settings**, or leave it: free instance hours cost nothing. Codespaces: `gh codespace delete -c <name>`, because a stopped codespace still uses the 15 GB storage quota.

### 2.4: Design questions

- d) **Render spin-down vs Cloud Run scale-to-zero:** same idea, different orders of magnitude. Why is Render's wake so much slower? What does each platform optimize for?
- e) **Why does Render inject `PORT` instead of reading your `EXPOSE`?** Which env vars did you set, and what does the `New primary port detected` restart cost you on every mismatched deploy?
- f) **Existing image vs Render building from your repo:** what's the trade-off? (Hint: caching, reproducibility, the image you scanned in Lab 9.) Also explain where your note from 2.2 step 5 went.

Option B answers instead: d) a stopped codespace vs Render spin-down: which one wakes on a request, and why is that the line between a dev environment and a hosting platform? e) why do GitHub's terms forbid production hosting on Codespaces, and what would you need to add to QuickNotes on Codespaces to call it production? f) where did your note from step 5 go, and why is the answer different from Render's?

### 2.5: Document

In `submissions/lab10.md`:
- Your service URL + a `curl -v` against `/health`
- Option A: the deploy log lines showing the port QuickNotes started on, `cloud/render.md` (or `render.yaml`) + the deploy-hook step of your workflow
- Option B: `devcontainer.json`, `gh codespace ports -c <name>` output showing `8080` public
- Warm p50 latency
- Cold latencies (3 measurements) + the note-persistence result
- Design questions d, e, f answered

---

## Bonus Task — Cloudflare Tunnel + Cross-Platform Comparison (2 pts)

### B.1: Goal

Expose the **same** QuickNotes image to the public internet via **Cloudflare Tunnel** (`cloudflared`) — *zero account*, *zero card*, edge-routed via Cloudflare's network. Then **compare** the resulting latency against your Render service or codespace.

### B.2: Requirements

1. Install [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) on your local machine
2. Run QuickNotes locally (Lab 6 compose or `go run`)
3. Start a **quick tunnel** that exposes `http://localhost:8080` at a public `https://<random>.trycloudflare.com` URL — no Cloudflare account or domain needed for quick tunnels
4. Verify with `curl` from a *different* machine or your phone on cellular (proves it's really public)
5. Measure with `hyperfine` (or `wrk`): 50 runs, warm; record p50 and p95

> 💡 Quick tunnels give an **ephemeral** URL — it changes on each `cloudflared` restart. Named tunnels with stable URLs need a Cloudflare-managed domain (free Cloudflare account + you bring a domain). Quick tunnel is enough for this Bonus.

### B.3: Comparison table

Same QuickNotes, two delivery models. Build this table in `submissions/lab10.md`:

| Metric | Render / Codespace | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50               |                  ? |                                  ? |
| Warm p95               |                  ? |                                  ? |
| Cold start             |                  ? |  N/A (continuously local)          |
| Public URL stability   |             stable |               ephemeral on restart |
| Cost                   |               free |                               free |

### B.4: Design questions

- g) **Architectural difference:** on Render (or Codespaces) your container runs in someone else's datacenter; in Cloudflare Tunnel your container runs on *your laptop* and Cloudflare's edge proxies traffic in. Which one is "really cloud" — and does the distinction matter to your users?
- h) **Latency dominator** for each: in the Render or Codespaces case, what's the slow part of warm latency? In the Tunnel case, what's the slow part?
- i) **When would Cloudflare Tunnel actually be the right production pick?** (Hint: home labs, on-prem services exposed externally, dev URLs for stakeholder review.) When is it never the right pick?

---

## How to Submit

1. Release CI workflow + `cloud/` directory (containing `render.md`, `render.yaml` or `devcontainer.md`, and any tunnel config you wrote); Option B also needs `.devcontainer/devcontainer.json` in your fork
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
- ✅ Render service or codespace serves QuickNotes at a public URL; `/health` and `/notes` work
- ✅ Option A: a tag push redeploys Render through the deploy hook (secret, not committed). Option B: `devcontainer.json` starts QuickNotes on codespace start
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
| **Task 2** — Render or Codespaces deploy | **4** | Public URL, scale-to-zero observed, design questions |
| **Bonus** — Cloudflare Tunnel + comparison | **2** | Tunnel reachable from outside, table, design questions |
| **Total** | **10 + 2 bonus** | |

---

## Common Pitfalls

- 🪤 **Image not public on ghcr.io** — first push creates a *private* package. Flip visibility to public via the package's GH UI once
- 🪤 **Deploy takes about 45 s longer and logs `New primary port detected ... Restarting deploy`**: `PORT` and the port QuickNotes listens on differ. It still goes live, but fix the env vars
- 🪤 **Render shows a card verification screen** (a $1 hold, cancelled right after): Russian cards fail there. Do not look for workarounds, use Option B
- 🪤 **Codespace URL asks you to log in to GitHub**: port `8080` is still private. Check visibility again after every codespace restart
- 🪤 **Render cannot pull the image**: the ghcr.io package is still private, or it was built only for `arm64` (Render runs `linux/amd64`; Apple Silicon users build with `--platform linux/amd64`)
- 🪤 **Deploy hook returns `400 deploy hook cannot change the host, project, or image name`**: only the tag in `imgURL` may differ from the image the service was created with. URL-encode it (`%2F` for `/`, `%3A` for `:`)
- 🪤 **Service billed at $7/month**: the create form pre-selects a paid instance type. Pick **Free** before clicking Deploy; no card is asked for Free
- 🪤 **Cloudflare quick tunnel URL changed** when you restarted `cloudflared` — that's by design. For a stable URL you'd need a named tunnel + a domain
- 🪤 **Tunnel "404"** — the quick tunnel only proxies to the *exact* path you set in `--url`. If you set `http://localhost:8080`, then the tunnel serves QuickNotes at `https://<random>.trycloudflare.com/health`
- 🪤 **Forgot to tear down** — both options cost $0, but leave a `cloud/teardown.md` documenting how anyway

---

## Guidelines

- Both deploy targets are **truly free, no card**: that's the design intent. If you find yourself adding a credit card, you've gone off the rails. If neither Render nor Codespaces works for you, another card-free host that runs your `ghcr.io` image is accepted: say which one and why in the report
- Treat this as production rehearsal: tag, build, push, sign (Cosign — Lecture 9), deploy. The platform changes; the workflow doesn't
- For the bonus, measure from a *different* machine than the one running the tunnel — the latency you care about is what *users* see, not localhost-to-localhost
- Fix the port mismatch with configuration (`PORT` / `ADDR`), not by changing QuickNotes

---

## Resources

- 📖 [Render: Deploy for Free](https://render.com/docs/free) (limits, spin-down, ephemeral filesystem)
- 📖 [Render: Deploy a prebuilt Docker image](https://render.com/docs/deploying-an-image)
- 📖 [Render: Deploy hooks](https://render.com/docs/deploy-hooks)
- 📖 [Codespaces: Forwarding ports](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace) (public visibility, URL format)
- 📖 [Codespaces: billing and free quota](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces)
- 📖 [GitHub Container Registry docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- 📖 [`docker/build-push-action`](https://github.com/docker/build-push-action)
- 📖 [Cloudflare Tunnel — Quick tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/trycloudflare/)
- 📖 [Cloudflare Tunnel — Named tunnels (for later)](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/)
- 📝 [AWS us-east-1 December 2021 outage summary](https://aws.amazon.com/message/12721/) — even paid hyperscalers have bad days
- 🛠️ [`hyperfine`](https://github.com/sharkdp/hyperfine), [`cloudflared`](https://github.com/cloudflare/cloudflared)
