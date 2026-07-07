# Lab 10

Artifacts: [`.github/workflows/release.yml`](../.github/workflows/release.yml),
[`cloud/Dockerfile`](../cloud/Dockerfile), [`cloud/README.md`](../cloud/README.md),
[`cloud/teardown.md`](../cloud/teardown.md).

---

## Task 1

[`release.yml`](../.github/workflows/release.yml) triggers on `push` of a `v*` tag,
logs in to ghcr with the built-in `GITHUB_TOKEN`, derives tags with
`docker/metadata-action` (the immutable `{{version}}` and `latest`), and builds
`./app` + pushes to `ghcr.io/<owner>/<repo>/quicknotes`. `permissions:` is scoped
to `contents: read` + `packages: write`; all three `docker/*` actions are pinned by
40-char SHA (carried over from Lab 3). YAML validated.

Done (live): pushed a signed `v0.1.0` tag → the workflow ran green
([run 28883168854](https://github.com/RoukayaZaki/DevOps-Intro/actions/runs/28883168854)),
`Build and push → success`. Image published to
`ghcr.io/roukayazaki/devops-intro/quicknotes` with tags `0.1.0` and
`latest`.

The package was flipped to public in the GH UI (no API for
container-package visibility). Verified anonymous clean pull (logged out,
image removed first):
```
$ docker pull ghcr.io/roukayazaki/devops-intro/quicknotes:0.1.0
Status: Downloaded newer image ... Digest: sha256:3d5c6213...   (21.9 MB)
$ docker run ... && curl /health  ->  {"notes":4,"status":"ok"}
```

> Bug caught + fixed along the way: the first `release.yml` had inline `#` comments
> on the `metadata-action` `tags:` lines, which got baked into the tag names
> (`0.1.0-e.g.-v0.1.0-...`). Removed the inline comments and re-tagged - the second
> run produced the clean `0.1.0` + `latest`.

### Design questions

a) OIDC vs `GITHUB_TOKEN`. For pushing to ghcr from the same repo,
`GITHUB_TOKEN` with `packages: write` is enough. Reach for OIDC when pushing to
an external registry/cloud (AWS ECR, GCP Artifact Registry, Docker Hub): the
workflow exchanges a short-lived, signed identity token for cloud credentials, so
you store no long-lived secrets in the repo. OIDC gives keyless, short-lived,
auditable auth to third parties that `GITHUB_TOKEN` (scoped to GitHub only) can't
reach.

b) Why ship `:latest` next to the immutable `:v0.1.0`? `:latest` is mutable -
useless for reproducible deploys - but it's the convenient "current release"
pointer for humans, quickstart docs, and demos. Production pins the immutable
`:v0.1.0` (exact bytes, rollback-able). You ship both: `latest` for convenience,
the version tag for what you actually deploy.

c) `packages: write` only - principle + attack prevented. Least privilege:
grant only what the job needs. If this workflow (or a compromised action inside it)
is exploited, a narrow `packages: write` token can only push packages; it can't
push code, rewrite branches, edit releases, or change repo settings. A broad
`write: all` would let the attacker tamper with the source itself; the narrow scope
caps the blast radius.

---

## Task 2 - Deploy to Hugging Face Spaces

The Space is live: https://huggingface.co/spaces/GammaViolet/quicknotes,
serving at https://gammaviolet-quicknotes.hf.space. It's a Docker-SDK Space
that builds from source ([`cloud/Dockerfile`](../cloud/Dockerfile) - a
multi-stage build with the app source copied into the Space repo) rather than
pulling the ghcr image, so it's self-contained and doesn't depend on the ghcr
package being made public first. `DATA_PATH` points at `/tmp` (HF gives no writable
volume and runs an arbitrary UID); [`cloud/README.md`](../cloud/README.md)
frontmatter sets `sdk: docker` and `app_port: 8080` so HF routes to QuickNotes'
listener.

```
$ curl -s https://gammaviolet-quicknotes.hf.space/health
{"notes":4,"status":"ok"}
$ curl -s .../notes            # GET  -> 200, seeded notes
[{"id":1,"title":"Welcome to QuickNotes",...}, ...]
$ curl -X POST -d '{"title":"from-grader","body":"hi"}' .../notes   # -> 201 Created
{"id":5,"title":"from-grader","body":"hi","created_at":"2026-07-07T16:52:29Z"}
```

- Warm p50: 0.565 s (5 consecutive requests, 0.550–0.595 s)
- Cold start (3×): 26.3 s, 9.3 s, 9.7 s - time from waking a paused Space to
  the first `200` (pause→restart; forcing the free-tier *idle*-sleep wasn't
  practical to script, so I paused it to force the scale-from-zero wake). The first
  wake is slowest; tens of seconds either way.

### Design questions

d) HF "sleep" vs Cloud Run "scale-to-zero". Same idea, very different wake
time. HF's wake is tens of seconds because the free tier pulls and cold-starts a
full container from shared, oversubscribed infrastructure optimized for cost and
ML demos, not request latency. Cloud Run keeps images warm-close to the runtime,
has start paths engineered for fast request serving, and a paid SLA.

e) Why `app_port: 8080`? HF defaults to 7860 - the Gradio/Streamlit port,
because most Spaces are ML demos built on those frameworks. QuickNotes listens on
8080, so `app_port: 8080` tells HF's proxy where to send traffic. Without it HF
probes 7860, finds nothing, and the Space looks dead.

f) Pull the ghcr image vs build in the Space. Pulling the prebuilt image is
faster to start and means the exact artifact CI tested runs but it
requires the ghcr package to be public and adds a registry dependency. Building in
the Space keeps it self-contained and editable in place, at the cost of a slower
first build and possible drift from CI. I chose build-from-source here: it made
the Space work end-to-end on its own (no ghcr public-flip in the loop), which was
the pragmatic call.
