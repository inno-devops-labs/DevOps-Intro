# Lab 10 - Cloud: Ship QuickNotes to ghcr.io, Hugging Face Spaces, and a Cloudflare Tunnel

## Objective

Push the QuickNotes image to a real registry from CI on a version tag, deploy
the same image to Hugging Face Spaces behind a public URL, measure warm vs
cold latency (scale-to-zero), and (bonus) expose a local copy through a
Cloudflare quick tunnel and compare the two delivery models.

## Environment

- Host: Apple M4 (arm64), macOS; Docker 29.2.1; cloudflared 2026.6.1;
  hyperfine 1.20.0
- Branch `feature/lab10` starts from the Lab 9 state (hardened app, Go 1.26.4
  builder, Lab 3 CI with the govulncheck gate) and drops the Lab 9 scan
  artifacts; Lab 9's scan reports live in the Lab 9 PR
- Image path: `ghcr.io/dekart-hub/devops-intro/quicknotes` (ghcr requires the
  lowercase path)

---

## Task 1 - Tag-triggered CI push to ghcr.io

### The workflow

`.github/workflows/release.yml` triggers on `v*` tags, has only
`contents: read` plus `packages: write`, and pins every third-party action by
its 40-char commit SHA (carried forward from Lab 3):

```yaml
name: Release

on:
  push:
    tags: ['v*']

permissions:
  contents: read
  packages: write

jobs:
  build-and-push:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
      - uses: docker/setup-qemu-action@96fe6ef7f33517b61c61be40b68a1882f3264fb8 # v4.2.0
      - uses: docker/setup-buildx-action@bb05f3f5519dd87d3ba754cc423b652a5edd6d2c # v4.2.0
      - uses: docker/login-action@c99871dec2022cc055c062a10cc1a1310835ceb4 # v4.3.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@53b7df96c91f9c12dcc8a07bcb9ccacbed38856a # v7.3.0
        with:
          context: app
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ghcr.io/dekart-hub/devops-intro/quicknotes:${{ github.ref_name }}
            ghcr.io/dekart-hub/devops-intro/quicknotes:latest
```

It builds both `linux/amd64` (what Hugging Face pulls) and `linux/arm64`
(what this laptop pulls), tags the immutable version from the git tag plus the
moving `latest`, and needs no stored secrets: the workflow-scoped
`GITHUB_TOKEN` is enough for same-repo ghcr pushes.

### The release

```bash
git tag -a -s v0.1.0 -m "Lab 10 release"
git push origin v0.1.0
```

Green run for the tag: https://github.com/Dekart-hub/DevOps-Intro/actions/runs/28658814522

### Evidence: publicly pullable

Anonymous pull with no docker login (after `docker logout ghcr.io`):

```text
$ docker pull ghcr.io/dekart-hub/devops-intro/quicknotes:v0.1.0
Status: Downloaded newer image for ghcr.io/dekart-hub/devops-intro/quicknotes:v0.1.0
```

Belt and braces, an anonymous registry-API token also resolves the manifest
(no GitHub credentials involved):

```text
$ curl -s "https://ghcr.io/token?scope=repository:dekart-hub/devops-intro/quicknotes:pull"
  ... anonymous bearer token ...
$ curl -s -H "Authorization: Bearer $TOKEN" \
    https://ghcr.io/v2/dekart-hub/devops-intro/quicknotes/manifests/v0.1.0
mediaType: application/vnd.oci.image.index.v1+json
platform: linux/amd64
platform: linux/arm64
```

The pulled image runs and still carries the Lab 9 security headers:

```text
$ docker run -d --name quicknotes-v010 ghcr.io/dekart-hub/devops-intro/quicknotes:v0.1.0
$ wget -S -qO- http://quicknotes-v010:8080/health
{"notes":4,"status":"ok"}
  HTTP/1.1 200 OK
  X-Content-Type-Options: nosniff
```

### Design questions

**a) When would you reach for OIDC instead of `GITHUB_TOKEN`, and what does it
give you?**
`GITHUB_TOKEN` only authenticates inside GitHub's own walls; it is exactly
right for pushing to ghcr from the same repo. OIDC is for everything outside
those walls: AWS, GCP, Azure, Vault, or keyless artifact signing. The workflow
exchanges a short-lived identity token (carrying verifiable claims: which
repo, which ref, which workflow) for cloud credentials, so no long-lived
secret is stored in the repo at all, and the cloud side can enforce trust
policies like "only tag builds of this repo may assume the deploy role". What
it gives you over `GITHUB_TOKEN` is federated identity to third parties plus
the end of copy-pasted cloud keys that leak and never expire.

**b) Why still ship `:latest` alongside the immutable `:v0.1.0`?**
Different audiences. The immutable tag is the contract: deployments,
rollbacks, SBOMs, and scan results all reference an artifact that can never
change under them. `:latest` is the courtesy pointer for humans: `docker pull`
without a tag works, docs and quickstarts do not need editing every release,
and "give me the current one" has an answer. Production pins the version;
`latest` just has to exist and point somewhere sane.

**c) What does the narrow `packages: write` scope actually prevent?**
Least privilege for a token that runs inside a build that executes third-party
code (actions, base images, compilers). If any of that is compromised, a
`packages: write` token can at worst publish a bad package version, which is
visible and revertible. With broad write scopes the same compromise could push
commits, rewrite releases, edit workflows, or use the API to reach anything
else the token covers. SHA-pinning the actions reduces the chance of that
compromise; the narrow scope caps the damage if it happens anyway.

---

## Task 2 - Hugging Face Space

### The Space files (`cloud/hf-space/`)

The Space pulls the released image instead of rebuilding from source, so the
public URL serves the exact artifact that Lab 9 scanned and Task 1 tagged:

```dockerfile
FROM ghcr.io/dekart-hub/devops-intro/quicknotes:v0.1.0
ENV DATA_PATH=/tmp/notes.json
```

The `DATA_PATH` override exists because Hugging Face may run the container
under a different uid than the image's nonroot user; `/tmp` is writable for
any uid and Space storage is ephemeral anyway.

`README.md` frontmatter declares the Docker SDK and moves the app port off
HF's 7860 default, since QuickNotes listens on 8080 and the lab (correctly)
says not to change the app:

```yaml
---
title: QuickNotes
emoji: "..."
colorFrom: blue
colorTo: gray
sdk: docker
app_port: 8080
pinned: false
---
```

### Deploy and public URL

The Space was created and deployed with the `hf` CLI (no UI clicking needed
beyond the account):

```bash
hf repos create Dekarters/quicknotes --type space --space-sdk docker --public
hf upload Dekarters/quicknotes cloud/hf-space . --type space
hf spaces wait Dekarters/quicknotes   # stage=RUNNING
```

Space: https://huggingface.co/spaces/Dekarters/quicknotes
Public URL: https://dekarters-quicknotes.hf.space

```text
$ curl -i https://dekarters-quicknotes.hf.space/health
HTTP/2 200
content-type: application/json
content-security-policy: default-src 'none'; frame-ancestors 'none'
cross-origin-resource-policy: same-origin
x-content-type-options: nosniff
x-proxied-host: http://10.111.60.30
x-proxied-replica: r1vl70iz-vt5lx

{"notes":4,"status":"ok"}
```

`/notes` returns the seeded notes JSON. Note the Lab 9 security headers
arriving from HF's edge: the deployed artifact really is the hardened
release image.

### Scale-to-zero: warm vs cold

Warm, 5 consecutive requests (`curl -w '%{time_total}'`, DNS resolution
excluded via `--resolve`):

```text
0.605  0.490  0.374  0.441  0.437   seconds -> p50 = 0.441 s
```

A finding about today's free tier: the lab text expects sleep after about 30
minutes, but the Space runtime reports `sleep_time: 172800`, i.e. free
`cpu-basic` Spaces now sleep only after 48 hours idle, and setting a custom
sleep time is a paid-hardware feature (the sleeptime API refuses the request).
Waiting out three real sleep cycles is therefore not possible within the lab.
The honest equivalent used instead: force the container fully down and up
(`hf spaces pause` + restart) and time from the restart until the first
successful `/health` response, three cycles. This measures the same thing a
wake does (schedule + image pull + container start + routing), minus the
request-triggered wake path that the free tier no longer exposes at a
measurable timescale.

Three cycles, each timed from issuing the restart until the first successful
`/health` response (1 second polling):

```text
cycle 1: 10 s
cycle 2: 13 s
cycle 3: 11 s
```

So a cold start costs roughly 10 to 13 seconds against a warm p50 of 0.44 s:
about 25 times slower, and exactly the "seconds, not milliseconds" trade the
free tier makes for scale-to-zero. One more platform note: pausing a Space
needs only content-write permission, but restarting one requires a
write-scoped token (a content-only fine-grained token gets 401), which is
worth knowing before automating anything against the Spaces API.

### Design questions

**d) Why is HF's wake so much slower than Cloud Run's scale-to-zero?**
Different products optimizing different things. HF free Spaces optimize
hosting cost for a huge fleet of mostly idle hobby demos: sleep means the
container is fully gone, and wake means schedule a node, pull or restore the
image, start the container, then route: tens of seconds is acceptable because
nobody pays and the workload is a showcase. Cloud Run sells production request
serving: pre-provisioned worker pools, micro-VM snapshots, image streaming,
and aggressive routing warmup get cold starts to sub-second-to-seconds,
because customers pay exactly to not feel them.

**e) Why does the Space need `app_port: 8080`, and why is HF's default 7860?**
HF's ingress forwards traffic to one declared container port. Their default,
7860, is Gradio's default port, because the typical Space is a Gradio ML demo
and zero-config should just work for it. QuickNotes listens on 8080, so the
frontmatter tells the router where the app actually is; the alternative would
be changing the app to please the platform, which is backwards.

**f) Trade-off of pulling the ghcr image vs building from source in the
Space?**
Pulling deploys the exact bytes that were scanned, tested, and released: one
build pipeline, one source of truth, and the Space redeploy is just a pull.
The costs: the Space now depends on ghcr availability and on the package being
public, and iterating means going around the whole tag-release loop. Building
inside the Space is self-contained and faster to hack on (edit, push, HF
rebuilds), but it creates a second artifact from a second builder that can
drift from what was actually released and scanned; debugging "works in CI,
differs on HF" is exactly the class of problem the single-artifact rule
exists to prevent.

---

## Bonus - Cloudflare quick tunnel + comparison

### Setup

The same released image runs locally and a quick tunnel exposes it at an
ephemeral public URL, no account and no card:

```bash
docker network create lab10-tunnel
docker run -d --name quicknotes-v010 --network lab10-tunnel \
  ghcr.io/dekart-hub/devops-intro/quicknotes:v0.1.0
docker run -d --name tunnel --network lab10-tunnel \
  cloudflare/cloudflared:latest tunnel --protocol http2 \
  --url http://quicknotes-v010:8080
```

Two operational lessons happened by themselves here. First, cloudflared's
default QUIC transport (UDP 7844) was blocked by the local VPN, so the first
tunnel registered but every edge connection timed out
("failed to dial to edge with quic"); `--protocol http2` moves the tunnel
onto plain TCP 443 and it connected immediately. Second, the restart proved
the ephemerality warning: the first tunnel got one URL, the http2 replacement
got a completely different one. Quick tunnel URLs really do die with the
process.

Final URL: https://strictly-broke-rate-pills.trycloudflare.com

```text
$ curl https://strictly-broke-rate-pills.trycloudflare.com/health
{"notes":4,"status":"ok"}
```

### Reachability from a different network

Verified from a phone on cellular (different network, different public IP):
`https://strictly-broke-rate-pills.trycloudflare.com/health` returns the
health JSON. The laptop-local origin is genuinely reachable from the public
internet through Cloudflare's edge.

### Measurements

hyperfine, 50 runs per target plus 3 warmup runs, measured from the laptop
(the caveat from the lab guidelines applies: the tunnel numbers are measured
from the same machine that runs the origin, so they show the
client-to-edge-to-origin round trip from this network, not a distant user's
view; both targets were measured identically, so the comparison is fair):

```text
tunnel: p50 257 ms  p95 285 ms  (min 234, max 1170)
hf:     p50 384 ms  p95 616 ms  (min 363, max 1178)
```

### Comparison table

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local via edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | 384 ms | 257 ms |
| Warm p95 | 616 ms | 285 ms |
| Cold start | 10-13 s (3 cycles: 10/13/11) | N/A (continuously local) |
| Public URL stability | stable | ephemeral on restart (observed: URL changed on the QUIC-to-http2 restart) |
| Cost | free | free |

The tunnel wins on warm latency from this location: the nearest Cloudflare
edge is closer than HF's datacenter, and the origin hop is a local machine.
The flip side is everything the "cold start" row hides: the tunnel column has
no cold start only because the laptop is always on; close the lid and the
"platform" is gone, while the HF Space keeps existing and wakes on demand.

### Design questions

**g) Which one is "really cloud", and does the distinction matter to users?**
By the textbook definition (pooled provider resources, elastic, provider
operates the compute) HF Spaces is cloud and the tunnel is not: with the
tunnel, the origin is still my laptop; only the front door (TLS termination,
anycast routing, DDoS shield) is Cloudflare's. Users cannot tell from the URL,
and for them the distinction only materializes as operational properties:
availability tracks my laptop's lid instead of a datacenter SLO, capacity is
one machine, and the URL changes when the tunnel restarts. The lesson is that
"cloud" is about who owns the failure modes, not where the TLS cert lives.

**h) What dominates warm latency in each case?**
HF Spaces: the request crosses the public internet to HF's datacenter and
their ingress/routing layers before hitting the container; distance to the
region plus platform routing dominates, the app itself answers in
microseconds. Tunnel: the request goes client to the nearest Cloudflare edge,
then rides the tunnel's persistent connection from the edge to my laptop; the
dominant cost is that second leg (edge to origin over my uplink), so total
latency is roughly client-to-edge plus edge-to-laptop, and my home uplink is
the ceiling.

**i) When is Cloudflare Tunnel the right production pick, and when never?**
Right: exposing something that must stay where it is: a home lab, an on-prem
service behind NAT that needs a public endpoint without firewall holes, a dev
box URL for a stakeholder demo, or as a zero-trust ingress in front of
internal apps (named tunnels with access policies). Never: as the serving
platform for a real user-facing service, because the origin is still a single
machine you own: no elasticity, no provider SLO on the origin, and (for quick
tunnels) a URL that dies with the process. It is an ingress tool, not a
compute platform.

---

## Teardown

Documented in `cloud/teardown.md`. Nothing here costs money either way.
