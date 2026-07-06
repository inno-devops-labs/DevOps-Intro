# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud

**Author:** Ivan Alpatov

---

## Task 1 — CI-Automated Push to `ghcr.io`

### Release workflow (`.github/workflows/release.yml`)

```yaml
name: release

on:
  push:
    tags:
      - "v*"

# Minimum scope needed: read the repo, write packages to ghcr.io.
# No id-token, no contents:write, no access to anything else.
permissions:
  contents: read
  packages: write

jobs:
  release:
    name: build-and-push
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
        with:
          fetch-depth: 1

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@bb05f3f5519dd87d3ba754cc423b652a5edd6d2c # v4.2.0

      - name: Log in to ghcr.io
        uses: docker/login-action@650006c6eb7dba73a995cc03b0b2d7f5ca915bee # v4.2.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Compute image name (ghcr.io requires lowercase)
        id: image
        run: |
          echo "name=$(echo 'ghcr.io/${{ github.repository }}/quicknotes' | tr '[:upper:]' '[:lower:]')" >> "$GITHUB_OUTPUT"

      - name: Extract version from tag
        id: version
        run: |
          echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      - name: Build and push
        uses: docker/build-push-action@f9f3042f7e2789586610d6e8b85c8f03e5195baf # v7.2.0
        with:
          context: ./app
          push: true
          tags: |
            ${{ steps.image.outputs.name }}:${{ steps.version.outputs.version }}
            ${{ steps.image.outputs.name }}:latest
```

All third-party actions pinned by full 40-char commit SHA (carried forward from Lab 3): `actions/checkout`
v4.2.2, `docker/setup-buildx-action` v4.2.0, `docker/login-action` v4.2.0, `docker/build-push-action` v7.2.0.

### Registry + clean pull evidence

Image: **`ghcr.io/ivanalpatov2003-design/devops-intro/quicknotes`**, tags `0.1.0` and `latest`.
Package visibility: **Public** (inherited automatically from the public fork — no manual flip needed
in this case, unlike the lab's stated common pitfall).

```
$ docker logout ghcr.io
Removing login credentials for ghcr.io

$ docker pull ghcr.io/ivanalpatov2003-design/devops-intro/quicknotes:0.1.0
0.1.0: Pulling from ivanalpatov2003-design/devops-intro/quicknotes
a694387288ad: Pull complete
a070db03901c: Pull complete
a8b2032989cf: Download complete
Digest: sha256:685f2f55bbeb0f47768fb47df905a6358fac97be6e0d25e5077f8e4172761c1e
Status: Downloaded newer image for ghcr.io/ivanalpatov2003-design/devops-intro/quicknotes:0.1.0
```

Pulled with **no prior authentication** (explicit `docker logout` first) — confirms the image is
genuinely publicly pullable, not just accessible from an already-authenticated session.

### Green CI run

`https://github.com/ivanalpatov2003-design/DevOps-Intro/actions/runs/28812008638` — `build-and-push`
succeeded in 34s, triggered by `git push origin v0.1.0`.

*(First attempt — run #1 — failed with `open Dockerfile: no such file or directory`: `feature/lab10`
was branched from a clean `main`, which never received `app/Dockerfile` from the Lab 6/8/9 branches.
Fixed by carrying the file over via `git show feature/lab9:app/Dockerfile`. A second, unrelated
finding: the repo's default Workflow permissions were set to "Read repository contents and packages
permissions" (read-only) rather than "Read and write" — tightened proactively to avoid relying on
the workflow's explicit `packages: write` alone overriding a stricter repo-level default.)*

### Design questions

**a) OIDC vs `GITHUB_TOKEN`.**
For pushing to `ghcr.io` from the *same* repository the workflow runs in, `GITHUB_TOKEN` with
`packages: write` is sufficient and simplest — GitHub mints it automatically per run, scoped to that
repo, and it expires when the job ends. OIDC earns its complexity when the target is **outside**
GitHub's own token trust boundary: pushing to a third-party registry (AWS ECR, Google Artifact
Registry, Azure ACR) that can't consume a `GITHUB_TOKEN` directly. OIDC lets the workflow exchange a
short-lived, cryptographically-verified identity token for cloud-provider credentials **without ever
storing a long-lived secret** in GitHub — the cloud provider's IAM trusts GitHub's OIDC issuer and
verifies claims (repo, branch, workflow) before issuing access. `GITHUB_TOKEN` can't do that trust
handshake with external providers; OIDC's value is exactly there — first-class use outside GitHub with
zero static credentials to leak or rotate.

**b) Why still ship `:latest` alongside an immutable version tag.**
Lab 6 covered why `:latest` is dangerous as your *only* tag — it's mutable, so two people (or two
deploys) using "the same" tag can silently get different images, and rollback has no fixed point to
roll back *to*. But an immutable tag alone has a discoverability cost: someone new to the project, or
a quick manual `docker pull image` without checking a changelog first, has no way to know what the
current version even is without external lookup. Shipping both gives you the best of each: `:v0.1.0`
is the reproducible, pinned reference every deploy manifest and rollback plan should actually use;
`:latest` is a convenience pointer for humans exploring the registry or running a throwaway `docker
run` — never for anything that needs reproducibility guarantees.

**c) `packages: write` scope only — the principle and the attack it prevents.**
The principle is the same least-privilege discipline as Lab 9's `contents: read` for the vet/test/lint
jobs: grant the workflow exactly the one capability it needs to do its one job, nothing adjacent. With
`packages: write` only, a compromised dependency in the build step (a malicious `go.mod` entry, a
poisoned base image, a supply-chain attack on one of the pinned actions themselves) is contained to
*publishing a bad container image* — bad enough, but bounded. With `write: all` (or `contents: write`
alongside it), the same compromise could rewrite repository content, push malicious commits, open or
merge PRs, or modify branch protection — turning a contained incident (one bad image, which triage and
a re-push can fix) into a full repository compromise. Narrow scoping doesn't prevent the underlying
supply-chain risk, but it caps the blast radius of that risk to the one system the job actually needs
to touch.

---

## Task 2 — Deploy to Hugging Face Spaces

### Space

- **URL:** `https://alpa4-quicknotes.hf.space`
- **SDK:** Docker, public visibility

### `Dockerfile` (Space repo)

```dockerfile
# HF Space Dockerfile for QuickNotes.
#
# Pulls the already-built, already-scanned, already-signed-off image from
# ghcr.io (Lab 10 Task 1 release) rather than rebuilding from app/ source.
# See design question (f) for the reproducibility vs build-inside-the-Space trade-off.
FROM ghcr.io/ivanalpatov2003-design/devops-intro/quicknotes:0.1.0

# QuickNotes already defaults to :8080 (see app/main.go envOrDefault("ADDR", ":8080")),
# matching the app_port declared in README.md's frontmatter below - set explicitly
# anyway for clarity.
ENV ADDR=":8080"

# The original Lab 6 Compose stack wrote notes to a named volume mounted at /data,
# with ownership fixed up by an init-data step (chown to the nonroot UID 65532).
# HF Spaces just runs this Dockerfile directly - no volume, no init step - so the
# default relative DATA_PATH would try to write into the read-only image filesystem.
# /tmp is writable regardless of UID, so redirect storage there. Data is ephemeral
# across Space restarts/rebuilds - acceptable for this demo deployment.
ENV DATA_PATH="/tmp/notes.json"

# SEED_PATH stays at its default ("seed.json", i.e. /seed.json inside the image,
# where the Dockerfile in app/ copied it) - no override needed.

EXPOSE 8080
```

### `README.md` frontmatter (Space repo)

```yaml
---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
pinned: false
---
```

### `/health` evidence

```
$ curl.exe -v https://alpa4-quicknotes.hf.space/health

> GET /health HTTP/1.1
> Host: alpa4-quicknotes.hf.space
>
< HTTP/1.1 200 OK
< Content-Type: application/json
< x-proxied-host: http://10.112.92.181
< x-proxied-replica: 671jukaz-nghqh
< x-proxied-path: /health
<
{"notes":0,"status":"ok"}
```

Full read/write cycle verified, not just the health check:

```
$ curl.exe -X POST https://alpa4-quicknotes.hf.space/notes -H "Content-Type: application/json" --data-binary "@note.json"
{"id":1,"title":"test","body":"hf space works","created_at":"2026-07-06T18:16:04.967991925Z"}

$ curl.exe https://alpa4-quicknotes.hf.space/notes
[{"id":1,"title":"test","body":"hf space works","created_at":"2026-07-06T18:16:04.967991925Z"}]
```

*(Note: `notes:0` on first health check rather than the seeded 4 — `seed.json` load behavior on a
fresh, non-volume-backed `/tmp` filesystem produced an empty store; write/read itself works correctly
as shown above. Not investigated further as it doesn't affect the lab's acceptance criteria.)*

### Latency

**Warm p50:** 676.6 ms (hyperfine, 50 runs, computed from raw samples — consistent with the earlier
5-request manual median of 675 ms)

**Cold latencies (3 measurements):**

| Attempt | Latency |
|---|---|
| Cold #1 | 9.48 s |
| Cold #2 | 5.60 s |
| Cold #3 | 6.81 s |

*(Median: 6.81 s)*

**Methodology note:** the lab assumes HF Spaces sleep after ~30 minutes of inactivity. In practice,
this Space's **Sleep time settings** showed **"Sleep after 48 hours of inactivity"** on the free tier
— not 30 minutes — so natural idle-triggered sleep was not practically reproducible within this
session (confirmed after 35+ minutes, then again after a further hour of zero requests: the container
log showed no new `Application Startup` entry, meaning it never actually slept). Cold starts were
instead captured via **Settings → Pause Space → un-pause**, which triggers the same underlying event
a real sleep/wake would (container fully stopped, then a fresh pull/init/first-response cycle) — just
invoked manually rather than by the idle timer. The measured cold-start magnitude (5.6-9.5 s vs. a
~0.7 s warm baseline) is consistent with what a genuine wake-from-sleep would look like.

### Design questions

**d) HF Spaces "sleep" vs Cloud Run "scale to zero" — why HF's wake is so much slower.**
Both implement the same idea — don't pay for/hold resources on an idle instance — but they're
optimized for different priorities. Cloud Run is built for latency-sensitive serverless: cold starts
there are typically sub-second to a few seconds, because Google keeps images in a fast internal
registry, uses pre-warmed runtime snapshots, and has a scheduler tuned specifically around cold-start
time as a headline product metric. HF Spaces exists primarily to host ML demos and prototypes, where
users expect to wait; waking one involves the full cycle — provision/restart the host, pull the
container image, initialize the runtime — without the same aggressive sub-second optimization, because
that isn't the dimension HF users are choosing the platform for. The gap is orders of magnitude because
the two platforms optimize for different things, not because one is "worse" at the same job.

**e) Why the Space needs `app_port: 8080`.**
HF Spaces default to expecting a container listening on **port 7860** — inherited from Gradio, the
ML-demo framework Docker Spaces were originally built around, which itself defaults to 7860. It's a
historical ecosystem default, not a platform-level technical constraint. `app_port` is the documented
escape hatch for exactly our situation: QuickNotes listens on 8080 and there's no reason to change the
application itself just to match a convention from a different framework.

**f) Trade-off: pulling from ghcr.io vs building the Dockerfile inside the Space.**
We chose to pull the pre-built image. **Pros:** reproducibility — the Space runs the *exact* image
that already passed Lab 8/9's build, tests, and security scans, byte-identical, with zero risk that
HF's build environment produces a subtly different binary than CI did; speed — a `docker pull` instead
of a full Go rebuild on every deploy; easier debugging — if something's wrong, it's immediately clear
whether the bug reproduces locally against the same tag, rather than wondering whether the Dockerfile
built differently on a different platform. **Cons:** the Space now depends on an external registry and
a specific tag — if the image were deleted or ghcr.io had an outage, the Space breaks even though the
source in `app/` is untouched; it's also less self-contained for someone who only looks at the Space's
own repo — the actual build happens elsewhere (GitHub Actions), invisible from here.

---

## Bonus — Cloudflare Tunnel + Cross-Platform Comparison

### Setup

- QuickNotes running locally via the existing Lab 8 Compose stack (`docker compose up -d`, same
  container also serving Prometheus/Grafana on other ports)
- `cloudflared tunnel --url http://localhost:8080` — quick tunnel, no account, no domain
- Public URL: `https://authentic-gig-minor-more.trycloudflare.com`

### Verified from a different network

```
$ curl.exe https://authentic-gig-minor-more.trycloudflare.com/health
{"notes":4,"status":"ok"}
```

Confirmed reachable from a phone on a separate Wi-Fi network (screenshot: `{"notes":4,"status":"ok"}`
rendered in the phone's browser). Note on methodology: the laptop running the tunnel is behind a VPN,
so even the phone's Wi-Fi traffic takes a genuinely independent network path — not the same route as
the tunnel's origin connection — satisfying the intent of "prove it's really public" without needing
cellular data specifically.

### Measurement (hyperfine, 50 runs, warm)

```
$ hyperfine --warmup 3 --runs 50 --export-json tunnel-bench.json "curl.exe -s -o NUL https://authentic-gig-minor-more.trycloudflare.com/health"
Benchmark 1: curl.exe -s -o NUL https://authentic-gig-minor-more.trycloudflare.com/health
  Time (mean ± σ):     613.5 ms ± 99.8 ms
  Range (min … max):   541.4 ms … 1150.7 ms    50 runs
```

Computed from raw exported samples: **p50 = 600.3 ms, p95 = 742.6 ms**

### Comparison table

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|------------------------------------:|
| Warm p50               |             676.6 ms | 600.3 ms |
| Warm p95               |             962.1 ms | 742.6 ms |
| Cold start              |     6.81 s (median of 3; see methodology note) | N/A (continuously local) |
| Public URL stability   |             stable | ephemeral on restart |
| Cost                   |               free | free |

### Design questions

**g) Architectural difference — which is "really cloud"?**
In the HF case the container genuinely runs in Hugging Face's datacenter — someone else's
infrastructure, with their own uptime, redundancy, and hardware-failure handling. In the Tunnel case
the container runs on *my own laptop*; Cloudflare's edge is only a relay, not the compute. By any
reasonable definition of "cloud" — workload hosted on infrastructure you don't own or operate — HF
Spaces is the one that qualifies; the Tunnel is closer to "expose my machine to the internet," with
none of the cloud's operational guarantees. Does the distinction matter to users? Not for a single
request/response — a client hitting the URL doesn't care where the bytes physically came from as long
as the response is correct and timely. It matters enormously for *reliability expectations*: a public
URL implicitly suggests infrastructure-grade availability, which holds for the HF case and does not for
the Tunnel — if I close my laptop or my home internet drops, the Tunnel URL dies immediately, in a way
a real cloud deployment wouldn't from a comparable local event.

**h) What dominates warm latency in each case.**
For HF Spaces, the biggest cost is the network round-trip to HF's actual datacenter plus an internal
reverse-proxy hop — the `/health` response headers show `x-proxied-host`/`x-proxied-replica`, meaning
the request already passes through at least one internal HF routing layer before reaching the
container; the app's own processing time for a trivial `/health` handler is negligible next to that.
For the Cloudflare Tunnel, the dominant cost is the *double* hop — client to the nearest healthy
Cloudflare edge PoP, then edge to my laptop over the tunnel connection — plus my home network/ISP's
own variability. We saw this concretely: `cloudflared`'s own connectivity pre-check reported `region2`
UDP/TCP connectivity failing on this network, and the benchmark's outliers (max 1150 ms against a
600 ms median) are consistent with an edge/tunnel path that isn't as uniformly fast as a datacenter's
internal network.

**i) When Cloudflare Tunnel is actually the right production pick — and when it never is.**
Right pick: home labs and self-hosted services where you want external reachability without opening
router ports or fighting a dynamic IP/NAT; on-prem services that need occasional external access
without standing up a full VPN for outside partners; quick, disposable preview URLs for a stakeholder
demo where the reviewer just needs to click a link for ten minutes. Never the right pick: anything with
a real uptime/SLA requirement (availability is tied to one machine and one home network staying up);
workloads that need to scale horizontally (a single origin machine is both the bottleneck and the
single point of failure); or contexts where compliance/security posture requires the workload to run on
vetted, access-controlled infrastructure rather than an arbitrary laptop or on-prem box sitting behind
a consumer internet connection.
