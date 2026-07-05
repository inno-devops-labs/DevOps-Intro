# Lab 10: Cloud Computing

## Task 1: CI-Automated Push to `ghcr.io`

### Release workflow

[`.github/workflows/release.yml`](../.github/workflows/release.yml):

```yaml
name: Release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

jobs:
  release:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4.3.1

      - uses: docker/setup-buildx-action@f7ce87c1d6bead3e36075b2ce75da1f6cc28aaca # v3.9.0

      - uses: docker/login-action@af1e73f918a031802d376d3c8bbc3fe56130a9b0 # v4.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Compute lowercase image name
        run: echo "IMAGE=ghcr.io/$(echo '${{ github.repository }}' | tr '[:upper:]' '[:lower:]')/quicknotes" >> "$GITHUB_ENV"

      - uses: docker/build-push-action@10e90e3645eae34f1e60eeb005ba3a3d33f178e8 # v6.19.2
        with:
          context: app
          push: true
          tags: |
            ${{ env.IMAGE }}:${{ github.ref_name }}
            ${{ env.IMAGE }}:latest
```

### Registry

Image: `ghcr.io/ten-do/devops-intro/quicknotes`, tags `v0.1.0` and `latest`, package visibility flipped to **public** in GitHub package settings.

Clean pull (no auth) after `docker rmi`:

```
$ docker pull ghcr.io/ten-do/devops-intro/quicknotes:v0.1.0
v0.1.0: Pulling from ten-do/devops-intro/quicknotes
Digest: sha256:d39c31e8cb3fc7a57cb78c8282099758be84ab2e122b1e24b269f4642d519862
Status: Downloaded newer image for ghcr.io/ten-do/devops-intro/quicknotes:v0.1.0
```

Ran it: `curl http://localhost:8080/health` -> `{"notes":4,"status":"ok"}`.

### CI run

Green release run: https://github.com/Ten-Do/DevOps-Intro/actions/runs/28742692544/job/85228164793?pr=9

### Design questions

**a) OIDC vs `GITHUB_TOKEN`**

`GITHUB_TOKEN` is scoped to the repo it runs in and expires with the job - enough here because we're pushing to `ghcr.io` from the same repo that owns the package. OIDC is worth it when the credential has to leave GitHub's own trust boundary: pushing to a _third-party_ registry or cloud (AWS ECR, GCP Artifactory, Docker Hub under another org) without storing a long-lived static secret. OIDC lets the external provider verify a short-lived token issued by GitHub for _this specific workflow run_, so there's no standing credential to leak or rotate.

**b) `:latest` alongside an immutable tag**

`:latest` is mutable and shouldn't be trusted for reproducible deploys, but consumers who just want "whatever is current" (a quick local pull, a demo, a dashboard link) still need a name that doesn't change every release. Shipping both lets automation/production pin to `:v0.1.0` for reproducibility while `:latest` stays a convenience pointer for humans and non-critical tooling.

**c) `packages: write` scope only**

Principle of least privilege: the job grants itself exactly the permissions it uses and nothing else (default `GITHUB_TOKEN` permissions are all read-only unless declared, and `contents: read` is enough since we only check out code). With `write: all` a compromised action/dependency in the build step could push commits, delete branches, edit issues/PRs, or modify repo settings. Scoping to `packages: write` (plus `contents: read`) means the worst a compromised step can do is publish a bad package - it can't touch the rest of the repo.

## Task 2: Deploy to Hugging Face Spaces

### Space

URL: https://yurarrrr-innodevops.hf.space (Space repo: https://huggingface.co/spaces/YuraRrrr/innodevops)

`curl -v` against `/health`:

```
> GET /health HTTP/2
> Host: yurarrrr-innodevops.hf.space
<
< HTTP/2 200
< content-type: application/json
< x-proxied-host: http://10.112.137.232
<
{"notes":4,"status":"ok"}
```

### Space files

`Dockerfile` (pulls the image already built and pushed in Task 1 - reuses the tested artifact instead of rebuilding from source; see design question f):

```dockerfile
FROM ghcr.io/ten-do/devops-intro/quicknotes:v0.1.0
```

`README.md` frontmatter:

```yaml
---
title: Innodevops
emoji: ⚡
colorFrom: indigo
colorTo: yellow
sdk: docker
app_port: 8080
pinned: false
license: mit
short_description: "space for innopolis devops labs "
---
```

Copies of both are in [`cloud/space/`](../cloud/space/).

### Warm latency

5 consecutive requests to `/health`:

| #   | time_total |
| --- | ---------: |
| 1   |     0.558s |
| 2   |     0.441s |
| 3   |     0.439s |
| 4   |     0.397s |
| 5   |     0.398s |

**p50: 0.439s**

### Cold latency

Single request after 35+ min idle, repeated 3 times (sleep -> wake -> sleep):

| #   | time_total |
| --- | ---------: |
| 1   |      5.72s |
| 2   |      0.60s |
| 3   |      6.20s |

Cold-start latency is inconsistent between runs - HF's proxy appears to answer some wake requests before the container is fully ready, with the actual delay sometimes showing up as a slow _second_ request rather than the first.

### Design questions

**d) HF "sleep" vs Cloud Run "scale to zero"**

Both kill the container on idle and start a fresh one on the next request, but HF's free tier optimizes for cost and simplicity across a huge number of hobby Spaces, not latency - waking often means re-provisioning a container slot and re-pulling the image with no guaranteed warm pool. Cloud Run is a paid, SLA-backed product: Google keeps lightweight sandboxes (gVisor) and cached image layers ready so cold starts land in the sub-second-to-low-seconds range. HF's wake is an order of magnitude slower because nothing is reserved to make it fast - it's a free-tier tradeoff, not a technical ceiling.

**e) Why `app_port: 8080`**

HF's default is `7860`, historically Gradio's default dev-server port (most Spaces are Gradio/Streamlit demos). HF's front proxy forwards external traffic to whatever port the frontend declares, so any app not listening on 7860, like QuickNotes on 8080, has to declare `app_port` or the proxy connects to a port nothing is listening on and the Space looks "down" even though the container is healthy.

**f) ghcr.io pull vs building the Dockerfile inside the Space**

Pulling the pre-built `v0.1.0` image means the Space runs the _exact_ artifact that Task 1's CI already built, tested, and made pullable - no chance of the Space's build drifting from the ghcr.io copy, and HF's build step is a fast, single-layer `FROM` pull instead of a full Go compile. The cost: the Space depends on ghcr.io being reachable at deploy time, and if something's wrong with the running container, HF's build logs won't show a compile - only the pull and boot, so debugging an app-level bug means going back to a local `docker run` or the CI logs, not the Space's build tab.
