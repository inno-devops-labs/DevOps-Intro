# Lab 10 - Cloud Computing

## Status

Task 1 is complete: a signed `v0.1.0` tag triggered a pinned GitHub Actions release workflow, pushed the QuickNotes image to GHCR, and the image is publicly pullable without authentication.

Task 2 repo artifacts are prepared under `cloud/hf-space/`, but the live Hugging Face Space deployment and cold-start measurements were not completed from this machine because there is no Hugging Face login or token available:

```text
huggingface-cli whoami
Not logged in
```

The bonus Cloudflare Tunnel task was not attempted because `cloudflared` and `hyperfine` are not installed here, and the task also requires verification from a different network.

## Task 1 - GHCR Release

Release workflow: `.github/workflows/release.yml`

```yaml
name: Release QuickNotes Image

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

env:
  IMAGE_NAME: ghcr.io/valdezzar/devops-intro/quicknotes

jobs:
  build-and-push:
    name: Build and push image
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@8d2750c68a42422c14e847fe6c8ac0403b4cbd6f

      - name: Log in to GHCR
        uses: docker/login-action@c94ce9fb468520275223c153574b00df6fe4bcc9
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@10e90e3645eae34f1e60eeb005ba3a3d33f178e8
        with:
          context: ./app
          file: ./app/Dockerfile
          platforms: linux/amd64
          push: true
          tags: |
            ${{ env.IMAGE_NAME }}:${{ github.ref_name }}
            ${{ env.IMAGE_NAME }}:latest
          labels: |
            org.opencontainers.image.source=${{ github.server_url }}/${{ github.repository }}
            org.opencontainers.image.revision=${{ github.sha }}
            org.opencontainers.image.version=${{ github.ref_name }}
```

Release run:

- `https://github.com/Valdezzar/DevOps-Intro/actions/runs/36151054730`
- Status: `completed`
- Conclusion: `success`
- Tag: `v0.1.0`
- Commit: `e2399d80c6b1578246f6d620c45e91f7f9d97950`

Registry image:

- `ghcr.io/valdezzar/devops-intro/quicknotes:v0.1.0`
- `ghcr.io/valdezzar/devops-intro/quicknotes:latest`

Clean pull evidence from the Vagrant VM, without logging in to GHCR:

```text
$ sudo docker pull ghcr.io/valdezzar/devops-intro/quicknotes:v0.1.0
v0.1.0: Pulling from valdezzar/devops-intro/quicknotes
Digest: sha256:54526af8fdca76ba8f45bdcbbca57af5334f384fb0ed4b63ad0639a7395485e2
Status: Downloaded newer image for ghcr.io/valdezzar/devops-intro/quicknotes:v0.1.0
ghcr.io/valdezzar/devops-intro/quicknotes:v0.1.0
```

Smoke test of the pulled image:

```text
$ curl -fsS http://127.0.0.1:8080/health
{"notes":4,"status":"ok"}
```

## Task 2 - Hugging Face Space Artifacts

The Space should be created as a public Docker SDK Space, then the contents of `cloud/hf-space/` should be pushed to the Space Git repository.

Expected public URL after creating the Space:

```text
https://<hf-user>-quicknotes.hf.space/health
```

`cloud/hf-space/Dockerfile`:

```dockerfile
FROM ghcr.io/valdezzar/devops-intro/quicknotes:v0.1.0

ENV ADDR=:8080
ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/seed.json
```

`cloud/hf-space/README.md`:

```yaml
---
title: QuickNotes
emoji: "\U0001F4DD"
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
pinned: false
---
```

I chose to pull the immutable GHCR image in the Space Dockerfile instead of rebuilding from source inside Hugging Face. That makes the Space run the same artifact that CI released and keeps the HF build small and easy to inspect.

Latency measurements were not collected because the Space could not be created without Hugging Face credentials.

| Metric | Result |
|---|---:|
| Warm p50 | Not measured - HF login unavailable |
| Cold latency 1 | Not measured - HF login unavailable |
| Cold latency 2 | Not measured - HF login unavailable |
| Cold latency 3 | Not measured - HF login unavailable |

## Design Questions

a) I would use OIDC when pushing to an external cloud or registry that should not rely on a long-lived secret stored in GitHub. OIDC gives the cloud provider a short-lived, claims-bound identity for this specific repo, ref, and workflow run. For GHCR in the same repo, `GITHUB_TOKEN` with `packages: write` is enough because GitHub can authorize the package write directly.

b) The immutable `:v0.1.0` tag is the audit trail and rollback target. The mutable `:latest` tag is still useful for humans and simple consumers who want the current stable release without editing config every time. Production deployments should record the immutable tag or digest even if `latest` also exists.

c) The principle is least privilege. `packages: write` lets the workflow publish images but does not grant broad repository write powers. If the workflow or one action is compromised, the narrow token cannot rewrite code, alter issues, edit releases, or mutate unrelated repo state the way a wider token could.

d) HF Spaces sleep is closer to pausing a user-facing development container and later rebuilding or rehydrating that environment. Cloud Run is built for fast request-driven autoscaling with infrastructure optimized around cold starts. HF optimizes for free hosted demos and GPU/app workloads, not low-latency production API wakeups.

e) HF defaults to port `7860` because many Spaces are Gradio demos, and Gradio commonly serves on `7860`. QuickNotes listens on `8080`, so `app_port: 8080` tells HF which container port to route public traffic to.

f) Pulling from GHCR improves reproducibility because the Space runs exactly the tagged image CI built. It also makes HF builds faster and simpler. Building inside the Space can be easier for debugging because all source is in the Space repo, but then HF has a second build pipeline that can drift from CI.

## Bonus

The Cloudflare Tunnel bonus was not attempted in this PR.
