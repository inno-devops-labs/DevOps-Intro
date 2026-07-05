# Lab 10 Submission — Cloud: Deploy QuickNotes Without a Credit Card

> Push the image to GHCR via CI (Task 1), deploy to Hugging Face Spaces (Task 2),
> optionally expose a local copy via Cloudflare Tunnel (bonus). Items marked
> _(paste from your run)_ need your GitHub/HF accounts and are yours to fill.

## Files
- Release workflow: [.github/workflows/release.yml](../.github/workflows/release.yml)
- HF Space image: [cloud/Dockerfile](../cloud/Dockerfile)
- HF Space metadata: [cloud/README.md](../cloud/README.md)

---

## Task 1 — CI push to `ghcr.io`

[release.yml](../.github/workflows/release.yml) triggers on `v*` tags, logs in to
GHCR with `GITHUB_TOKEN`, derives tags via `docker/metadata-action` (immutable
`{{version}}` + `latest`), and builds/pushes from `app/`. All actions are
SHA-pinned; `permissions:` is scoped to `contents: read` + `packages: write`.

### Release it
```bash
git tag -a -s v0.1.0 -m "Lab 10 release"
git push origin v0.1.0
```
Then in **GitHub → your profile → Packages → quicknotes → Package settings**, flip
visibility to **Public** (first push creates a *private* package).

### Verify a clean pull (from any machine, logged out)
```bash
docker pull ghcr.io/1am6ada/devops-intro/quicknotes:v0.1.0
docker run --rm -p 8080:8080 ghcr.io/1am6ada/devops-intro/quicknotes:v0.1.0 &
curl -s localhost:8080/health
```

- **Registry URL:** `ghcr.io/1am6ada/devops-intro/quicknotes` <!-- confirm owner is lowercased -->
- **Clean-pull evidence:** _(paste `docker pull` + `/health` output)_
- **Green release-run URL:** _(paste the Actions run URL)_

### Design answers

**a) OIDC vs `GITHUB_TOKEN`.**
For pushing to **ghcr.io from the same repo**, `GITHUB_TOKEN` with `packages: write`
is enough — it's already short-lived and repo-scoped. OIDC is preferable when
pushing to **external** registries/clouds (AWS ECR, GCP Artifact Registry, Azure):
the workflow exchanges a short-lived, workflow-scoped OIDC token with the provider
via federation, so you store **no long-lived cloud credentials** in GitHub secrets.
Advantages: nothing static to leak/rotate, short token lifetime, and fine-grained
trust conditions (repo/branch/environment).

**b) Why ship both `:latest` and `:v0.1.0`.**
The immutable `:v0.1.0` tag is what production pins to — a given version always maps
to the same digest, so deploys and rollbacks are reproducible and auditable. `:latest`
is a mutable convenience pointer for humans and quickstarts ("just pull latest") but
is unsafe to pin in production because it moves. Ship both: version for prod, latest
for discovery/dev.

**c) `packages: write` scope principle.**
**Least privilege** — grant only the scopes the job needs. `packages: write` lets the
job publish images but **not** push code (`contents: write`), cut releases, edit
issues, or administer the repo. If a step or third-party action is compromised, the
blast radius is limited to package publishing, not repo takeover — whereas `write: all`
would let an attacker rewrite code, move tags, or pivot to secrets.

---

## Task 2 — Deploy to Hugging Face Spaces

Create a **Docker SDK**, **public** Space at huggingface.co/new-space, clone its git
repo, and add the two files mirrored in [cloud/](../cloud/): a `Dockerfile` that
pulls `ghcr.io/<you>/devops-intro/quicknotes:v0.1.0` and a `README.md` whose
frontmatter declares `sdk: docker` and **`app_port: 8080`**. Push to the Space's
remote → HF auto-builds and serves at `https://<user>-<spacename>.hf.space`.

- **Space URL + `curl -v /health`:** _(paste)_
- **Space `Dockerfile` + `README.md`:** see [cloud/Dockerfile](../cloud/Dockerfile) and [cloud/README.md](../cloud/README.md)

### Scale-to-zero measurements
```bash
# warm p50 (5 immediate requests)
for i in $(seq 1 5); do curl -w '%{time_total}\n' -o /dev/null -s https://<user>-<space>.hf.space/health; done
# then idle 35+ min so the Space sleeps, and measure a cold request 3 times
```
| Measurement | Value |
|---|---|
| Warm p50 | _(paste)_ s |
| Cold #1 | _(paste)_ s |
| Cold #2 | _(paste)_ s |
| Cold #3 | _(paste)_ s |

### Design answers

**d) HF "sleep" vs Cloud Run "scale to zero" — why HF wakes slower.**
Both scale to zero to save cost, but they optimize for different things. HF free tier
optimizes for **cheap shared hosting of demos**: waking pulls and starts a full
container on shared hardware with little pre-warming, so cold starts run
seconds-to-minutes. Cloud Run optimizes for **request latency**: heavily engineered
cold-start (fast microVM/sandbox, image streaming, keep-warm heuristics) gets it to
sub-second/a-few-seconds. Different priorities — free demos vs production SLAs.

**e) Why `app_port: 8080`? HF's default?**
HF's default port is **7860** (the Gradio default HF standardized on). QuickNotes
listens on **8080**, so we must declare `app_port: 8080`; otherwise HF routes to 7860
and the Space shows nothing / the container looks dead.

**f) Pull image vs build inside the Space.**
**Pull** (our choice): fast (no build), reproducible (the exact CI-built, scanned
artifact — same digest everywhere), single source of truth; costs some in-Space
debuggability and needs the image to be public. **Build-in-Space:** HF shows build
logs (debuggable) and needs no registry, but it's slower (rebuild each push), can
drift from the CI image, and re-runs the toolchain. We chose pull for reproducibility
(documented in [cloud/Dockerfile](../cloud/Dockerfile)).

---

## Bonus — Cloudflare Tunnel + comparison

```bash
# run QuickNotes locally, then:
cloudflared tunnel --url http://localhost:8080
# -> prints a public https://<random>.trycloudflare.com URL
```
Verify from a **different network** (phone on cellular), then measure with hyperfine:
```bash
hyperfine -r 50 'curl -s -o /dev/null https://<random>.trycloudflare.com/health'
```

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|---:|---:|
| Warm p50 | _(paste)_ | _(paste)_ |
| Warm p95 | _(paste)_ | _(paste)_ |
| Cold start | _(paste)_ | N/A (continuously local) |
| Public URL stability | Stable | Ephemeral on restart |
| Cost | Free | Free |

- **Tunnel URL + cross-network verification:** _(paste)_

### Design answers

**g) Which is "really cloud"?**
HF Spaces is "really cloud" — compute and hosting live in HF's datacenter. Cloudflare
Tunnel is **edge-proxied local compute**: the container runs on your laptop and
Cloudflare just routes public traffic to it. To end users the distinction is invisible
(both give a working public HTTPS URL); operationally it matters a lot — with the
tunnel, if your machine sleeps or loses network, the service dies (no datacenter
durability or scaling).

**h) Latency dominator.**
For **HF warm**, the dominant cost is the network/proxy hop into HF's datacenter plus
shared-runtime overhead — the app itself is microseconds. For **Tunnel**, latency is
dominated by the round-trip through Cloudflare's edge down to your home/office uplink
(your ISP's upstream latency/bandwidth and the edge→origin hop), since the app is local.

**i) When is Tunnel the right production choice — and never?**
**Right:** exposing a home-lab/on-prem service without opening firewall ports, sharing
a temporary review/preview URL with stakeholders, or fronting an internal service via
a **named** tunnel + your own domain + Access policies. **Never** as the primary host
for a real user-facing app needing uptime/scale/durability — a laptop on a home
connection isn't a datacenter (no HA, dies on sleep), and quick-tunnel URLs are
ephemeral.

---

## Submission Checklist
- [ ] `release.yml` + `cloud/` (Dockerfile, README) + `submissions/lab10.md`
- [ ] Tagged release `v0.1.0` pushed; workflow green; image **public** & pullable
- [ ] HF Space serves `/health` + `/notes`; `app_port: 8080`; warm + 3 cold latencies
- [ ] (Bonus) tunnel reachable from another network; comparison table; answers g–i
- [ ] Design answers a–f
- [ ] PR `feature/lab10 → main` against **upstream** and **your fork**; both URLs in Moodle
