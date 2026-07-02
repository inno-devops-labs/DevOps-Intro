# Lab 10 - Cloud Computing: GHCR + Hugging Face Spaces + Cloudflare Tunnel

## Implemented files

- [`.github/workflows/release.yml`](../.github/workflows/release.yml)
- [`app/Dockerfile`](../app/Dockerfile)
- [`app/.dockerignore`](../app/.dockerignore)
- [`compose.yaml`](../compose.yaml)
- [`cloud/huggingface/Dockerfile`](../cloud/huggingface/Dockerfile)
- [`cloud/huggingface/README.md`](../cloud/huggingface/README.md)
- [`cloud/tunnel/README.md`](../cloud/tunnel/README.md)
- [`cloud/teardown.md`](../cloud/teardown.md)
- [`security/lab10/ghcr-release-run.txt`](../security/lab10/ghcr-release-run.txt)
- [`security/lab10/ghcr-clean-pull.txt`](../security/lab10/ghcr-clean-pull.txt)
- [`security/lab10/cloudflare-tunnel.txt`](../security/lab10/cloudflare-tunnel.txt)
- [`security/lab10/cloudflare-hyperfine.json`](../security/lab10/cloudflare-hyperfine.json)

## Task 1 - GHCR release workflow

The release workflow is stored at [`.github/workflows/release.yml`](../.github/workflows/release.yml). It triggers on tags matching `v*`, builds from `app/`, pushes to GHCR, and publishes both the immutable release tag and `latest`.

Image URL:

```text
ghcr.io/bearax/devops-intro/quicknotes:v0.1.0
ghcr.io/bearax/devops-intro/quicknotes:latest
```

Workflow excerpt:

```yaml
on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

jobs:
  publish:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: docker/setup-buildx-action@6524bf65af31da8d45b59e8c27de4bd072b392f5
      - uses: docker/login-action@9780b0c442fbb1117ed29e0efdff1e18412f7567
      - uses: docker/build-push-action@ca877d9245402d1537745e0e356eab47c3520991
```

Release evidence:

```text
Tag: v0.1.0
Run URL: https://github.com/BearAx/DevOps-Intro/actions/runs/28587249995
Status: completed
Conclusion: success
```

Clean pull evidence:

```text
Command used a temporary empty Docker config directory, so no saved GHCR credentials were used:

docker --config <empty-temp-dir> pull ghcr.io/bearax/devops-intro/quicknotes:v0.1.0

Output excerpt:
v0.1.0: Pulling from bearax/devops-intro/quicknotes
Digest: sha256:2b74b9b9f7eae6e9f6d74deb323876c5a3db2aa4012ef8203a38fd9f6d3e5c85
Status: Downloaded newer image for ghcr.io/bearax/devops-intro/quicknotes:v0.1.0
ghcr.io/bearax/devops-intro/quicknotes:v0.1.0
```

### a) OIDC vs `GITHUB_TOKEN`

For pushing to GHCR from the same repository, `GITHUB_TOKEN` with `packages: write` is enough because GitHub issues the token directly to the workflow and scopes it to the repo. I would use OIDC when deploying to an external cloud such as AWS, GCP, Azure, or a separate registry where short-lived federated credentials are safer than storing a long-lived secret. OIDC gives the external provider a verifiable identity claim for the workflow, branch, tag, and repo.

### b) `latest` vs immutable release tags

The immutable tag, such as `v0.1.0`, is what production rollbacks and audits should use. `latest` is still useful as a convenience pointer for humans, demos, smoke tests, and platforms that intentionally track the newest release. It should never be the only release identity.

### c) Narrow `packages: write`

The principle is least privilege. The workflow needs to read source and write one package; it does not need broad repository write access. Avoiding `write-all` limits damage if a build step or dependency is compromised, because the token cannot edit code, issues, pull requests, or unrelated repo settings.

## Task 2 - Hugging Face Spaces

The Space artifact lives in [`cloud/huggingface/`](../cloud/huggingface/).

`Dockerfile`:

```dockerfile
FROM ghcr.io/bearax/devops-intro/quicknotes:v0.1.0
```

`README.md` frontmatter:

```yaml
---
title: QuickNotes
emoji: 📝
sdk: docker
app_port: 8080
pinned: false
---
```

Space URL:

```text
Blocked in this environment: no Hugging Face token, CLI login, or cached HF credentials were available.
```

`curl -v /health` evidence:

```text
Blocked until the Space repository can be created and pushed with a Hugging Face account token.
```

Latency evidence:

| Measurement | Value |
|---|---:|
| Warm p50, 5 consecutive requests | Blocked by missing HF deployment |
| Cold start #1 | Blocked by missing HF deployment |
| Cold start #2 | Blocked by missing HF deployment |
| Cold start #3 | Blocked by missing HF deployment |

I chose the pull-from-GHCR Space Dockerfile so the Space runs the same tested release artifact that CI published. That makes the deployed image easier to correlate with the release tag and SBOM than rebuilding independently inside the Space.

### d) HF sleep vs Cloud Run scale to zero

Both stop idle compute, but they optimize for different products. Cloud Run is built as a production request-serving platform with fast scheduling and managed container startup paths. HF Spaces is optimized for free interactive demos and ML apps, so waking a sleeping Space may include slower queueing, image/container startup, and app initialization.

### e) `app_port: 8080`

Hugging Face Docker Spaces default to port `7860`, which matches the common Gradio/Spaces convention. QuickNotes listens on `8080`, so the Space metadata must declare `app_port: 8080` or HF will route traffic to the wrong port.

### f) Pulling from GHCR vs building inside the Space

Pulling from GHCR is more reproducible: the Space runs the exact image produced by the release workflow. It also improves caching because HF only needs to pull the released image layer set. Building in the Space can be easier to debug in HF logs and avoids public registry visibility problems, but it creates a second build path that can drift from CI.

## Bonus - Cloudflare Tunnel comparison

Tunnel runbook: [`cloud/tunnel/README.md`](../cloud/tunnel/README.md).

Cloudflare quick tunnel URL:

```text
https://imperial-recipients-traditional-gras.trycloudflare.com
```

External reachability evidence:

```text
cloudflared created a public trycloudflare.com URL that reached the local GHCR image:

curl.exe -s https://imperial-recipients-traditional-gras.trycloudflare.com/health
{"notes":4,"status":"ok"}

Single request timing:
time_total=0.436720

I could not perform a phone/cellular verification from this non-interactive environment.
```

Warm latency evidence:

```text
hyperfine --warmup 5 --runs 50 "curl.exe -s -o NUL https://imperial-recipients-traditional-gras.trycloudflare.com/health"

mean=389.8 ms
stddev=43.4 ms
min=339.3 ms
max=528.8 ms
runs=50
p50=375.8 ms
p95=483.9 ms
```

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | Blocked by missing HF deployment | 375.8 ms |
| Warm p95 | Blocked by missing HF deployment | 483.9 ms |
| Cold start | Blocked by missing HF deployment | N/A (continuously local) |
| Public URL stability | stable | ephemeral on restart |
| Cost | free | free |

### g) Architectural difference

HF Spaces runs the container in HF's infrastructure, while Cloudflare Tunnel keeps the container on my machine and proxies public traffic through Cloudflare's edge. Both can be useful to users because both provide a public HTTPS URL, but operationally they are very different: HF hosts the workload, while the tunnel depends on my laptop staying online.

### h) Latency dominator

For HF Spaces, warm latency is dominated by the path to HF's region plus the hosted container's request handling. Cold latency is dominated by waking and starting the sleeping Space. For Cloudflare Tunnel, the slow part is the proxy path from user to Cloudflare edge, through the tunnel connection, back to the laptop, and then the response along the same route.

### i) When Cloudflare Tunnel is the right production pick

It can be right for home labs, internal tools, on-prem services that need controlled external access, and temporary stakeholder review URLs. It is not the right pick when production availability depends on a laptop, unstable home internet, or an unmanaged local process.
