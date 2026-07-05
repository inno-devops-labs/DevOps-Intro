# Lab 10 — Cloud Computing

Branch: feature/lab10

## Summary

Task 1, Task 2, and the Cloudflare Tunnel bonus are completed.

## Task 1 — CI automated push to GHCR

### Release workflow

Workflow path: .github/workflows/release.yml

The workflow triggers on pushed tags matching v* and validates strict semantic version tags in the form vMAJOR.MINOR.PATCH.

The release tag used for this lab is v0.1.0.

The signed tag points to commit:

3dfb81a7fed822dda0fc5041fda662e4563e4416

The tag was verified locally with:

git verify-tag v0.1.0

### Published image

Image name:

ghcr.io/tivdzualubem/devops-intro/quicknotes

Published tags:

- ghcr.io/tivdzualubem/devops-intro/quicknotes:v0.1.0
- ghcr.io/tivdzualubem/devops-intro/quicknotes:latest

Registry digest:

sha256:51087fe7c8f2c787d8e338cf3c1c6f801aba4a6d4431a285629349fd1ed56db8

Image ID:

sha256:0ea6eca6e351804a946a0a940df674eb40bac873229822d7fad6442b0edce6a3

### Release run evidence

Green release run:

https://github.com/tivdzualubem/DevOps-Intro/actions/runs/28542860182

Evidence files:

- artifacts/lab10/registry/release-run.txt
- artifacts/lab10/registry/release-run.json
- artifacts/lab10/registry/image-references.txt
- artifacts/lab10/registry/registry-verification.txt
- artifacts/lab10/registry/unauthenticated-pull-v0.1.0.txt
- artifacts/lab10/registry/unauthenticated-pull-latest.txt

The registry verification recorded:

- package_visibility: public
- version_pull_status: 0
- latest_pull_status: 0
- same_image_status: 0
- health_status: 0
- notes_status: 0

### Security and workflow choices

Minimum permissions:

- contents: read
- packages: write

The workflow only grants the permissions needed to read the repository contents and publish the image to GHCR.

Third-party action pinning:

- actions/checkout is pinned by full 40-character SHA: 11bd71901bbe5b1630ceea73d27597364c9af683

### Design questions a-c

a) OIDC vs GITHUB_TOKEN

For pushing to GHCR from the same GitHub repository, GITHUB_TOKEN with packages: write is sufficient because GHCR understands that repository-scoped token. I would use OIDC when the workflow needs to authenticate to an external cloud provider such as AWS, Azure, or GCP without storing long-lived cloud secrets in GitHub. OIDC gives short-lived, audience-bound credentials issued after the cloud provider verifies the GitHub workflow identity, branch, repository, and other claims.

b) latest vs immutable version tag

The v0.1.0 tag is the immutable deployment reference. It is what downstream deployments should use when they need reproducibility. The latest tag is still useful as a convenience pointer for humans, demos, quick local testing, and consumers who intentionally want the newest release. Shipping both gives reproducibility for production and convenience for discovery.

c) packages: write only

The principle is least privilege. The release job needs to publish packages, not rewrite repository contents, change pull requests, modify issues, or administer the repo. A narrow packages: write scope limits the blast radius if the workflow or token is compromised. Compared with write-all permissions, it helps prevent an attacker from using the release job token to push code changes, alter repository metadata, or tamper with unrelated GitHub resources.

## Task 2 — Hugging Face Spaces deployment

### Public Space

Hugging Face Space:

https://huggingface.co/spaces/lubem/quicknotes-lab10

Public application URL:

https://lubem-quicknotes-lab10.hf.space

Public endpoints:

- https://lubem-quicknotes-lab10.hf.space/health
- https://lubem-quicknotes-lab10.hf.space/notes

The public /health response recorded in artifacts/lab10/huggingface/public-health.json was:

{"notes":4,"status":"ok"}

The public /notes response was recorded in:

artifacts/lab10/huggingface/public-notes.json

It returned the four seeded QuickNotes notes.

### Hugging Face Space files

Space Dockerfile path in this repository:

cloud/huggingface/Dockerfile

Dockerfile content:

FROM ghcr.io/tivdzualubem/devops-intro/quicknotes:v0.1.0

EXPOSE 8080

The Space pulls the immutable v0.1.0 GHCR image instead of latest, so the deployed container is tied to the signed Lab 10 release.

Space README path in this repository:

cloud/huggingface/README.md

README frontmatter:

---
title: QuickNotes Lab 10
emoji: 📝
sdk: docker
app_port: 8080
---

### Public curl proof

Verbose public /health proof is recorded in:

artifacts/lab10/huggingface/public-health-curl-v.txt

Important observed values:

- connected to lubem-quicknotes-lab10.hf.space
- TLS connection succeeded
- HTTP/2 200
- content-type: application/json
- x-content-type-options: nosniff
- x-frame-options: DENY

### Warm latency

Five consecutive warm /health request timings:

- 0.958094 seconds
- 0.470079 seconds
- 0.617242 seconds
- 0.419299 seconds
- 0.386668 seconds

Warm p50:

0.470079 seconds

Evidence files:

- artifacts/lab10/huggingface/warm-times.txt
- artifacts/lab10/huggingface/warm-summary.txt

### Cold latency

The cold-start protocol was:

1. Confirm the Space was working.
2. Record the idle-start timestamp.
3. Avoid Space requests and browser access for 40 minutes.
4. Make one first request.
5. Require HTTP 200.
6. Repeat for three cold cycles.

The 40-minute idle window exceeds the required 35+ minutes.

Cold samples:

- Cycle 1: 0.832342 seconds
- Cycle 2: 0.865489 seconds
- Cycle 3: 0.997414 seconds

Evidence files:

- artifacts/lab10/huggingface/cold-cycle-1-idle-start.txt
- artifacts/lab10/huggingface/cold-cycle-1-response.json
- artifacts/lab10/huggingface/cold-cycle-1-result.txt
- artifacts/lab10/huggingface/cold-cycle-2-idle-start.txt
- artifacts/lab10/huggingface/cold-cycle-2-result.txt
- artifacts/lab10/huggingface/cold-cycle-3-idle-start.txt
- artifacts/lab10/huggingface/cold-cycle-3-result.txt
- artifacts/lab10/huggingface/latency-summary.txt

### Design questions d-f

d) HF Spaces sleep vs Cloud Run scale to zero

Both platforms can stop idle workloads and wake them on demand, but they optimize for different use cases. Cloud Run is a production serverless container platform with faster request routing, autoscaling, and cold-start optimization. Hugging Face Spaces is optimized for free hosted demos, ML apps, and simple public projects. On the free tier, it can sleep after inactivity and wake more slowly because low cost and shared capacity matter more than production-grade startup latency. For QuickNotes, this means HF is acceptable for a lab/demo, but not the platform I would choose for strict latency SLOs.

e) Why app_port: 8080 is needed

QuickNotes listens on port 8080. Hugging Face Spaces defaults to port 7860 because many Gradio and demo apps use 7860. Without app_port: 8080 in the README frontmatter, HF would route traffic to the wrong port and the Space would not expose the QuickNotes API correctly. Setting app_port: 8080 tells HF which container port should receive public requests.

f) Pulling from GHCR vs building inside the Space

Pulling the already released GHCR image improves reproducibility because the Space runs the same immutable v0.1.0 image that was built and published by the signed release workflow. It also keeps the Space Dockerfile small and makes debugging easier: if the Space fails, the deployment layer is separate from the application build. Building inside the Space can be convenient during rapid iteration because the Space repo contains everything it needs, but it duplicates CI build logic and may make cache behavior and release provenance less clear.

## Bonus — Cloudflare Tunnel

Status: completed.

Cloudflare Tunnel URL:

https://controversy-parcel-designer-enjoying.trycloudflare.com

The tunnel exposed the local Lab 10 QuickNotes Docker container on port 8080.

Local health verification: {"notes":4,"status":"ok"}

Public Cloudflare health verification: {"notes":4,"status":"ok"}

Phone cellular verification: the same public /health URL returned {"notes":4,"status":"ok"}.

Tunnel evidence:

Registered tunnel connection connIndex=0 connection=47ac8f96-f3b0-46eb-b172-d046e65d8e26 ip=198.41.192.77 location=mad06 protocol=http2

Cloudflare latency evidence:

- runs: 50
- p50_ms: 5645.342
- p95_ms: 6610.407
- mean_ms: 3647.065
- min_ms: 553.140
- max_ms: 11171.764

Hugging Face vs Cloudflare:

- Hugging Face warm p50: 470.079 ms from the existing warm sample.
- Cloudflare Tunnel warm p50: 5645.342 ms from 50 requests.
- Cloudflare Tunnel warm p95: 6610.407 ms from 50 requests.

The Cloudflare path was slower and more variable from this network because requests crossed the VPN route, Cloudflare edge, the temporary tunnel, and then the local container.

Bonus design answers:

g. Cloudflare Tunnel avoids inbound port forwarding. cloudflared opens an outbound connection to Cloudflare, and public requests are forwarded through that connection to the local container.

h. The tunnel still depends on the local machine and network path. If the laptop sleeps, Docker stops, cloudflared exits, the VPN route breaks, or the quick tunnel expires, the public URL stops working.

i. For a temporary lab demo, a quick trycloudflare.com tunnel is useful because it exposes the local container without router changes. For production, I would use a named Cloudflare Tunnel or a managed cloud service with a stable hostname and better operational controls.

Evidence files:

- artifacts/lab10/cloudflare/url.txt
- artifacts/lab10/cloudflare/local-health.json
- artifacts/lab10/cloudflare/remote-health.json
- artifacts/lab10/cloudflare/phone-cellular-health.txt
- artifacts/lab10/cloudflare/cloudflare-latency.txt
- artifacts/lab10/cloudflare/cloudflare-latency.json
- artifacts/lab10/cloudflare/cloudflare-latency-summary.txt
- artifacts/lab10/cloudflare/windows-cloudflared-success.log

## Teardown

Teardown notes are recorded in:

cloud/teardown.md

Summary:

- Keep the Hugging Face Space public until grading is complete.
- After grading, delete the Hugging Face Space from its Settings page.
- Stop any Cloudflare quick tunnel with Ctrl+C. Its temporary URL then expires.
- The public GHCR image may remain available for reproducibility.
