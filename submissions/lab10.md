# Lab 10 — Cloud Computing: QuickNotes on ghcr.io + HF Spaces + Cloudflare Tunnel

## Task 1 — CI-automated push to ghcr.io

**Workflow:** [`.github/workflows/release.yml`](../.github/workflows/release.yml) —
triggers on `v*` tag push, builds `app/` for `linux/amd64`, pushes
`v0.1.0` + `latest` to ghcr. Permissions: `contents: read`, `packages: write`
only. All actions pinned by 40-char SHA (verified via `git ls-remote` against
upstream tags).

**Registry:** `ghcr.io/dnau15/devops-intro/quicknotes` —
https://github.com/Dnau15/DevOps-Intro/pkgs/container/devops-intro%2Fquicknotes

**Green release run:** https://github.com/Dnau15/DevOps-Intro/actions/runs/28896505596
(triggered by tag `v0.1.0`, completed in 49s)

**Publicly pullable — anonymous registry access** (no `docker login`, token
requested anonymously):

```text
$ curl -s "https://ghcr.io/token?scope=repository:dnau15/devops-intro/quicknotes:pull" \
    | jq -r .token   # issued without credentials
$ curl -sI -H "Authorization: Bearer $TOK" \
    https://ghcr.io/v2/dnau15/devops-intro/quicknotes/manifests/v0.1.0 | grep -i digest
docker-content-digest: sha256:7d3cbde25c67749c9d680364025c12bf261dbe6c465af250445ece76388a8e26
$ curl -sI -H "Authorization: Bearer $TOK" \
    https://ghcr.io/v2/dnau15/devops-intro/quicknotes/manifests/latest | grep -i digest
docker-content-digest: sha256:7d3cbde25c67749c9d680364025c12bf261dbe6c465af250445ece76388a8e26
```

Both `v0.1.0` and `latest` resolve to the same digest
`sha256:7d3cbde25c67749c9d680364025c12bf261dbe6c465af250445ece76388a8e26`.

**Clean `docker pull` (no `docker login`, after `docker logout ghcr.io`):**

```text
$ docker pull ghcr.io/dnau15/devops-intro/quicknotes:v0.1.0
v0.1.0: Pulling from dnau15/devops-intro/quicknotes
Digest: sha256:7d3cbde25c67749c9d680364025c12bf261dbe6c465af250445ece76388a8e26
Status: Image is up to date for ghcr.io/dnau15/devops-intro/quicknotes:v0.1.0
ghcr.io/dnau15/devops-intro/quicknotes:v0.1.0
```

> Note: the very first pull attempt right after the release run returned
> `unauthorized` — the first push to ghcr creates the package **private**.
> Flipping visibility to Public in the package settings (one-time UI action)
> fixed it; everything above is anonymous access after the flip.

### Design questions

**a) OIDC vs `GITHUB_TOKEN`.** For pushing to ghcr from the same repo,
`GITHUB_TOKEN` is the right tool: it's minted automatically per job, scoped to
this repository, and expires when the job ends — nothing to store or rotate.
OIDC becomes necessary the moment the target is *outside* GitHub: AWS ECR,
GCP Artifact Registry, Azure, a Vault instance. There you'd otherwise have to
store long-lived cloud credentials as repo secrets. OIDC replaces them with a
short-lived, per-job identity token whose *claims* (repo, branch, tag,
environment, workflow) the cloud provider verifies against a trust policy —
so you get: no static secrets to leak or rotate, and fine-grained trust rules
like "only tags `v*` from repo X may assume the deploy role", which
`GITHUB_TOKEN` can't express because it means nothing to a non-GitHub service.

**b) Why ship `:latest` alongside `:v0.1.0`.** They serve different consumers.
The immutable semver tag is for *machines and production*: deploy manifests,
the HF Space Dockerfile, audits — anything that must be reproducible pins
`v0.1.0` (or better, the digest). `:latest` is a *discovery alias for humans
and dev tooling*: `docker pull ghcr.io/...` with no tag "just works", docs and
quickstarts stay evergreen, and "what's the current release?" is answerable
without checking the tag list. The rule: `latest` may only ever *point at* an
immutable release tag, never carry unique bits — then its mutability is a
convenience, not a hazard. (Verified above: both tags → one digest.)

**c) `packages: write` only — the principle and the attack.** Principle:
least privilege — grant the token exactly the capability the job needs.
The concrete threat model in this workflow is a compromised third-party action
(we run four of them; that's why they're SHA-pinned) or a malicious build
dependency: anything in the job can read `GITHUB_TOKEN`. With
`packages: write` only, the worst case is a poisoned *package* — bad, but
visible and revocable. With a write-all token the same attacker could push
commits or rewrite branches (`contents: write`), tamper with other workflows,
edit releases, or open/approve PRs — i.e. persist in the *source*, turning a
one-off CI compromise into a supply-chain foothold that survives the job.
Narrow scope caps the blast radius to the artifact.

## Task 2 — Hugging Face Space

**Space:** https://huggingface.co/spaces/Dnau15/quicknotes
**Public URL:** https://dnau15-quicknotes.hf.space

**`curl -v` against `/health`** (trimmed to the interesting part):

```text
* Connected to Dnau15-quicknotes.hf.space (35.175.32.85) port 443
* subjectAltName: host "Dnau15-quicknotes.hf.space" matched cert's "*.hf.space"
* using HTTP/2
> GET /health HTTP/2
> Host: Dnau15-quicknotes.hf.space
< HTTP/2 200
< content-type: application/json
< cache-control: no-store
< content-security-policy: default-src 'none'; frame-ancestors 'none'
< x-content-type-options: nosniff
< x-frame-options: DENY
< x-proxied-host: http://10.111.104.87
< x-proxied-replica: iflbopad-r8qlv
<
{"notes":4,"status":"ok"}
```

(The security headers are QuickNotes' own lab9 middleware, served through
HF's proxy — the exact CI-built image is running.)

`GET /notes` returns the 4 seed notes — separate instance from the local
compose stack (which has 24 notes): free-tier Space storage is ephemeral,
data resets on every rebuild/wake.

**Space files** (also in [`cloud/`](../cloud/)):

`Dockerfile`:

```dockerfile
# Deploy the exact image CI built, scanned (lab9) and published — not a rebuild.
FROM ghcr.io/dnau15/devops-intro/quicknotes:v0.1.0
```

`README.md` frontmatter:

```yaml
---
title: QuickNotes
emoji: 📝
colorFrom: indigo
colorTo: blue
sdk: docker
app_port: 8080
pinned: false
---
```

I chose *pulling the ghcr image* over building from source in the Space —
rationale in design question (f). One real-world hiccup worth recording:
the first push to the Space was rejected by HF's YAML metadata validation
(`colorTo: cyan` is not in their allowed palette) — fixed to `blue`.

### Latency

| Measurement | Value |
|---|---|
| Warm p50 (5 consecutive requests) | **0.592 s** |
| Warm p50 / p95 (hyperfine, 50 runs) | **617 ms** / **645 ms** |
| Cold start #1 (forced, see method below) | **9.39 s** |
| Cold start #2 | **11.54 s** |
| Cold start #3 | **6.10 s** |

Raw warm samples (s): 0.583033, 0.583278, 0.592485, 0.594718, 0.603686
hyperfine: mean 615.2 ms ± 21.6 ms, range 576.0–701.3 ms, 50 runs.

**Cold-start methodology (and an honest finding).** The lab expects the free
Space to sleep after ~30 min idle. Observed behavior differs: after idle
windows of 15+ min the first request returned in 0.63–0.72 s — i.e. no cold
start; the current HF free tier puts Spaces to sleep only after **48 h** of
inactivity, which doesn't fit in one lab session. So the three cold starts
were **forced** through the HF API, which exercises the same wake path
(container scheduling + boot + proxy re-registration, image already cached):

1. `POST /api/spaces/Dnau15/quicknotes/pause` → wait until `/health` returns 503
2. `POST /api/spaces/Dnau15/quicknotes/restart` → poll `/health` every 0.5 s
3. Cold start = time from the restart call to the first
   `200 {"status":"ok"}` response

A plain `restart` on a *running* Space, by the way, produced no observable
outage at all (rolling replacement) — only pause→restart yields a true cold
boot. First-ever deploy was slower still (full image pull on build).

### Design questions

**d) HF Spaces "sleep" vs Cloud Run "scale to zero".** Same lifecycle,
different economics. When an HF Space wakes, the platform has to find a slot
on a shared free-tier cluster, pull (or restore) the full Docker image, start
the container and re-register the proxy route — tens of seconds, sometimes
more. HF optimizes for *hosting cost ≈ 0* on hardware shared across thousands
of idle demos; wake time is not a metric they sell. Cloud Run optimizes for
*request latency* because it bills per request-time: images staged in regional
caches close to the compute, lightweight sandboxes (gVisor microVMs) that
start in milliseconds, pre-warmed instance pools, an autoscaler that starts
the instance while the request is held at the edge. Sub-second cold starts
are the product; that's what the per-100ms billing pays for.

**e) Why `app_port: 8080`?** HF's ingress proxy forwards traffic to *one*
declared container port, default **7860** — Gradio's default port, because
Docker Spaces inherited conventions from the Gradio/Streamlit demo SDKs that
Spaces was built for. QuickNotes listens on `:8080` and the lab forbids
changing the app, so the Space metadata must tell the proxy where to route:
`app_port: 8080`. Without it, the proxy probes 7860, nothing answers, and the
Space reports the container as unhealthy.

**f) Pull from ghcr vs build in the Space.** Pulling wins on
*reproducibility and provenance*: the Space runs byte-for-byte the artifact
that CI built, Trivy-scanned (lab9) and released — one supply chain, one
truth; the Space rebuild can never drift from the release, and Space builds
are fast (one `FROM` layer pull). The trade-offs: **caching** — HF re-pulls a
full external image instead of reusing cached source-build layers, and the
image must stay publicly pullable; **debug-ability** — you can't hot-fix by
editing source in the Space repo; every change must go through tag → CI →
new image → bump the `FROM` tag, which is slower to iterate but is exactly
the discipline you want in production. Building inside the Space inverts all
of this: fast iteration and HF-local layer cache, but now there are two build
environments that can diverge, and what you scanned is no longer what you run.

## Bonus — Cloudflare Tunnel

**Tunnel URL (ephemeral):** `https://urge-levels-practitioner-paste.trycloudflare.com`
**Origin:** the lab8 compose stack (`docker compose up -d`) serving
QuickNotes on `localhost:8080`; exposed with
`cloudflared tunnel --url http://localhost:8080` (cloudflared 2026.6.1,
QUIC connection registered at Cloudflare edge `ist02`).

**Reachability from another network:** verified by opening
`https://urge-levels-practitioner-paste.trycloudflare.com/health` from a phone
on cellular data (Wi-Fi off) — screenshot:
![tunnel from cellular](lab10-tunnel-phone.png)

**Measurement:** `hyperfine --warmup 5 --runs 50 'curl -s -o /dev/null $TUNNEL/health'`,
p50/p95 computed from the exported raw samples (sorted, indices 24 / 47):

```text
Time (mean ± σ):  153.3 ms ± 23.0 ms   Range: 132.5 … 259.8 ms   (50 runs)
p50=148ms  p95=211ms
```

(A first 50-run pass gave p50=144 ms / p95=162 ms — same p50 within noise;
p95 varies run-to-run because the tail is residential-uplink jitter.)

### Comparison table

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50               | 617 ms | 148 ms |
| Warm p95               | 645 ms | 211 ms |
| Cold start             | 6.1–11.5 s (3 forced samples) | N/A (continuously local) |
| Public URL stability   | stable | ephemeral on restart |
| Cost                   | free | free |

Client for both rows: the same laptop/network, so the comparison is
apples-to-apples for this client location.

### Design questions

**g) Which one is "really cloud"?** By the textbook definition (compute owned
and operated by a provider, elastic, reachable as a service) HF Spaces is
cloud: the container's power, network, host failures and scheduling are HF's
problem. The tunnel is *edge-fronted on-prem*: Cloudflare provides ingress,
TLS and DDoS absorption, but the compute is my laptop — close the lid and the
"service" is down. To users the distinction is invisible in the URL and
irrelevant *until it isn't*: they experience it as availability and latency.
The moment the laptop sleeps, the architectural difference becomes a
user-visible outage. So: the label doesn't matter to users; the operational
properties the label implies absolutely do.

**h) Latency dominator.** HF warm path: the wire — client RTT to HF's
datacenter (US region; note the AWS `us-east` IPs and Amazon-issued cert in
the `curl -v` above) plus their proxy/routing layers, with some noise from
shared free-tier hosts; the Go handler itself is microseconds. Tunnel path:
the *backhaul* — the client reaches the nearest Cloudflare edge fast (ist02
in my case), but the request then rides the persistent tunnel back to my
laptop over a residential last-mile uplink, and the response crosses it
again. In both cases the app is negligible; the two rows of the table are
really measuring two different network topologies.

**i) When is Cloudflare Tunnel the right production pick?** When the workload
*must* stay where it is and what you need is safe ingress: home labs and
on-prem services that sit behind NAT/CGNAT with no public IP and no desire to
port-forward; internal tools exposed to a partner; data-residency-constrained
services that can't move to a cloud region; stakeholder-facing dev/demo URLs.
A named tunnel (free account + domain) makes this a legitimate, stable
production ingress. It's never the right pick when the *origin itself* is the
weak link: user-facing services needing HA, autoscaling, or latency guarantees
served off a single machine — the tunnel fixes reachability, not availability.
And a *quick* tunnel specifically is never production: ephemeral URL, no SLA,
no auth.

## Teardown

Documented in [`cloud/teardown.md`](../cloud/teardown.md). The Space and the
ghcr image are left up (both free) for grading; the quick tunnel URL died with
its `cloudflared` process.
