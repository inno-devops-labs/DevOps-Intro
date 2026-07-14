# Lab 10 — Cloud Computing

## Task 1 — CI-Automated Push to ghcr.io

### Release workflow

`.github/workflows/release.yml`:

\`\`\`yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: read
  packages: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

      - name: Extract version from tag
        id: version
        run: echo "VERSION=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      - name: Compute lowercase repo name
        id: repo
        run: echo "REPO=${GITHUB_REPOSITORY,,}" >> "$GITHUB_OUTPUT"

      - name: Log in to ghcr.io
        uses: docker/login-action@74a5d142397b4f367a81961eba4e8cd7edddf772 # v3.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@f7ce87c1d6bead3e36075b2ce75da1f6cc28aaca # v3.9.0

      - name: Build and push
        uses: docker/build-push-action@471d1dc4e07e5cdedd4c2171150001c434f0b7a4 # v6.15.0
        with:
          context: ./app
          push: true
          tags: |
            ghcr.io/${{ steps.repo.outputs.REPO }}/quicknotes:${{ steps.version.outputs.VERSION }}
            ghcr.io/${{ steps.repo.outputs.REPO }}/quicknotes:latest
\`\`\`

### Registry

Image: `ghcr.io/darknesod1-netizen/devops-outro/quicknotes`
Tags: `0.1.0`, `latest`

(Note: image tag is `0.1.0` not `v0.1.0` — the workflow strips the `v` prefix from the git tag `v0.1.0` via `VERSION=${GITHUB_REF_NAME#v}`.)

### Green CI run

https://github.com/darknesod1-netizen/DevOps-Outro/actions/runs/29342678187

### Clean pull evidence

\`\`\` Bash
$ docker pull ghcr.io/darknesod1-netizen/devops-outro/quicknotes:0.1.0
0.1.0: Pulling from darknesod1-netizen/devops-outro/quicknotes
51086c5c38e2: Pull complete
c172f21841df: Pull complete
dd64bf2dd177: Pull complete
7c12895b777b: Pull complete
ebddc55facdc: Pull complete
52630fc75a18: Pull complete
99515e7b4d35: Pull complete
1eed391ea893: Pull complete
b839dfae01f6: Pull complete
d6b1b89eccac: Pull complete
3214acf345c0: Pull complete
99ba982a9142: Pull complete
2780920e5dbf: Pull complete
bdfd7f7e5bf6: Pull complete
046a90b49100: Download complete
Digest: sha256:efe993b962881a8b5fd1bb8867b0f04262235c4c25229021d5a4bf1c49706bb8
Status: Downloaded newer image for ghcr.io/darknesod1-netizen/devops-outro/quicknotes:0.1.0
ghcr.io/darknesod1-netizen/devops-outro/quicknotes:0.1.0
\`\`\`

### Design questions

**a) OIDC vs GITHUB_TOKEN**
GITHUB_TOKEN is scoped to the repo the workflow runs in and expires with the job — sufficient for same-repo pushes to ghcr.io. OIDC is the right choice when authenticating to a third-party cloud (AWS, GCP, Azure) without storing a long-lived secret — the external provider trusts GitHub's identity token and mints short-lived credentials dynamically.

**b) :latest vs :v0.1.0**
`:latest` is a convenience alias for consumers who don't want to track exact versions (dev/staging pulls, quick manual tests). Production deployments should still pin the immutable tag — `:latest` is not a deployment target, just a pointer to the newest release.

**c) packages: write scope only**
Least privilege: the job can push/pull packages but can't touch repo contents, issues, PRs, or org settings. If a build step were compromised, `write: all` would let an attacker rewrite repo history or exfiltrate secrets from unrelated scopes; `packages: write` limits the blast radius to the registry.

## Task 2 - Hugging Face Spaces
Task 2 was not attempted: HF changed the Docker SDK to a paid-only feature now.