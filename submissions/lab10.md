# Lab 10

## Task 1 — CI-Automated Push to `ghcr.io` (6 pts)

## Release workflow

Workflow file: `.github/workflows/release.yml`

```yaml
name: release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: read
  packages: write

jobs:
  publish:
    name: publish ghcr image
    runs-on: ubuntu-24.04
    steps:
      - name: Check out code
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

      - name: Derive image coordinates
        id: image
        run: |
          owner="${GITHUB_REPOSITORY_OWNER,,}"
          repo="${GITHUB_REPOSITORY#*/}"
          repo="${repo,,}"
          echo "image=ghcr.io/${owner}/${repo}/quicknotes" >> "$GITHUB_OUTPUT"
          echo "version=${GITHUB_REF_NAME}" >> "$GITHUB_OUTPUT"

      - name: Set up QEMU
        uses: docker/setup-qemu-action@29109295f81e9208d7d86ff1c6c12d2833863392  # v3.6.0

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@e468171a9de216ec08956ac3ada2f0791b6bd435  # v3.11.1

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@74a5d142397b4f367a81961eba4e8cd7edddf772  # v3.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push QuickNotes image
        uses: docker/build-push-action@263435318d21b8e681c14492fe198d362a7d2c83  # v6.18.0
        with:
          context: ./app
          file: ./app/Dockerfile
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ${{ steps.image.outputs.image }}:${{ steps.image.outputs.version }}
            ${{ steps.image.outputs.image }}:latest
```

## Registry target

The workflow publishes to:

```text
ghcr.io/smairon/devops-intro/quicknotes
```

Published release tags:

```text
ghcr.io/smairon/devops-intro/quicknotes:v0.1.1
ghcr.io/smairon/devops-intro/quicknotes:latest
```

## Verification status

Verified:

- New release workflow added at `.github/workflows/release.yml`
- Trigger configured for tag pushes matching `v*`
- Permissions narrowed to `contents: read` and `packages: write`
- All third-party actions pinned by full 40-character SHA
- Image path normalized to lowercase for ghcr compatibility
- Release tags pushed to origin:

```text
v0.1.0
v0.1.1
```

- Published multi-arch manifest for `v0.1.1`:

```text
Platform: linux/amd64
Platform: linux/arm64
```

- Successful clean pull of the released image on this machine:

```text
docker pull ghcr.io/smairon/devops-intro/quicknotes:v0.1.1
Exit Code: 0
```

- A green GitHub Actions release run URL: https://github.com/smairon/DevOps-Intro/actions/runs/28964479031

Manifest inspection evidence:

```text
Name: ghcr.io/smairon/devops-intro/quicknotes:v0.1.1
Platform: linux/amd64
Platform: linux/arm64
```

The original `v0.1.0` release was `amd64` only. I fixed the workflow to publish both `amd64` and `arm64`, then released `v0.1.1` so Apple Silicon machines can pull the image natively.

Clean-pull verification commands:

```bash
docker rmi ghcr.io/smairon/devops-intro/quicknotes:v0.1.1 || true
docker rmi ghcr.io/smairon/devops-intro/quicknotes:latest || true
docker pull ghcr.io/smairon/devops-intro/quicknotes:v0.1.1
docker pull ghcr.io/smairon/devops-intro/quicknotes:latest
```

## Design questions

### a) **OIDC vs `GITHUB_TOKEN`** — for pushing to ghcr.io from the same repo, `GITHUB_TOKEN` with `packages: write` is enough. When would you reach for OIDC instead, and what does it give you that `GITHUB_TOKEN` doesn't?

For pushing to `ghcr.io` from the same repository, `GITHUB_TOKEN` is enough because GitHub already trusts that workflow identity and can issue a token with `packages: write`.

I would reach for OIDC when the workflow needs to authenticate to an external cloud provider such as AWS, GCP, or Azure, or when I want the target platform to make a fine-grained trust decision based on repository, branch, tag, or workflow identity. OIDC gives short-lived federated credentials and removes the need to store long-lived cloud secrets in GitHub.

### b) **`:latest` tag vs `:v0.1.0` immutable tag** — Lab 6 covered why `:latest` is mutable. So why do you still ship a `:latest` tag alongside the immutable one in production releases?

The immutable tag such as `:v0.1.1` is the source of truth for reproducibility, rollback, and audit. It tells me exactly what image I deployed.

I still ship `:latest` because it is convenient for humans, demos, and simple deploy targets that intentionally track the newest stable release. It is a moving pointer for convenience, while the version tag remains the stable reference that production automation should prefer.

### c) **`packages: write` scope only** — what's the principle, and what concrete attack does the *narrow* scope prevent vs `write: all`?

This is least privilege. The workflow only needs to read repository contents and write a package to GitHub Container Registry, so it should not get broader repository write access.

The narrow scope prevents a compromised action from doing unrelated damage such as pushing commits, changing repository contents, creating releases, or modifying other GitHub resources that a broad write token could reach. With `packages: write`, the blast radius stays much smaller.

## Task 2 — Deploy to Hugging Face Spaces (attempted)

## Target Space

- Space repository: `https://huggingface.co/spaces/Axxilius/quicknotes`
- Expected public URL: `https://axxilius-quicknotes.hf.space`

## Space files prepared for deployment

Dockerfile prepared for the Space:

```dockerfile
FROM ghcr.io/smairon/devops-intro/quicknotes:v0.1.1

HEALTHCHECK --interval=30s --timeout=3s CMD ["/quicknotes", "healthcheck"]
```

`README.md` prepared for the Space:

```yaml
---
title: QuickNotes
emoji: "📝"
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
fullWidth: true
header: mini
short_description: QuickNotes API deployed from the published GHCR release image.
---

# QuickNotes

This Space runs the published QuickNotes container image from GitHub Container Registry:

`ghcr.io/smairon/devops-intro/quicknotes:v0.1.1`

Expected public endpoints:

- `/health`
- `/notes`

Source repository:

- `https://github.com/smairon/DevOps-Intro`

Space repository:

- `https://huggingface.co/spaces/Axxilius/quicknotes`
```

These same files are stored in this repository under `cloud/hf-space/`.

## Deployment attempt and evidence

What I completed:

- Verified that the Hugging Face Space repository already exists.
- Cloned the Space repository locally.
- Confirmed the remote Space was still on the default Hugging Face starter template instead of a Docker Space.
- Replaced the local clone contents with the Docker Space configuration above.
- Created a local deployment commit in the Space clone:

```text
3e05f20c27c3f2808ba1dabc7d2c84159514b521
```

What failed:

- `git push` to the Hugging Face Space did not succeed from the local environment.
- Because the push failed, the deployment commit never reached the remote Space repository.
- The remote Space branch remained unchanged at:

```text
98feed9e91d13122ab46036449aa091a1b4077fb        refs/heads/main
```

Public health probe after the failed push:

```text
> GET /health HTTP/2
< HTTP/2 503
< content-type: text/html; charset=utf-8
< link: <https://huggingface.co/spaces/Axxilius/quicknotes>;rel="canonical"
```

Current conclusion:

- The Space exists, but the Docker deployment was not published.
- As a result, QuickNotes is not yet serving at the public HF URL.
- Since `/health` already returns `503`, `/notes` is also not testable in a meaningful way.

## Measurements

Warm-latency and cold-start measurements could not be collected because the Space never became healthy after the failed push.

## Design questions

### d) **HF Spaces sleep vs Cloud Run scale-to-zero**

They are the same broad idea, but they optimize for different things. Hugging Face Spaces on the free tier optimize for low-cost shared hosting of many community apps, not for aggressive low-latency autoscaling. Waking a Space can involve scheduling shared capacity, pulling or restoring a container image, starting the container, and waiting for the app to become healthy.

Cloud Run is designed much more like a production request-serving platform. It is optimized around fast instance startup, tighter integration with Google’s serving stack, and much stronger latency expectations. In short, HF optimizes for accessibility and free hosting; Cloud Run optimizes far more for operational responsiveness.

### e) **Why does the Space need `app_port: 8080`?**

QuickNotes listens on port `8080`, so the Space must tell Hugging Face which internal container port should be exposed publicly. If I omit that setting, Hugging Face assumes the Docker app is serving on port `7860`.

That default exists because many Spaces historically run Gradio demos, and `7860` is the conventional port for that ecosystem. QuickNotes is a plain Go HTTP API, so I need to override the default and explicitly set `app_port: 8080`.

### f) **Pulling from `ghcr.io` vs building inside the Space**

Pulling `ghcr.io/smairon/devops-intro/quicknotes:v0.1.1` makes the Space run the exact immutable artifact that was built and published in Task 1. That is better for reproducibility, rollback, and debugging because the deployed image matches the released image byte-for-byte.

Building from source inside the Space would make the Space repository more self-contained, but it shifts more build logic into Hugging Face, makes deploys slower, and can make debugging harder because the Space build environment becomes another moving part. The trade-off is convenience and self-containment versus reproducibility and tighter release discipline. For this lab, pulling the released image is the cleaner choice.

## Task 2 status

Task 2 was attempted seriously and prepared correctly at the file level, but it is incomplete because the Hugging Face Space deployment commit could not be pushed to the remote repository. The missing successful push prevented the Space rebuild, public API verification, and latency measurements.