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