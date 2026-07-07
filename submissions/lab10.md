# Lab 10: Cloud Computing – Ship QuickNotes to a Real Cloud

## Task 1: CI Push to GHCR

### Release workflow

Workflow: `.github/workflows/release.yml`

- Triggers on `v*` tags
- Builds QuickNotes from `app/`
- Pushes both `:<version>` and `:latest`
- Uses only `packages: write`
- All third-party actions are pinned to 40-character SHAs

```yaml
on:
  push:
    tags: ['v*']

permissions:
  contents: read
  packages: write

jobs:
  publish:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - id: img
        run: echo "name=ghcr.io/${GITHUB_REPOSITORY,,}/quicknotes" >> "$GITHUB_OUTPUT"
      - uses: docker/setup-buildx-action@bb05f3f5519dd87d3ba754cc423b652a5edd6d2c
      - uses: docker/login-action@af1e73f918a031802d376d3c8bbc3fe56130a9b0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@53b7df96c91f9c12dcc8a07bcb9ccacbed38856a
        with:
          context: ./app
          push: true
          tags: |
            ${{ steps.img.outputs.name }}:${{ github.ref_name }}
            ${{ steps.img.outputs.name }}:latest
```

### Registry

Package:

```
ghcr.io/danielpancake/devops-intro/quicknotes
```

Clean pull:

```text
docker pull ghcr.io/danielpancake/devops-intro/quicknotes:v0.1.0

Status: Downloaded newer image
Digest: sha256:5b456746231d865812b6a72dd2341a94b7c4bb60ce5464929989a2c534b01bbf
```

### CI Run

[https://github.com/danielpancake/DevOps-Intro/actions/runs/28894208488](https://github.com/danielpancake/DevOps-Intro/actions/runs/28894208488)

### Design Questions

#### a) OIDC vs `GITHUB_TOKEN`

`GITHUB_TOKEN` with `packages: write` is enough for pushing to GHCR from the same repository. OIDC is mainly used when authenticating to external cloud providers without storing long-lived credentials.

#### b) Why publish both `latest` and `v0.1.0`?

The version tag is immutable and should be used for deployments. `latest` is a convenience tag that always points to the newest release.

#### c) Why only `packages: write`?

It follows the principle of least privilege. Restricting permissions limits the damage if the workflow or token is compromised.

# Task 2: Hugging Face Spaces

## Space URL

Repository:

[https://huggingface.co/spaces/danielpancake/quicknotes](https://huggingface.co/spaces/danielpancake/quicknotes)

Application:

[https://danielpancake-quicknotes.hf.space](https://danielpancake-quicknotes.hf.space)

Health check:

```text
curl -si https://danielpancake-quicknotes.hf.space/health

HTTP/1.1 200 OK
Content-Type: application/json

{"notes":4,"status":"ok"}
```

## Space Files

### Dockerfile

```dockerfile
FROM ghcr.io/danielpancake/devops-intro/quicknotes:v0.1.0
```

### README.md

```yaml
---
title: QuickNotes
emoji: 📝
sdk: docker
app_port: 8080
---
```

## Latency

| Measurement                     | Time (s) |
| ------------------------------- | -------: |
| Warm p50 (5 back-to-back)       |    0.571 |
| First request after 35 min idle |    0.853 |

Warm samples:

```
0.731
0.724
0.564
0.554
0.571
```

## Design Questions

#### d) Why is HF sleep slower than Cloud Run?

HF Spaces prioritizes free hosting and shared resources, so waking a container takes longer. Cloud Run is optimized for fast autoscaling.

#### e) Why `app_port: 8080`?

HF Docker Spaces default to port **7860**. QuickNotes listens on **8080**, so `app_port: 8080` is required.

#### f) Pull image vs build inside the Space?

Pulling from GHCR deploys the same tested image produced by CI. Building inside the Space is more independent but duplicates the build process.
