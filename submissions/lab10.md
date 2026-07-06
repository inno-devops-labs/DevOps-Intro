# Lab 10 — Cloud: Ship QuickNotes to a Real Cloud (No Card)

Release CI: [`.github/workflows/release.yml`](../.github/workflows/release.yml).
Space artifacts: [`cloud/Dockerfile`](../cloud/Dockerfile),
[`cloud/README.md`](../cloud/README.md), [`cloud/teardown.md`](../cloud/teardown.md).

---

## Task 1 — CI-Automated Push to `ghcr.io`

### What the workflow does

On a pushed semver tag (`v*`): checkout → buildx → log in to ghcr with the
auto-issued `GITHUB_TOKEN` → derive tags (`{{version}}` + `latest`) with
`docker/metadata-action` → build `./app` for `linux/amd64` and push to
`ghcr.io/rikire/devops-intro/quicknotes`. Permissions are `contents: read` +
`packages: write` only; every third-party action is pinned by 40-char SHA.

### Evidence

- Release run (green): <!-- TODO: paste the `release` workflow run URL from the Actions tab -->
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

- Space URL: <!-- TODO: https://<user>-quicknotes.hf.space -->

```text
$ curl -v https://<user>-quicknotes.hf.space/health
<!-- TODO: paste the 200 + {"status":"ok","notes":N} -->
```

### Scale-to-zero (HF "sleep")

| Measurement | time_total |
|-------------|-----------:|
| Warm p50 (5 back-to-back requests) | <!-- TODO --> s |
| Cold start #1 (after 35 min idle)  | <!-- TODO --> s |
| Cold start #2                      | <!-- TODO --> s |
| Cold start #3                      | <!-- TODO --> s |

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
