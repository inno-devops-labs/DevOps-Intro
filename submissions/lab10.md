# Lab 10 — Cloud: Ship QuickNotes to a Real Cloud

> **Execution note.** This lab is cloud-bound — it needs a Git **push** of a tag
> (to fire CI → ghcr.io), a **Hugging Face account** (to host the Space), and a
> public **tunnel**. Per the request, nothing was pushed and no accounts were used,
> so the live URLs / latency numbers below are marked **PENDING**. The artifacts
> (release workflow, Space `Dockerfile` + `README.md`, teardown) are complete and
> validated, and every design question is answered.

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

**To run it (needs push):**
```
git tag -a -s v0.1.0 -m "Lab 10 release"
git push origin v0.1.0          # fires the workflow
docker rmi ghcr.io/<owner>/<repo>/quicknotes:v0.1.0    # then pull on a clean machine:
docker pull ghcr.io/<owner>/<repo>/quicknotes:v0.1.0   # works without auth once the package is public
```
Registry URL: `ghcr.io/<owner>/<repo>/quicknotes` · green run + clean-pull evidence:
**PENDING PUSH** (first push creates a *private* package — flip it to public once in
the package's GH UI).

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

The Space is a Docker-SDK Space. [`cloud/Dockerfile`](../cloud/Dockerfile) does
`FROM ghcr.io/.../quicknotes:v0.1.0` (run the CI artifact, don't rebuild) and points
`DATA_PATH` at `/tmp` (HF gives no writable volume and runs an arbitrary UID).
[`cloud/README.md`](../cloud/README.md) frontmatter sets `sdk: docker` and
**`app_port: 8080`** so HF routes to QuickNotes' listener.

- Space URL + `curl -v /health`: **PENDING (needs an HF account + push to the Space repo)**
- Warm p50 / cold latencies (3×): **PENDING** — method: `curl -w '%{time_total}'`
  ×5 immediately for warm p50; idle 35 min so the Space sleeps; then single cold
  requests ×3.

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
faster to start, reproducible, and means *the exact artifact CI tested and scanned
is what runs* — no drift. Building inside the Space re-runs the build on HF's
builder (slower cold deploys, can drift from CI) but keeps the Space self-contained
and easy to tweak/debug in place. I chose **pull**: the CI artifact is the single
source of truth (it's already Trivy-scanned from Lab 9).

---

## Bonus — Cloudflare Tunnel + comparison

Approach (zero account, zero card): run QuickNotes locally, then
`cloudflared tunnel --url http://localhost:8080` → public
`https://<random>.trycloudflare.com`. Verify from a *different* network (phone on
cellular), then `hyperfine` 50 runs for p50/p95.

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | PENDING | PENDING |
| Warm p95 | PENDING | PENDING |
| Cold start | PENDING (tens of s) | N/A (always-on locally) |
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
| 1 — Tag → CI → ghcr.io | `release.yml` written, SHA-pinned, least-privilege, YAML-validated; **live push/pull PENDING** |
| 2 — HF Spaces deploy | Space `Dockerfile` + `README.md` (`app_port: 8080`) written; **live URL + latency PENDING (account/push)** |
| Bonus — Cloudflare Tunnel | approach + comparison framework documented; **measurements PENDING (cloudflared + public exposure)** |
| Design questions a–i | ✅ complete |
