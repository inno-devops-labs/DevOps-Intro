# Lab 10 — Cloud: Ship QuickNotes to a Real Cloud

> **Status.** Task 1 is **done** — a signed `v0.1.0` tag fired the release workflow
> (green), pushed to ghcr.io, and the public image is verified anonymously pullable.
> Task 2 (Hugging Face Space) is **live** — public URL + warm/cold latency measured
> below. The Bonus (Cloudflare Tunnel) is documented but not run.

Artifacts: [`.github/workflows/release.yml`](../.github/workflows/release.yml),
[`cloud/Dockerfile`](../cloud/Dockerfile), [`cloud/README.md`](../cloud/README.md),
[`cloud/teardown.md`](../cloud/teardown.md).

---

## Task 1 — CI-automated push to `ghcr.io`

[`release.yml`](../.github/workflows/release.yml) triggers on `push` of a `v*` tag,
logs in to ghcr with the built-in `GITHUB_TOKEN`, derives tags with
`docker/metadata-action` (the immutable `{{version}}` **and** `latest`), and builds
`./app` + pushes to `ghcr.io/<owner>/<repo>/quicknotes`. `permissions:` is scoped
to `contents: read` + `packages: write`; all three `docker/*` actions are pinned by
40-char SHA (carried over from Lab 3). YAML validated.

**Done (live):** pushed a signed `v0.1.0` tag → the workflow ran **green**
([run 28883168854](https://github.com/RoukayaZaki/DevOps-Intro/actions/runs/28883168854)),
`Build and push → success`. Image published to
**`ghcr.io/roukayazaki/devops-intro/quicknotes`** with tags **`0.1.0`** and
**`latest`**.

The package was flipped to **public** in the GH UI (no API for
container-package visibility). **Verified anonymous clean pull** (logged out,
image removed first):
```
$ docker pull ghcr.io/roukayazaki/devops-intro/quicknotes:0.1.0
Status: Downloaded newer image ... Digest: sha256:3d5c6213...   (21.9 MB)
$ docker run ... && curl /health  ->  {"notes":4,"status":"ok"}
```

> Bug caught + fixed along the way: the first `release.yml` had inline `#` comments
> on the `metadata-action` `tags:` lines, which got baked into the tag names
> (`0.1.0-e.g.-v0.1.0-...`). Removed the inline comments and re-tagged — the second
> run produced the clean `0.1.0` + `latest`.

### Design questions

**a) OIDC vs `GITHUB_TOKEN`.** For pushing to ghcr from the *same* repo,
`GITHUB_TOKEN` with `packages: write` is enough. Reach for **OIDC** when pushing to
an *external* registry/cloud (AWS ECR, GCP Artifact Registry, Docker Hub): the
workflow exchanges a short-lived, signed identity token for cloud credentials, so
you store **no long-lived secrets** in the repo. OIDC gives keyless, short-lived,
auditable auth to third parties that `GITHUB_TOKEN` (scoped to GitHub only) can't
reach.

**b) Why ship `:latest` next to the immutable `:v0.1.0`?** `:latest` is mutable —
useless for reproducible deploys — but it's the convenient "current release"
pointer for humans, quickstart docs, and demos. Production **pins the immutable
`:v0.1.0`** (exact bytes, rollback-able). You ship both: `latest` for convenience,
the version tag for what you actually deploy.

**c) `packages: write` only — principle + attack prevented.** Least privilege:
grant only what the job needs. If this workflow (or a compromised action inside it)
is exploited, a narrow `packages: write` token can *only* push packages — it can't
push code, rewrite branches, edit releases, or change repo settings. A broad
`write: all` would let the attacker tamper with the source itself; the narrow scope
caps the blast radius.

---

## Task 2 — Deploy to Hugging Face Spaces

The Space is **live**: https://huggingface.co/spaces/GammaViolet/quicknotes,
serving at **https://gammaviolet-quicknotes.hf.space**. It's a Docker-SDK Space
that **builds from source** ([`cloud/Dockerfile`](../cloud/Dockerfile) — a
multi-stage build with the app source copied into the Space repo) rather than
pulling the ghcr image, so it's self-contained and doesn't depend on the ghcr
package being made public first. `DATA_PATH` points at `/tmp` (HF gives no writable
volume and runs an arbitrary UID); [`cloud/README.md`](../cloud/README.md)
frontmatter sets `sdk: docker` and **`app_port: 8080`** so HF routes to QuickNotes'
listener.

```
$ curl -s https://gammaviolet-quicknotes.hf.space/health
{"notes":4,"status":"ok"}
$ curl -s .../notes            # GET  -> 200, seeded notes
[{"id":1,"title":"Welcome to QuickNotes",...}, ...]
$ curl -X POST -d '{"title":"from-grader","body":"hi"}' .../notes   # -> 201 Created
{"id":5,"title":"from-grader","body":"hi","created_at":"2026-07-07T16:52:29Z"}
```
- **Warm p50: 0.565 s** (5 consecutive requests, 0.550–0.595 s)
- **Cold start (3×): 26.3 s, 9.3 s, 9.7 s** — time from waking a paused Space to
  the first `200` (pause→restart; forcing the free-tier *idle*-sleep wasn't
  practical to script, so I paused it to force the scale-from-zero wake). The first
  wake is slowest; tens of seconds either way — consistent with design (d).

### Design questions

**d) HF "sleep" vs Cloud Run "scale-to-zero".** Same idea, very different wake
time. HF's wake is tens of seconds because the free tier pulls and cold-starts a
full container from shared, oversubscribed infrastructure optimized for *cost* and
ML demos, not request latency. Cloud Run keeps images warm-close to the runtime,
has start paths engineered for fast request serving, and a paid SLA — it optimizes
for **latency**; HF optimizes for **free hosting**.

**e) Why `app_port: 8080`?** HF defaults to **7860** — the Gradio/Streamlit port,
because most Spaces are ML demos built on those frameworks. QuickNotes listens on
8080, so `app_port: 8080` tells HF's proxy where to send traffic. Without it HF
probes 7860, finds nothing, and the Space looks dead.

**f) Pull the ghcr image vs build in the Space.** Pulling the prebuilt image is
faster to start and means *the exact artifact CI tested runs* — no drift — but it
requires the ghcr package to be public and adds a registry dependency. Building in
the Space keeps it self-contained and editable in place, at the cost of a slower
first build and possible drift from CI. **I chose build-from-source** here: it made
the Space work end-to-end on its own (no ghcr public-flip in the loop), which was
the pragmatic call. For a real release I'd pull the CI-scanned image so
tested-artifact == deployed-artifact.

---

## Bonus — Cloudflare Tunnel + comparison

Approach (zero account, zero card): run QuickNotes locally, then
`cloudflared tunnel --url http://localhost:8080` → public
`https://<random>.trycloudflare.com`. Verify from a *different* network (phone on
cellular), then `hyperfine` 50 runs for p50/p95.

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | **0.565 s** | not run (bonus) |
| Warm p95 | ~0.60 s | not run (bonus) |
| Cold start | **9–26 s** (pause→wake) | N/A (always-on locally) |
| URL stability | stable | ephemeral (changes on restart) |
| Cost | free | free |

Not executed: needs `cloudflared` installed and a public exposure of the local app.

### Design questions

**g) Which is "really cloud"?** HF Spaces — the container runs in HF's datacenter.
With Cloudflare Tunnel the container runs on **your laptop** and Cloudflare's edge
just proxies traffic in; that's your machine exposed, not cloud compute. To users
the happy path looks identical (both are public HTTPS URLs), so the distinction is
about *who owns and runs the compute* and its availability — your laptop sleeping
means the Tunnel is down, while the Space keeps serving.

**h) Latency dominator.** HF: *warm* latency is network RTT to HF's datacenter plus
the (tiny) handler; *cold* latency is dominated by image pull + container start
(tens of seconds). Tunnel: the dominant cost is the round trip out to Cloudflare's
edge and back to your laptop (your home uplink + the extra hop), not the app code.

**i) When is Cloudflare Tunnel the right production pick — and never?** Right for
exposing on-prem / home-lab services or anything that must stay on your own
hardware (data residency, special hardware) without opening firewall ports, and for
sharing dev URLs with stakeholders. **Never** when you need real availability and
scale independent of your machine, or low/stable global latency — your laptop isn't
a datacenter, and a quick-tunnel URL isn't stable.

---

## Summary

| Task | Status |
|------|--------|
| 1 — Tag → CI → ghcr.io | ✅ `v0.1.0` → **green release run** → `ghcr.io/.../quicknotes:0.1.0,latest`, **public + anonymous pull verified** |
| 2 — HF Spaces deploy | ✅ **live** at https://gammaviolet-quicknotes.hf.space, `app_port: 8080`, warm p50 0.565 s, cold 9–26 s |
| Bonus — Cloudflare Tunnel | approach + comparison documented; measurements not run |
| Design questions a–i | ✅ complete |
