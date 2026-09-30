# Lab 10 — QuickNotes in GHCR and GitHub Codespaces

## Environment and platform choice

Repository: [SanyaLikeIT/DevOps-Intro](https://github.com/SanyaLikeIT/DevOps-Intro), branch `feature/lab10`.

Render requested card verification on this account. No payment method was added. The assignment's Task 2 Option B, GitHub Codespaces, was selected.

## Task 1 — CI automated push to GHCR

### Release workflow

The [release workflow](../.github/workflows/release.yml) triggers on pushed `v*` tags. It builds from `app/` for `linux/amd64`, authenticates to GHCR with `GITHUB_TOKEN`, and publishes both the release version and `latest`. The job grants only `contents: read` and `packages: write`.

| Action | Release | Pinned commit |
|---|---|---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `docker/login-action` | v4.6.0 | `dbcb813823bdd20940b903addbd779551569679f` |
| `docker/setup-buildx-action` | v4.3.0 | `37fe631027851001ddb9b187196cc803df7f5f0e` |
| `docker/build-push-action` | v7.4.0 | `c3c9e263c25d99ce0380d002d59b67737d91b0dc` |

### Signed release and registry image

- Signed tag: `v0.1.1`, pointing to `e0745d0a9d7691a826e10c1def019a45ad283d84`.
- Signature: verified with the existing ED25519 signing key.
- [Successful release run](https://github.com/SanyaLikeIT/DevOps-Intro/actions/runs/36334925479), run ID `36334925479`.
- Exact image: `ghcr.io/sanyalikeit/devops-intro/quicknotes:v0.1.1`.
- Registry digest: `sha256:0b007f8f4ad619838c7d99f715f9d09c47cc6d5015925492dc8d61d538ca60c4`.
- An anonymous `docker pull` succeeded with an empty temporary `DOCKER_CONFIG`; [pull evidence](../evidence/lab10/02-anonymous-pull.txt) and [release evidence](../evidence/lab10/01-release.txt).

### Design questions

#### a) OIDC vs `GITHUB_TOKEN`

For this repository's GHCR package, the workflow's short-lived `GITHUB_TOKEN` with `packages: write` is sufficient. OIDC is useful when publishing to an external cloud provider that accepts GitHub identity claims and exchanges them for short-lived credentials. The provider can restrict trust by repository, ref, and workflow. This avoids storing a long-lived cloud key as a repository secret and reduces credential rotation work.

#### b) `latest` vs a version tag

`v0.1.1` identifies this release; deployments should select the version tag or digest so they remain reproducible. `latest` is a mutable convenience pointer for users who deliberately want the newest release without changing the image reference.

#### c) Least privilege

`contents: read` lets the workflow check out source and `packages: write` lets it publish the image. `write-all` would also grant unrelated repository write capabilities. If a build step or dependency were compromised, the narrower token would prevent it from using those unrelated permissions to modify repository content or other resources.

## Task 2 — GitHub Codespaces Option B

The [devcontainer](../.devcontainer/devcontainer.json) installs Docker, forwards port 8080, and runs the [startup script](../.devcontainer/start-quicknotes.sh) on each Codespace start. The script pulls the exact release image above. The persistent notes directory is `/workspaces/.quicknotes-lab10-data`, mounted to `/data` inside the container. [Configuration notes](../cloud/devcontainer.md).

### Codespace and public port

The `codespace` CLI scope was authorized through GitHub browser approval. The Codespace `quicknotes-lab10-verified-xj5jj5797p4c9qr7` was created from `feature/lab10` using `basicLinux32gb` (2 cores, 8 GB RAM). `gh codespace ports` showed port 8080 with `visibility=public` and browse URL `https://quicknotes-lab10-verified-xj5jj5797p4c9qr7-8080.app.github.dev`.

Plain laptop `curl` requests without a GitHub token or browser login returned HTTP 200 for [`/health`](https://quicknotes-lab10-verified-xj5jj5797p4c9qr7-8080.app.github.dev/health) and [`/notes`](https://quicknotes-lab10-verified-xj5jj5797p4c9qr7-8080.app.github.dev/notes). The response to `/health` was `{"notes":4,"status":"ok"}` before the persistence test. [Codespace evidence](../evidence/lab10/03-codespace.txt) includes the machine, branch, public port, running image, and responses.

### Warm and cold latency

Five consecutive public `/health` `curl` requests took `0.957022`, `0.447903`, `0.505269`, `0.406993`, and `0.435737` seconds. Their p50 (median) was **0.447903 s**.

A stopped Codespace did not wake from an HTTP request. Each cold cycle confirmed the `Shutdown` state, requested the public URL once, sent an explicit GitHub REST start request, restored the port's public visibility, and timed until the first public `/health` HTTP 200.

| Cycle | Stopped public URL | Manual start → public `/health` 200 |
|---|---|---:|
| 1 | HTTP 404, 6.041646 s | 49.013 s |
| 2 | HTTP 404, 11.126035 s | 97.702 s |
| 3 | HTTP 404, 1.349386 s | 179.437 s |

The third measurement includes observed GitHub API and tunnel network delays. [Cold cycle evidence](../evidence/lab10/05-codespace-cold.txt) records timestamps and results. The port became private after every restart, so public visibility had to be set again.

A separate sample of 50 successful warm public `/health` requests gave **p50 0.431468 s**, **p95 0.689285 s**, min `0.386738 s`, and max `0.960635 s`. Percentiles use nearest rank on sorted values (one-based index `ceil(p*n)`). [Raw samples](../evidence/lab10/04-codespace-latency.txt) are preserved.

### Persistence experiment

A public `POST /notes` returned HTTP 201 for note ID `5`, title `lab10-codespace-persistence-20260927T171407Z`. It appeared in `GET /notes` before the third stop and remained available through `GET /notes` and `GET /notes/5` after restart. [Persistence evidence](../evidence/lab10/06-codespace-persistence.txt). The file is in the bind-mounted `/workspaces/.quicknotes-lab10-data` directory, which persisted across ordinary stop/start.

### Design questions

#### d) Stopped Codespace vs Render spin-down

Both can stop compute. A Render web service is designed to wake on an incoming request; the stopped Codespace required an explicit start. In all three cycles the stopped public URL returned HTTP 404 and did not start it. That request-driven wake behavior is a key distinction between hosting and this development environment. The three measured manual start times were 49.013, 97.702, and 179.437 seconds.

#### e) Codespaces and production hosting

Codespaces is a development environment with a manually controlled lifecycle, forwarded development ports, idle timeout, and included-use quota. In this lab the public port reverted to private after each restart and the URL could not wake the stopped VM. This setup has no demonstrated production availability guarantee, scaling, or redundancy. A production QuickNotes service would need an owned ingress/domain and TLS configuration, durable external data storage with backups, monitoring and alerts, secure secret management, a deployment strategy, and capacity or failover planning. GitHub's Codespaces terms position it for development rather than production traffic.

#### f) Where the note went

The note survived because normal Codespace stop/start preserved `/workspaces/.quicknotes-lab10-data`, which was bind-mounted into the QuickNotes container. Deleting the Codespace is a separate action and should not be treated as equivalent to stopping it. A Render free instance's ephemeral filesystem would not provide the same persistence guarantee; that comparison is architectural because Render was not deployed here. The Codespace directory is still not a production database, so production would use external durable storage.

## Bonus — Cloudflare Quick Tunnel

The same immutable image `ghcr.io/sanyalikeit/devops-intro/quicknotes:v0.1.1` ran locally as `quicknotes-lab10-tunnel`. Its container port 8080 was mapped to `127.0.0.1:18081` because another local QuickNotes service already occupied host port 8080. The local `/health` and `/notes` endpoints both returned HTTP 200.

With the VPN enabled and a working endpoint selected, `cloudflared tunnel --protocol http2 --loglevel info --url http://127.0.0.1:18081` registered an edge connection. Its temporary URL was `https://bee-viewers-learning-cover.trycloudflare.com`. Plain laptop `curl` without authentication returned HTTP 200 for [`/health`](https://bee-viewers-learning-cover.trycloudflare.com/health) and [`/notes`](https://bee-viewers-learning-cover.trycloudflare.com/notes). The user also confirmed that `/health` displayed QuickNotes JSON on a phone with Wi-Fi off and mobile data on: `готово — /health открылся`. Earlier VPN endpoints failed to register with Cloudflare; their temporary URLs were not used as success evidence.

### 50-request comparison

Both warm samples contain 50 consecutive successful public `/health` requests from the laptop. Percentiles use the same nearest-rank method on sorted values, with one-based index `ceil(p*n)`. The [raw Cloudflare samples and connection evidence](../evidence/lab10/07-cloudflare.txt) and [raw Codespaces samples](../evidence/lab10/04-codespace-latency.txt) are preserved.

| Metric | GitHub Codespaces | Cloudflare Quick Tunnel |
|---|---:|---:|
| Warm p50 | 0.431468 s | 0.302855 s |
| Warm p95 | 0.689285 s | 1.301399 s |
| Warm min / max | 0.386738 / 0.960635 s | 0.230481 / 15.260199 s |
| Manual cold start | 49.013 / 97.702 / 179.437 s | N/A for continuously running local process |
| Public URL stability | stable while Codespace and public port exist | temporary URL changes on restart |
| Compute location | GitHub cloud VM | local laptop |
| Cost in this lab | included personal quota | free Quick Tunnel |

The Tunnel sample's typical response was 0.128613 s faster at p50, while its p95 was 0.612114 s slower. One Tunnel request took 15.260199 s. These end-to-end samples show variability but do not identify which internal network segment caused it.

### Design questions

#### g) Architecture

For Codespaces, a client reaches GitHub's forwarded-port infrastructure, then the cloud VM and QuickNotes container. For the tunnel, the client reaches Cloudflare's edge, which proxies over an outbound tunnel to the laptop and its QuickNotes container. Both expose a public URL, but the compute and failure dependencies differ: the Codespace depends on a running GitHub development VM, while the Quick Tunnel depends on the laptop, its power, and its uplink.

#### h) Warm latency contributors

Codespaces measured p50 0.431468 s and p95 0.689285 s. Potential contributors are client network RTT, GitHub's forwarded-port proxy, the VM, and QuickNotes. Cloudflare measured p50 0.302855 s and p95 1.301399 s, with a 15.260199 s maximum. Potential contributors there are the path to Cloudflare's edge, edge-to-tunnel routing over the VPN, the laptop uplink, and QuickNotes. The measurements were end-to-end; no individual layer was isolated as dominant. The Cloudflare tail suggests occasional path or service delay, but these data alone cannot assign it to a specific component.

#### i) Appropriate use of Cloudflare Tunnel

Cloudflare Tunnel can expose a home lab, on-premises service, temporary development URL, stakeholder demo, or webhook endpoint without inbound firewall configuration. A temporary Quick Tunnel to a laptop is unsuitable for a production service requiring a stable hostname, high availability, autoscaling, an SLA, or survival across laptop sleep and restart. That limitation concerns this temporary laptop setup; a managed named Cloudflare Tunnel with a stable domain and reliable origin infrastructure can be part of a production architecture. [Teardown instructions](../cloud/teardown.md).
