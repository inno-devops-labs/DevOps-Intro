# Lab 10 - Cloud Computing: Ship QuickNotes to a Real Cloud

## Objective

Publish the QuickNotes container image to GitHub Container Registry from a tag-triggered GitHub Actions release workflow, prepare a Hugging Face Docker Space deployment that runs the immutable release image, and compare the hosted model with a Cloudflare quick tunnel.

## Environment

| Component | Version / value |
|-----------|-----------------|
| Branch | `feature/lab10` |
| Release tag | `v0.1.0` |
| Registry image | `ghcr.io/hidancloud/devops-intro/quicknotes` |
| Local Docker | Docker 29.1.5 |
| Local Go | go1.26.4 darwin/arm64 |
| Cloudflare tunnel | cloudflared 2026.6.1 |
| Benchmark tool | hyperfine 1.20.0 |

## Evidence Status

The repository-side implementation is complete: the release workflow, Hugging Face Space artifacts, Cloudflare tunnel notes, measurement helper, and this submission are included in the branch.

Repository, registry, and hosted deployment evidence already collected:

1. GitHub Actions release run succeeded: `https://github.com/Hidancloud/DevOps-Intro/actions/runs/28892339659`.
2. GHCR package is public and anonymously pullable.
3. The published `v0.1.0` image was pulled and smoke-tested locally from GHCR.
4. Hugging Face Space is live: `https://hiidancloud-inno-devops-quicknotes.hf.space`.

Manual evidence still useful before final submission:

1. Three HF cold-start samples after 35+ minutes idle between each sample.
2. Optional screenshots: green release workflow, public package, HF Space logs, and phone/cellular Cloudflare verification.

No secrets, private keys, tokens, or production data are stored in this repository.

---

## Task 1 - CI-Automated Push to GHCR

### Implementation

Workflow file: `.github/workflows/release.yml`

```yaml
name: Release image

on:
  push:
    tags:
      - "v*"

concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: false

permissions:
  contents: read
  packages: write

jobs:
  publish:
    name: Build and push QuickNotes image
    runs-on: ubuntu-24.04
    timeout-minutes: 20

    steps:
      - name: Checkout repository
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2, resolved 2026-07-07

      - name: Compute image tags
        id: meta
        shell: bash
        run: |
          set -euo pipefail
          image="ghcr.io/${GITHUB_REPOSITORY}/quicknotes"
          image="$(printf '%s' "$image" | tr '[:upper:]' '[:lower:]')"
          version="${GITHUB_REF_NAME}"

          {
            echo "image=${image}"
            echo "version=${version}"
            echo "version_tag=${image}:${version}"
            echo "latest_tag=${image}:latest"
          } >> "$GITHUB_OUTPUT"

          printf 'Publishing %s and %s\n' "${image}:${version}" "${image}:latest"

      - name: Login to GitHub Container Registry
        shell: bash
        env:
          GHCR_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -euo pipefail
          printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin

      - name: Build and push image
        shell: bash
        run: |
          set -euo pipefail
          docker buildx create --use --name quicknotes-release-builder || docker buildx use quicknotes-release-builder
          docker buildx inspect --bootstrap
          docker buildx build \
            --platform linux/amd64 \
            --tag "${{ steps.meta.outputs.version_tag }}" \
            --tag "${{ steps.meta.outputs.latest_tag }}" \
            --push \
            ./app

      - name: Print published image digest
        shell: bash
        run: |
          set -euo pipefail
          docker buildx imagetools inspect "${{ steps.meta.outputs.version_tag }}"
```

The workflow uses a tag trigger, builds from `./app`, publishes both immutable and mutable tags, and grants only `contents: read` plus `packages: write`. The only third-party action is `actions/checkout`, pinned to a full 40-character commit SHA.

### Local validation output

Go tests:

```text
$ cd app && go test ./...
ok  	quicknotes	0.802s
?   	quicknotes/cmd/healthcheck	[no test files]
```

YAML parsing:

```text
$ ruby -e 'require "yaml"; YAML.load_file(".github/workflows/release.yml"); YAML.load_file("cloud/huggingface-space/README.md"); puts "YAML parsed"'
YAML parsed
```

GitHub Actions workflow lint:

```text
$ actionlint .github/workflows/release.yml
(no output, exit 0)
```

Local image build and smoke test:

```text
$ docker build -t quicknotes:lab10 ./app
#21 naming to docker.io/library/quicknotes:lab10 done
#21 DONE 0.0s

$ docker run -d --name quicknotes-lab10-smoke -p 8080:8080 quicknotes:lab10
7b5f344962163156a4d9df3839e6c74db7fd7895b5c43c69beaad49d8d96c71c

$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

Local latency helper sanity check:

```text
$ ./cloud/scripts/measure-curl-latency.sh http://localhost:8080/health 5
0.002701
0.002259
0.002234
0.002092
0.002058
runs=5
p50=0.002234s
p95=0.002701s
```

### Release commands

The intended release commands are:

```bash
git tag -a -s v0.1.0 -m "Lab 10 release"
git push origin feature/lab10
git push origin v0.1.0
```

Local signed release evidence:

```text
$ git log --show-signature -1 --format=fuller
commit 9c9bd0b102caee06c05da898953597650ae2a29f
Good "git" signature for hidancloud@yandex.ru with ED25519 key SHA256:0suWfmEHZ/Xt+yrRNKc2HZQbjzw33ZGHOnxmXKllv54
Author:     Arseny Pinigin <hidancloud@yandex.ru>
AuthorDate: Tue Jul 7 14:12:45 2026 +0300
Commit:     Arseny Pinigin <hidancloud@yandex.ru>
CommitDate: Tue Jul 7 14:12:45 2026 +0300

    feat(lab10): add cloud release workflow

    Signed-off-by: Arseny Pinigin <hidancloud@yandex.ru>

$ git tag -v v0.1.0
Good "git" signature for hidancloud@yandex.ru with ED25519 key SHA256:0suWfmEHZ/Xt+yrRNKc2HZQbjzw33ZGHOnxmXKllv54
object 9c9bd0b102caee06c05da898953597650ae2a29f
type commit
tag v0.1.0
tagger Arseny Pinigin <hidancloud@yandex.ru> 1783422772 +0300

Lab 10 release
```

After the workflow succeeds, verify the image from an unauthenticated Docker session:

```bash
docker logout ghcr.io || true
docker pull ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
docker run --rm -p 8080:8080 ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
curl -s http://localhost:8080/health
```

### Registry URL

```text
ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
ghcr.io/hidancloud/devops-intro/quicknotes:latest
```

### Green release run

```text
https://github.com/Hidancloud/DevOps-Intro/actions/runs/28892339659
```

GitHub API confirmation:

```text
$ curl -s 'https://api.github.com/repos/Hidancloud/DevOps-Intro/actions/workflows/release.yml/runs?per_page=3' | jq -r '.workflow_runs[] | [.id, .status, .conclusion, .html_url, .head_branch, .head_sha, .display_title, .run_started_at] | @tsv'
28892339659  completed  success  https://github.com/Hidancloud/DevOps-Intro/actions/runs/28892339659  v0.1.0  9c9bd0b102caee06c05da898953597650ae2a29f  Release image  2026-07-07T19:19:23Z
```

The GitHub UI also shows `Release image #1` as successful with a total duration of 50 seconds. The only annotation is a non-failing GitHub runner warning that Node.js 20 actions are being forced to run on Node.js 24.

### Public pull evidence

This was tested after logging out from `ghcr.io`. Because this host is Apple Silicon and the release workflow intentionally published `linux/amd64` for GitHub/Hugging Face compatibility, the local verification uses `--platform linux/amd64`. On a normal `linux/amd64` clean machine, the same pull works without the platform override.

```text
$ docker logout ghcr.io || true
$ docker pull --platform linux/amd64 ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
v0.1.0: Pulling from hidancloud/devops-intro/quicknotes
Digest: sha256:889abfe27fdffdfbe0fd8a513c5ea1eb33e305ead4e3371908139264f6105b88
Status: Downloaded newer image for ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0

$ docker image inspect ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0 --format 'ID={{.Id}} Size={{.Size}} Architecture={{.Architecture}} OS={{.Os}}'
ID=sha256:889abfe27fdffdfbe0fd8a513c5ea1eb33e305ead4e3371908139264f6105b88 Size=5704983 Architecture=amd64 OS=linux

$ docker run --platform linux/amd64 -d --name quicknotes-ghcr-smoke -p 18080:8080 ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
acfce2c4ef2bf85106a14dd6a811e37e00f51c0e4c88c3342d09dbb547e22d2f

$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### Design questions

**a) OIDC vs `GITHUB_TOKEN`.**

For pushing to GHCR from the same GitHub repository, `GITHUB_TOKEN` with `packages: write` is enough because GitHub can authorize the workflow directly against the repository package namespace. I would reach for OIDC when GitHub Actions must access an external cloud provider such as AWS, GCP, Azure, or Vault without storing long-lived cloud credentials as repository secrets. OIDC gives a short-lived, audience-bound identity token to the job, and the cloud provider exchanges it for temporary permissions based on claims such as repository, branch, environment, or workflow. That reduces secret sprawl and makes credential theft less useful because there is no static token to reuse later.

**b) `latest` tag vs immutable version tag.**

The immutable `:v0.1.0` tag is the release artifact used for reproducibility, rollback, audit, and deployments that must not drift. The `:latest` tag is still useful as a convenience pointer for humans, demos, smoke tests, and environments that intentionally follow the newest stable release. In production I would deploy the immutable tag and publish `latest` as a discoverability pointer, not as the source of truth for controlled rollouts.

**c) Why only `packages: write`.**

This is least privilege: the workflow token should have only the permission needed to publish the image. Compared with broad `write-all` permissions, this prevents a compromised build step from pushing commits, modifying issues, changing pull requests, creating releases, or writing unrelated repository state. If a malicious Docker build dependency or action step executes arbitrary code, the narrow token limits the blast radius to package publishing instead of handing it the whole repository.

---

## Task 2 - Hugging Face Spaces Deployment

### Space artifact layout

The repository contains the files to copy or push into the Hugging Face Space Git repository:

```text
cloud/huggingface-space/
├── Dockerfile
└── README.md
```

### Space Dockerfile

```dockerfile
# This Space intentionally runs the exact release artifact from GHCR instead of
# rebuilding QuickNotes. The deployment consumes the same immutable image that
# CI published for Lab 10, which keeps release and production behavior aligned.
FROM ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
```

### Space README with YAML frontmatter

````markdown
---
title: QuickNotes Lab 10
emoji: "📝"
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
pinned: false
short_description: QuickNotes API deployed from the Lab 10 GHCR release image.
---

# QuickNotes Lab 10

This Hugging Face Space runs the immutable Lab 10 QuickNotes release image:

```text
ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
```

The Space uses the Docker SDK and sets `app_port: 8080` because QuickNotes
listens on port 8080. The public API endpoints are:

```text
/health
/notes
/metrics
```
````

### Deployment evidence

Hugging Face Space repository:

```text
https://huggingface.co/spaces/HiidanCloud/inno-devops-quicknotes
```

Public Space URL:

```text
https://hiidancloud-inno-devops-quicknotes.hf.space
```

Space repo commit:

```text
$ git -C /tmp/inno-devops-quicknotes-hf log --oneline --decorate -2
f4f172d (HEAD -> main, origin/main, origin/HEAD) Deploy QuickNotes release image
d7e74f8 initial commit
```

The contents of `cloud/huggingface-space/` were pushed to the Space repository:

```bash
git clone https://huggingface.co/spaces/HiidanCloud/inno-devops-quicknotes /tmp/inno-devops-quicknotes-hf
cp cloud/huggingface-space/Dockerfile cloud/huggingface-space/README.md /tmp/inno-devops-quicknotes-hf/
cd /tmp/inno-devops-quicknotes-hf
git add Dockerfile README.md
git commit -m "Deploy QuickNotes release image"
git push
```

### Public health check

```text
$ curl -v https://hiidancloud-inno-devops-quicknotes.hf.space/health
* Host hiidancloud-inno-devops-quicknotes.hf.space:443 was resolved.
* Connected to hiidancloud-inno-devops-quicknotes.hf.space (35.175.32.85) port 443
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* Server certificate:
*  subject: CN=hf.space
*  subjectAltName: host "hiidancloud-inno-devops-quicknotes.hf.space" matched cert's "*.hf.space"
* using HTTP/2
> GET /health HTTP/2
> Host: hiidancloud-inno-devops-quicknotes.hf.space
< HTTP/2 200
< content-type: application/json
< x-proxied-replica: lo00sud0-z7xbb
< link: <https://huggingface.co/spaces/HiidanCloud/inno-devops-quicknotes>;rel="canonical"
{"notes":4,"status":"ok"}
```

The `/notes` endpoint also returns the seeded QuickNotes data:

```text
[{
  "id":4,
  "title":"Endpoint cheat-sheet",
  "body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
  "created_at":"2026-01-15T10:15:00Z"
}, ...]
```

### Warm latency

Five consecutive warm requests:

```text
$ for i in 1 2 3 4 5; do curl -w '%{time_total}\n' -o /dev/null -s https://hiidancloud-inno-devops-quicknotes.hf.space/health; done
0.868571
0.813725
0.754585
0.797764
0.802027
```

Warm p50 from the required five-request sample: `0.802027s`.

Additional 50-run sample for p50/p95 comparison:

```text
$ ./cloud/scripts/measure-curl-latency.sh https://hiidancloud-inno-devops-quicknotes.hf.space/health 50
runs=50
p50=0.801118s
p95=0.989296s
```

### Cold latency plan

HF cold-start sampling still requires waiting for the free Space to sleep between samples. The exact command to run after each 35+ minute idle period is:

```bash
curl -w '%{time_total}\n' -o /dev/null -s https://hiidancloud-inno-devops-quicknotes.hf.space/health
```

Cold samples table:

| Sample | Idle time before request | `time_total` |
|--------|--------------------------|-------------:|
| 1 | Pending 35+ min idle | Pending |
| 2 | Pending 35+ min idle | Pending |
| 3 | Pending 35+ min idle | Pending |

### Design questions

**d) HF Spaces sleep vs Cloud Run scale to zero.**

Both platforms remove idle compute and wake it on demand, but they optimize for different products. Cloud Run is a production serverless container platform, so it invests heavily in fast scheduling, request routing, image caching, concurrency controls, and predictable cold starts. Hugging Face Spaces is optimized for free public demos and ML apps; a sleeping Space may need to rehydrate a container, restore the runtime environment, and sometimes pull larger images or model assets. That makes HF wake-ups slower, but it keeps the free tier practical for many public demos.

**e) Why `app_port: 8080`.**

Hugging Face Docker Spaces default to port `7860`, which matches common Gradio and demo-app conventions in the Hugging Face ecosystem. QuickNotes listens on port `8080` and the lab explicitly says not to change the application. The `app_port: 8080` frontmatter tells the Spaces router which internal container port should receive public traffic.

**f) Pulling from GHCR vs building inside the Space.**

Pulling the GHCR image deploys the exact release artifact produced by CI. That is better for reproducibility and rollback because the Space runs `v0.1.0`, not whatever source happens to build later. It can also make Space builds smaller and faster because the Space Dockerfile is only a `FROM` line. The trade-off is that debugging may require looking at GitHub Actions and GHCR instead of only HF logs, and the Space depends on GHCR availability and package visibility. Building inside the Space is more self-contained and easier to inspect in HF logs, but it duplicates CI build logic and risks drift between release and deployment.

---

## Bonus Task - Cloudflare Tunnel and Cross-Platform Comparison

### Tool installation

```text
$ brew install cloudflared hyperfine
==> Pouring cloudflared--2026.6.1.arm64_tahoe.bottle.tar.gz
==> Summary
/opt/homebrew/Cellar/cloudflared/2026.6.1: 10 files, 38.3MB
==> Pouring hyperfine--1.20.0.arm64_tahoe.bottle.tar.gz
/opt/homebrew/Cellar/hyperfine/1.20.0: 14 files, 1.2MB

$ cloudflared --version
cloudflared version 2026.6.1 (built 2026-06-18T13:39:02Z)

$ hyperfine --version
hyperfine 1.20.0
```

### Local QuickNotes container

```text
$ docker run -d --name quicknotes-lab10 -p 8080:8080 quicknotes:lab10
4905d16c28b6a19af5b222e22b9800e330e54bf0926fe11c5d0987801843de28

$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### Quick tunnel

```text
$ cloudflared tunnel --url http://localhost:8080 --no-autoupdate
2026-07-07T11:08:10Z INF Your quick Tunnel has been created! Visit it at:
https://supplied-rational-varieties-margin.trycloudflare.com
2026-07-07T11:08:10Z INF Version 2026.6.1
2026-07-07T11:08:10Z INF Initial protocol quic
```

This is an ephemeral quick-tunnel URL. It is valid only while the local `cloudflared` process keeps running.

### Public `/health` verification from this machine

```text
$ curl -v https://supplied-rational-varieties-margin.trycloudflare.com/health
* Host supplied-rational-varieties-margin.trycloudflare.com:443 was resolved.
* Connected to supplied-rational-varieties-margin.trycloudflare.com (104.16.231.132) port 443
* SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256
* Server certificate:
*  subject: CN=trycloudflare.com
*  subjectAltName: host "supplied-rational-varieties-margin.trycloudflare.com" matched cert's "*.trycloudflare.com"
* using HTTP/2
> GET /health HTTP/2
> Host: supplied-rational-varieties-margin.trycloudflare.com
< HTTP/2 200
< content-type: application/json
< cf-ray: a1766404b8ba187a-MIA
< server: cloudflare
{"notes":4,"status":"ok"}
```

The lab asks to verify from a different machine or a phone on cellular. I could not perform the cellular check from this terminal, so that manual screenshot should be collected before final submission.

### Warm latency measurement

```text
$ hyperfine --warmup 3 --runs 50 "curl -o /dev/null -s https://supplied-rational-varieties-margin.trycloudflare.com/health"
Benchmark 1: curl -o /dev/null -s https://supplied-rational-varieties-margin.trycloudflare.com/health
  Time (mean +/- sigma):     737.3 ms +/-  58.9 ms    [User: 15.6 ms, System: 8.0 ms]
  Range (min ... max):       667.0 ms ... 931.3 ms    50 runs
```

Explicit p50/p95 using the repository helper:

```text
$ ./cloud/scripts/measure-curl-latency.sh https://supplied-rational-varieties-margin.trycloudflare.com/health 50
runs=50
p50=0.694076s
p95=0.846806s
```

### Comparison table

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | 0.801118 s | 0.694076 s |
| Warm p95 | 0.989296 s | 0.846806 s |
| Cold start | Pending 3 cold samples after Space sleep | N/A, continuously local while tunnel runs |
| Public URL stability | Stable for the Space name | Ephemeral on tunnel restart |
| Cost | Free | Free |

### Design questions

**g) Architectural difference.**

In Hugging Face Spaces, the QuickNotes container runs in Hugging Face infrastructure and users connect to a platform-hosted service. In Cloudflare Tunnel, the container runs on my laptop and Cloudflare proxies public traffic from its edge back to the local machine over the tunnel. Both are useful cloud delivery models, but they solve different problems. For users, the distinction matters mainly through availability, latency, and operational responsibility: a hosted container survives my laptop sleeping; a quick tunnel does not.

**h) Latency dominator.**

For HF Spaces warm requests, the slow part is usually internet routing to HF plus the platform router and the container runtime path. If the Space has slept, cold start dominates by far. For Cloudflare Tunnel, the slow part is the round trip from user to Cloudflare edge, then from Cloudflare edge through the tunnel to my laptop and back. The QuickNotes handler itself is tiny; network path and tunnel forwarding dominate the measured latency.

**i) When Cloudflare Tunnel is the right production pick.**

Cloudflare Tunnel is a good production choice for controlled exposure of home lab services, on-prem internal tools, admin dashboards, webhook receivers, or private apps where the service must remain on an internal network but needs secure external ingress. It is also excellent for temporary stakeholder review URLs during development. A quick tunnel is never the right production pick for a stable public product because the URL is ephemeral and tied to a local process. Even named tunnels should not be used when the workload needs cloud autoscaling, regional high availability, managed runtime isolation, or independence from a single laptop or office network.

---

## Repository Artifacts Added

```text
.github/workflows/release.yml
cloud/huggingface-space/Dockerfile
cloud/huggingface-space/README.md
cloud/cloudflare/README.md
cloud/scripts/measure-curl-latency.sh
cloud/teardown.md
submissions/lab10.md
```
