# Lab 10 - Cloud Computing: QuickNotes on GHCR + Hugging Face Spaces

## Overview

This lab releases the QuickNotes Docker image to GitHub Container Registry using a tag-triggered GitHub Actions workflow, then deploys the same image to Hugging Face Spaces using the Docker SDK.

The deployed public service is:

```text
https://minimizec-quicknotes.hf.space
```

---

# Task 1 - CI-Automated Push to GitHub Container Registry

## Release workflow

File:

```text
.github/workflows/release.yml
```

Workflow summary:

```yaml
name: Release QuickNotes

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/devops-intro/quicknotes

jobs:
  build-and-push:
    name: Build and push QuickNotes image
    runs-on: ubuntu-24.04

    steps:
      - name: Checkout
        uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@8d2750c68a42422c14e847fe6c8ac0403b4cbd6f

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@c94ce9fb468520275223c153574b00df6fe4bcc9
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Docker metadata
        id: meta
        uses: docker/metadata-action@c299e40c65443455700f0fdfc63efafe5b349051
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=tag
            type=raw,value=latest

      - name: Build and push
        uses: docker/build-push-action@10e90e3645eae34f1e60eeb005ba3a3d33f178e8
        with:
          context: ./app
          file: ./app/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

The workflow triggers on tags matching `v*`, builds the image from `app/`, pushes both the immutable version tag and `latest`, and uses minimum permissions for GHCR publishing.

All third-party GitHub Actions are pinned to full 40-character commit SHAs.

---

## Release tag

Release tag used:

```text
v0.1.0
```

The tag triggered the release workflow and produced the GHCR image.

---

## Registry image

Image URL:

```text
ghcr.io/minimaxc/devops-intro/quicknotes:v0.1.0
```

Latest tag:

```text
ghcr.io/minimaxc/devops-intro/quicknotes:latest
```

---

## Clean pull evidence

Command:

```powershell
docker pull ghcr.io/minimaxc/devops-intro/quicknotes:v0.1.0
```

Output:

```text
v0.1.0: Pulling from minimaxc/devops-intro/quicknotes
3c6cb073fb76: Pull complete
354f125ba48f: Pull complete
60aacc5c1ffc: Pull complete
42612f809805: Download complete
Digest: sha256:90c8cc17273f92b95339c233e043b46b4b6b2a05bf7026f830a7b86b26b8252e
Status: Downloaded newer image for ghcr.io/minimaxc/devops-intro/quicknotes:v0.1.0
ghcr.io/minimaxc/devops-intro/quicknotes:v0.1.0
```

---

## Local run evidence

The pulled image was run locally on port `18080`.

Health endpoint:

```powershell
curl.exe -s http://localhost:18080/health
```

Output:

```json
{"notes":0,"status":"ok"}
```

Notes endpoint:

```powershell
curl.exe -s http://localhost:18080/notes
```

Output:

```json
[]
```

---

## Release workflow run

GitHub Actions release run:

```text
https://github.com/MiniMaxC/DevOps-Intro/actions/runs/28884370843```

Result:

```text
Green / successful
```

---

## Task 1 design questions

### a) OIDC vs `GITHUB_TOKEN`

For pushing to GHCR from the same repository, `GITHUB_TOKEN` with `packages: write` is enough. It is scoped to the repository workflow run and works directly with GitHub Container Registry.

I would use OIDC when deploying to an external cloud provider such as AWS, Azure, or GCP. OIDC lets GitHub Actions exchange a short-lived identity token for temporary cloud credentials. That avoids storing long-lived cloud secrets in GitHub and allows the cloud provider to enforce conditions such as repository, branch, tag, environment, or workflow identity.

### b) Why ship `latest` alongside immutable version tags?

The immutable version tag, such as `v0.1.0`, is used for reproducible deployments and rollback. It always identifies the same image.

The `latest` tag is still useful as a convenience pointer for humans, demos, quick local testing, and environments that intentionally track the newest release. In production, deployment manifests should normally pin the immutable version tag, but `latest` is useful as a moving alias for discovery and quick experiments.

### c) Why `packages: write` only?

This follows the principle of least privilege. The workflow only needs to read repository contents and write packages to GHCR, so it should not receive broader repository write permissions.

A narrow permission scope limits damage if the workflow or one of its third-party actions is compromised. With `write: all`, an attacker could modify repository contents, create releases, alter issues, or abuse unrelated permissions. With `contents: read` and `packages: write`, the blast radius is mainly limited to package publishing.

---

# Task 2 - Hugging Face Spaces Deployment

## Hugging Face Space

Space repository:

```text
https://huggingface.co/spaces/Minimizec/quicknotes
```

Public app URL:

```text
https://minimizec-quicknotes.hf.space
```

The Space uses the Docker SDK and runs the GHCR image built by the release workflow.

---

## Space Dockerfile

File:

```text
cloud/hf-space/Dockerfile
```

Contents:

```dockerfile
FROM ghcr.io/minimaxc/devops-intro/quicknotes:v0.1.0

EXPOSE 8080
```

I chose to pull the GHCR image into the Space instead of rebuilding the app inside the Space. This keeps the deployed artifact identical to the release artifact produced by CI.

---

## Space README

File:

```text
cloud/hf-space/README.md
```

Contents:

```yaml
---
title: QuickNotes
emoji: 📝
sdk: docker
app_port: 8080
pinned: false
---
```

The important settings are `sdk: docker` and `app_port: 8080`.

QuickNotes listens on port `8080`, while Hugging Face Spaces commonly expects apps on its default port unless `app_port` is specified.

---

## Public `/health` evidence

Command:

```powershell
curl.exe -v https://minimizec-quicknotes.hf.space/health
```

Relevant output:

```text
< HTTP/1.1 200 OK
< content-type: application/json
< cache-control: no-store
< content-security-policy: default-src 'none'
< referrer-policy: no-referrer
< x-content-type-options: nosniff
< x-frame-options: DENY
```

Response body:

```json
{"notes":0,"status":"ok"}
```

---

## Public `/notes` evidence

Command:

```powershell
curl.exe -s https://minimizec-quicknotes.hf.space/notes
```

Output:

```json
[]
```

---

## Note on Hugging Face iframe

The Hugging Face embedded Space view showed a browser message saying the app refused to connect. However, the public API endpoints work correctly.

This is caused by the security headers added in Lab 9, especially:

```text
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'
```

These headers prevent the app from being embedded in an iframe. Since QuickNotes is an API and the lab checks `/health` and `/notes`, the API deployment is still valid.

---

## Warm latency

Command:

```powershell
$space = "https://minimizec-quicknotes.hf.space"

1..5 | ForEach-Object {
  curl.exe -o NUL -s -w "%{time_total}`n" "$space/health"
}
```

Samples:

```text
1.141156
0.571920
1.405816
0.934777
1.065606
```

Sorted:

```text
0.571920
0.934777
1.065606
1.141156
1.405816
```

Warm p50:

```text
1.065606 s
```

---

## Cold latency measurements

Command:

```powershell
$space = "https://minimizec-quicknotes.hf.space"

1..3 | ForEach-Object {
  Write-Host ""
  Write-Host "Cold sample ${_}: waiting 35 minutes..."
  Start-Sleep -Seconds 2100

  Write-Host "Cold sample ${_} at $(Get-Date):"
  curl.exe -o NUL -s -w "%{time_total}`n" "$space/health"
}
```

Results:

```text
Cold sample 1 after 35 minutes idle: 0.871886 s
Cold sample 2 after 35 minutes idle: 0.851275 s
Cold sample 3 after 35 minutes idle: 0.810833 s
```

Observation:

The measured cold samples were close to warm latency. In this run, the Space did not show a large visible cold-start delay after the 35-minute idle windows. The measurements are still recorded as required, but no multi-second wake-up penalty was observed.

---

## Task 2 design questions

### d) HF Spaces sleep vs Cloud Run scale to zero

Both systems can stop serving from an active container when idle, but they optimize for different use cases.

Cloud Run is designed as production serverless infrastructure. It has tighter autoscaling behavior, faster request routing, and options such as minimum instances to avoid cold starts. Hugging Face Spaces is optimized for free hosted demos and ML apps, where slower wake-up is acceptable. HF may need to restore the Space runtime, image, or app process before serving the first request.

### e) Why does the Space need `app_port: 8080`?

QuickNotes listens on port `8080`. Hugging Face Docker Spaces need to know which container port to expose publicly. If the Space assumes the wrong default port, the container can be running but the public route will not reach the app.

The `app_port: 8080` setting tells Hugging Face to route public traffic to QuickNotes on port 8080 instead of the platform default.

### f) Pulling the image from GHCR vs building inside the Space

Pulling the GHCR image improves reproducibility because the Space runs the exact image produced by the tagged CI release. It also makes the Space Dockerfile small and makes deployment depend on a single versioned artifact.

Building inside the Space can be easier to debug because the Space build logs show the whole application build process. It can also avoid needing a public container registry. The trade-off is that the Space build may drift from CI, may be slower, and can produce a different artifact from the one tested in the release workflow.

---

# Bonus Task - Cloudflare Tunnel

Bonus was not attempted.

---

# Final result

Task 1 complete:

```text
Tag v0.1.0 triggered release workflow
Image pushed to GHCR
Image publicly pullable
Image runs locally and serves /health and /notes
```

Task 2 complete:

```text
Hugging Face Space deployed
Public URL serves /health and /notes
Warm p50 latency measured
Three 35-minute idle latency samples recorded
```