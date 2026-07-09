# Lab 10 Submission — QuickNotes to Cloud

## Task 1 — CI release → ghcr.io (push on tag)

### Release workflow
File: `.github/workflows/release.yml`

Workflow details:
- Triggers on tag `v*`
- Builds image from `app/`
- Pushes to `ghcr.io/ilyapechersky/devops-intro/quicknotes` with tags `${GITHUB_REF_NAME}` and `latest`
- Actions are SHA-pinned

### Evidence: tag → CI success
Release run (tag `v0.1.1`):
- https://github.com/IlyaPechersky/DevOps-Intro/actions/runs/28951114199

### Registry URL
- Image: `ghcr.io/ilyapechersky/devops-intro/quicknotes:v0.1.1`

### Evidence: clean pull
On the course VM server:
```text
$ docker pull ghcr.io/ilyapechersky/devops-intro/quicknotes:v0.1.1
Status: Downloaded newer image for ghcr.io/ilyapechersky/devops-intro/quicknotes:v0.1.1
```

Design questions:
- a) In-repo push to GHCR can be done with `GITHUB_TOKEN` (scoped to `packages: write`). OIDC is useful when you want to avoid long-lived tokens or when pushing to a different account/registry with stronger trust.
- b) `:latest` is a convenience pointer for humans and some tooling, while immutable `:vX.Y.Z` tags make releases reproducible and auditable.
- c) Narrow `packages: write` prevents an attacker from doing unrelated writes (`write: all`) like modifying repo content.

---

## Task 2 — Hugging Face Spaces (Docker SDK)

I attempted to create a public Docker Space on Hugging Face with the Docker SDK.

### Attempt result (blocked)
HF API error when creating Docker Space:
- `Static Spaces are free for everyone, but hosting Gradio and Docker Spaces on free cpu-basic requires a PRO subscription.`

I also checked the account capability via `whoami-v2`:
- `isPro=false`.

Because the account is not PRO and paid hardware requires pre-paid credits, I could not complete Task 2 (create the Space + measure warm/cold latency).

Artifacts prepared in this repo (for when the Space can be created):
- `cloud/Dockerfile`
- `cloud/README.md` (Spaces YAML frontmatter includes `sdk: docker` and `app_port: 8080`)

Design questions:
- d) (unanswered due to blocked Space creation)
- e) (unanswered due to blocked Space creation)
- f) (unanswered due to blocked Space creation)

---

## Bonus — Cloudflare Tunnel (public URL + latency)

### Quick tunnel URL
From server logs after running `cloudflared`:
- `https://investigators-martial-series-insert.trycloudflare.com/health`

### Reachability check
The tunnel served QuickNotes health successfully:
- `{"status":"ok","notes":0}` (after container start)

### Warm latency measurement (50 requests)
Measurement method: 50 sequential GET requests with Python `urllib.request` and recording wall-clock time.

Results:
- p50: ~190 ms
- p95: ~236 ms

Cold start is not applicable to the Tunnel comparison here because the container is continuously running locally for the measurement.

Comparison table (measured):
| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | N/A (blocked) | 190 ms |
| Warm p95 | N/A (blocked) | 236 ms |
| Cold start | N/A | N/A |
| Public URL stability | N/A | Ephemeral per restart |
| Cost | N/A | free |

Design questions:
- g) HF runs the container in their datacenter; Tunnel proxies traffic from your local container via Cloudflare’s edge. For users, both are “hosted URLs”, but operationally Tunnel is closer to local deployments with remote exposure.
- h) For Tunnel, the warm latency is dominated by request path (client → Cloudflare edge → your server) and your server’s response time. For hosted HF, warm latency dominator is usually platform routing + container/service startup overhead.
- i) Tunnel is good for local dev, demos, and exposing stakeholder URLs from home/on-prem; it’s usually not ideal for production unless you accept your laptop/on-prem as the origin.
