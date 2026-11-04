# Lab 10 — QuickNotes on GHCR, Render and Cloudflare Tunnel

Date: 2026-11-04. Uses the current Render version of Task 2, including a CI deploy
hook and checking notes after spin-down. All three idle/wake cycles are recorded.

## Task 1 — tagged CI publication

[release.yml](../.github/workflows/release.yml) runs on a `v*` tag and validates
`vMAJOR.MINOR.PATCH`. It tests QuickNotes, builds `linux/amd64` from `app/`, pushes
version and latest tags, verifies an anonymous clean pull, then calls Render.
Only the publishing job has `packages: write`; checkout has `contents: read`.
Authentication uses the repository's `GITHUB_TOKEN`. The single third-party
action is pinned to its full 40-character SHA. Existing version images are
reused only if their revision label matches the tagged source; rerunning a
release does not rebuild/overwrite its version image. `latest` remains mutable.

- Signed release tag: [`v0.1.3`](https://github.com/4rni4ka/DevOps-Intro/tree/v0.1.3), on the fork's `main` commit `6f9920dfa9a751d651396d1869bc29b6637c4d69`.
- Registry: `ghcr.io/4rni4ka/devops-intro/quicknotes:v0.1.3` and `ghcr.io/4rni4ka/devops-intro/quicknotes:latest`.
- Digest: `sha256:d9f659526c98b9b5e795e65b661764295a6dd5ff2b29a5fc196f63ff25705a64`.
- [Green release run](https://github.com/4rni4ka/DevOps-Intro/actions/runs/41818708980), [full log](evidence/lab10/release-v0.1.3.txt), [tag signature verification](evidence/lab10/tag-signature.txt).
- [Clean anonymous pull from this machine](evidence/lab10/anonymous-pull.txt), using an empty Docker configuration. CI also removes both local tags and pulls the version with a new empty `DOCKER_CONFIG`; neither check relies on registry login credentials.
- The final published image was also scanned with pinned Trivy 0.71.1: [JSON](evidence/lab10/trivy-release.json), [CycloneDX SBOM](evidence/lab10/quicknotes-release.cdx.json). No HIGH/CRITICAL findings were reported. Remote `linux/amd64` analysis avoids a Docker image-store export issue.

**a)** `GITHUB_TOKEN` with package write access is sufficient for this repo's GHCR
package. Use OIDC for an external cloud role: the provider checks issuer,
audience and repository/ref claims, then issues short-lived credentials. This
avoids storing a long-lived cloud key and limits trust to selected workflows.

**b)** `latest` is a convenient default/discovery channel. Version tags provide
named releases and rollback targets, but a registry can still overwrite a tag;
the workflow guards reruns and the recorded digest is the strict content
identity. Render's hook explicitly selects the new version.

**c)** Least privilege limits the effect of a compromised action or build step.
This publisher cannot use `contents: write` to alter source, Git tags or releases,
or broadly modify repository resources as `write-all` would allow. It can still
write packages, so image poisoning is within the remaining token's capabilities.

## Task 2 — Render Free and CI redeployment

Public service: [https://quicknotes-4rni4ka.onrender.com](https://quicknotes-4rni4ka.onrender.com).
Option A was used: Render accepted Free without a card, so Codespaces was not
needed. [Configuration](../cloud/render.md): Existing Image, **Free**, Frankfurt,
`PORT=10000`, `ADDR=:10000`, health check `/health`; image defaults provide
`DATA_PATH=/data/notes.json` and `SEED_PATH=/seed.json`. No persistent disk is
attached. The application was not changed for port discovery.

The service was created from v0.1.1, then **a new v0.1.3 tag** triggered the
release workflow, published the image and redeployed Render through its hook.
The hook is stored only as `RENDER_DEPLOY_HOOK` in Actions Secrets. The step
URL-encodes `imgURL`, keeping the host/image path identical and changing the tag.
An accepted hook is followed by observing the deployment live and testing JSON;
hook acceptance alone is not treated as application readiness.

- Service ID: `srv-dblgvft9el5s73d15alg`.
- Deployment: `dep-dblh45oae00c73c83p90`, **Live**, **v0.1.3**, trigger **Deploy Hook**, source `d9f6595`.
- [Deployment screenshot](evidence/lab10/render-deploy.png) and [saved deploy log](evidence/lab10/render-deploy-log.txt).
- Port log: `2026/11/04 11:08:14 quicknotes listening on :10000 (notes loaded: 4)`.
- No `New primary port detected` restart occurred; the deployment took about 11.1 s.
- [Verbose unauthenticated /health request](evidence/lab10/render-health.txt); `/notes` is also exercised by the persistence probe.

### Warm and cold observations

[`measure.py`](../scripts/lab10/measure.py) made five immediate warm requests,
then POSTed a uniquely named disposable note before each **21-minute no-traffic
period**. Each wake records its first response, time until genuine QuickNotes
JSON, and the complete notes list. The script compares both note ID and unique
title to avoid mistaking a reseeded/reused ID for persistence.

Five-request warm p50 from the Windows client:
**0.326343 s**. Raw responses, timestamps, measured idle
duration and note results: [render-measurements.json](evidence/lab10/render-measurements.json).

| Cycle | Actual idle time | First request | Until QuickNotes JSON ready | Note survived |
|---|---:|---:|---:|---|
| 1 | 1260.011 s | 13.968635 s | 13.984340 s | False |
| 2 | 1260.001 s | 12.621119 s | 12.621297 s | False |
| 3 | 1260.000 s | 13.966436 s | 13.966703 s | False |

**d)** Both Render spin-down and Cloud Run scale-to-zero release idle capacity.
Render Free prioritizes low-cost shared preview hosting; scheduling, image setup
and process startup make its wake much slower than a tiny Go process alone.
Cloud Run is optimized for request-driven autoscaling and offers startup controls
and minimum instances. The observations above measure this service rather than
assuming a platform-wide startup guarantee.

**e)** `PORT` tells the platform which listener to route to; Docker `EXPOSE` is
metadata and does not bind a socket. `PORT=10000` and `ADDR=:10000` agree from the
first boot. A mismatch can force port detection and an extra restart/deploy
cycle, delaying rollout and repeating startup work. This deploy avoided it.

**f)** Existing Image reuses the CI-built, scanned artifact and avoids a second
build with potentially different tool/base inputs. Building from Git offers
convenient setup and Render's build cache but can produce a different image.
The digest identifies the exact artifact. Free's writable filesystem is
ephemeral: spin-down discards runtime changes, and a new process seeds its notes
file again. The observations above determine whether the probe note survived.

## Bonus — same image via Cloudflare Tunnel

[Tunnel configuration](../cloud/tunnel.md): cloudflared **2026.10.7**, HTTP/2,
origin `http://127.0.0.1:8081`, public quick URL
`https://assured-opposed-leather-belief.trycloudflare.com`.
The local container runs the **same GHCR v0.1.3 digest** as Render:
[image identity](evidence/lab10/image-digest.txt).

The [independent-network benchmark](https://github.com/4rni4ka/DevOps-Intro/actions/runs/41818175008/attempts/2)
used a GitHub-hosted Ubuntu runner, without authentication to either endpoint.
Both `/health` responses were checked as QuickNotes JSON. Hyperfine **1.18.0**
made five warmups and **50 measured requests per endpoint** from the same
machine. [Runner log](evidence/lab10/tunnel-remote.txt),
[tunnel timing JSON](evidence/lab10/tunnel-remote-hyperfine.json),
[Render timing JSON](evidence/lab10/render-remote-hyperfine.json).
Percentiles are median and nearest-rank p95; warmups are excluded. Curl process
time includes DNS, connection/TLS and transfer, not only handler time.

| Metric | Render | Cloudflare Tunnel |
|---|---:|---:|
| Warm p50, same external runner | 0.156126 s | 0.328537 s |
| Warm p95, same external runner | 0.347974 s | 0.792971 s |
| Cold starts, Windows client | 13.984 s, 12.621 s, 13.967 s | N/A while local process runs |
| Public URL stability | Stable service URL | Ephemeral; changes on restart |
| Cost | Free | Free quick tunnel |

A separate preliminary local-host control used hyperfine 2.0.0 (five warmups,
50 runs): [JSON](evidence/lab10/tunnel-local-hyperfine.json),
[summary](evidence/lab10/tunnel-local-hyperfine.txt). It used the earlier local
Lab 9 build and is not substituted for the independent same-image comparison.

**g)** Render outsources origin compute to its datacenter. Tunnel provides cloud
ingress while origin compute stays on the laptop. Both use cloud services;
users mainly care about availability, latency and data durability. The laptop
and its ISP remain failure points in the tunnel architecture.

**h)** Warm Render latency mainly reflects client-to-region RTT/TLS and routing
for this tiny API; a cold request adds wake time. Tunnel adds the client-to-edge
path plus the edge-to-home connection, where ISP upload, local network and
laptop load can dominate. The measured values also include curl startup.

**i)** A managed named tunnel suits home labs, on-prem services and authenticated
review environments when origin uptime, access control and network capacity are
managed. An anonymous quick tunnel suits temporary demos. A personal laptop's
quick tunnel is unsuitable for an always-on durable production notes service
or sensitive unauthenticated data: no stable URL or origin redundancy exists.

## Teardown

[cloud/teardown.md](../cloud/teardown.md) records cleanup. Render remains on Free
for grading; no paid upgrade or disk was selected. Quick-tunnel availability
depends on the local client/container. The quick-tunnel client was stopped
after evidence capture. Local test-container removal is deferred while Docker
Desktop is stopped; the cloud service remains available.
