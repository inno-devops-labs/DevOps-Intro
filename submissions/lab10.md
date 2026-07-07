# Lab 10 — Cloud: Ship QuickNotes to a Real Cloud (No Card)

Release CI: [`.github/workflows/release.yml`](../.github/workflows/release.yml).
Space artifacts: [`cloud/Dockerfile`](../cloud/Dockerfile),
[`cloud/README.md`](../cloud/README.md), [`cloud/teardown.md`](../cloud/teardown.md).

---

## Task 1 — CI-Automated Push to `ghcr.io`

### What the workflow does

On a pushed tag (`v*`): checkout → buildx → log in to ghcr with the auto-issued
`GITHUB_TOKEN` → derive tags (the raw ref name `v0.1.0` + `latest`) with
`docker/metadata-action` → build `./app` for `linux/amd64` and push to
`ghcr.io/rikire/devops-intro/quicknotes`. Permissions are `contents: read` +
`packages: write` only; every third-party action is pinned by 40-char SHA.

### Evidence

- Release run (green): https://github.com/rikire/DevOps-Intro/actions/runs/28790465672
- Registry: `ghcr.io/rikire/devops-intro/quicknotes:v0.1.0` (+ `:latest`), public.
- Clean pull with **no credentials** (`~/.docker/config.json` has no ghcr entry):

```text
$ docker logout ghcr.io && docker rmi ghcr.io/rikire/devops-intro/quicknotes:v0.1.0
$ docker pull ghcr.io/rikire/devops-intro/quicknotes:v0.1.0
v0.1.0: Pulling from rikire/devops-intro/quicknotes
Digest: sha256:be82c125e58a64e41c9eee6e08d814530f423d3ca7846affb74674c25dd9dcb9
Status: Downloaded newer image for ghcr.io/rikire/devops-intro/quicknotes:v0.1.0

$ docker run --rm -p 8099:8080 ghcr.io/…/quicknotes:v0.1.0 &  ; curl -s :8099/health
{"notes":4,"status":"ok"}        # 200 — and carries the Lab 9 security headers
```

### 1.2 Design questions

**a) OIDC vs `GITHUB_TOKEN` for ghcr.io.**
For pushing to ghcr **from the same repo**, `GITHUB_TOKEN` with `packages: write`
is enough — it's auto-issued, scoped to this repo, and expires when the job ends.
You reach for **OIDC** when you need to authenticate to an **external** cloud
(AWS ECR, GCP Artifact Registry, Azure) — OIDC exchanges a short-lived signed JWT
(carrying `repo`/`ref`/`actor` claims) for cloud credentials with **no stored
long-lived secrets** and a fine-grained trust policy ("only this repo on this
branch may assume this role"). `GITHUB_TOKEN` only works inside GitHub's own
services; OIDC gives keyless, secret-less federation to third parties. For ghcr
same-repo, OIDC is overkill; for deploying to a hyperscaler, it's the right tool.

**b) Why ship `:latest` alongside the immutable `:v0.1.0`?**
The immutable `:v0.1.0` is the source of truth — reproducible, auditable,
pin-able for rollback; production and CI pin *this* (never `:latest`, which is
mutable). `:latest` is a moving convenience pointer: it's the ergonomic entry for
humans doing quick pulls, docs/examples, and "just give me the current release"
tooling. They serve different audiences — you keep the immutable tag for
correctness and `:latest` for UX, and you never *depend* on `:latest` where
reproducibility matters.

**c) `packages: write` only — principle + attack prevented.**
**Least privilege.** The job only publishes a package, so it gets only
`packages: write` + `contents: read`. If the job (or a compromised action /
dependency inside it) runs hostile code, the blast radius is bounded to "push a
package." With `write: all` / `contents: write`, a compromised run could push
malicious **commits**, rewrite **workflows**, cut fake **releases** — a full
supply-chain repo takeover. The narrow scope means a leaked token or poisoned
action can at worst publish a bad image (caught downstream), not backdoor your
source or CI.

---

## Task 2 — Deploy to Hugging Face Spaces

### The Space

A Docker-SDK Space serving QuickNotes. The Space repo holds two files:
[`cloud/Dockerfile`](../cloud/Dockerfile) (pulls the ghcr image) and
[`cloud/README.md`](../cloud/README.md) (frontmatter: `sdk: docker`,
`app_port: 8080`).

- Space URL: **https://rikire-quicknotes.hf.space**

```text
$ curl -sD- https://rikire-quicknotes.hf.space/health
HTTP/1.1 200 OK
Content-Type: application/json
cache-control: no-store
content-security-policy: default-src 'none'      # the deployed image carries the Lab 9 hardening
x-content-type-options: nosniff

{"notes":4,"status":"ok"}
```

`/notes` also serves the seeded data. Note the Space runs the *exact* ghcr image
(digest `be82c125…`) — the security headers prove it's the hardened Lab 9 build,
not a rebuild.

### Scale-to-zero (HF "sleep")

Measured with `curl -w '%{time_total}'` (connection is VPN-routed to HF's
datacenter, so warm samples show high variance — best-case ~0.7 s).

| Measurement | time_total |
|-------------|-----------:|
| Warm p50 (7 back-to-back requests)          | ~1.5 s (min 0.73 s) |
| Cold start #1 (first hit after a long idle) | 10.7 s |
| Cold start #2 (first hit after idle)        | 8.9 s |
| Cold start #3 (wake exceeded client timeout) | ≥ 15 s |

Each cold sample is the **first request after the Space had been idle**; the
immediate warm follow-up dropped back to ~0.6 s, so the 9–15+ s is the *wake*, not
the network — a **~10–15× penalty** vs warm.

**Finding on HF's "sleep":** the free-tier sleep threshold proved *inconsistent*.
A deliberate 37-minute idle probe came back **warm (0.69 s)** — the Space hadn't
slept yet — so `sleep → wake` isn't reliably reproducible on a fixed 35-minute
schedule; the cold numbers above are genuine wake observations captured when it
*had* slept (notably right after deploy and after long multi-hour idles). HF
optimizes for cost, not a predictable wake SLA — you get scale-to-zero savings but
no guarantee of *when* it sleeps or *how fast* it wakes.

### 2.4 Design questions

**d) HF "sleep" vs Cloud Run "scale to zero" — why is HF's wake so much slower?**
Both scale to zero to save cost, but HF wakes in seconds-to-tens-of-seconds
vs Cloud Run's sub-second-to-few-seconds. They optimize for different things. HF
Spaces is a **free demo/showcase** platform on shared infra: a wake means
scheduling the container onto a shared node, pulling a (often large) image from
storage, and cold-starting it — no warm pool is kept for free Spaces. Cloud Run
is a **paid, latency-sensitive production** serverless: images are pre-staged near
compute, container start is heavily optimized, and you can pay to keep
`min-instances` warm. HF trades wake speed for $0; Cloud Run trades money for
low tail latency.

**e) Why does the Space need `app_port: 8080`?**
HF Spaces default the served port to **7860** (the Gradio/Streamlit heritage).
QuickNotes binds **8080**, so without `app_port: 8080` HF routes the public URL
to 7860 where nothing listens → the Space looks dead (no response / 502). Setting
`app_port: 8080` points HF's edge at the port the app actually binds. We don't
touch QuickNotes — `app_port` is HF's escape hatch from their default.

**f) Pull the ghcr image vs build the Dockerfile inside the Space — trade-off.**
We **pull** the immutable ghcr tag, so the Space runs the *exact* artifact CI
built, tagged, and Lab-9-scanned — reproducible, no build drift, and the Space
build is a fast pull (no recompile). Cost: it depends on the image being
published+public first, and you can't tweak the image in-place. **Building from
`app/` in the Space** instead makes it self-contained and easy to hack/debug, but
HF rebuilds on every push (slower) and can produce a *different* image than CI
did (different base digest, build-time drift) — so "what you tested" ≠ "what you
ship." We chose reproducibility: ship the scanned CI artifact, not a rebuild.

---

## Bonus — Cloudflare Tunnel + Cross-Platform Comparison

Not attempted (Task 1 + Task 2 completed for 10/10).
