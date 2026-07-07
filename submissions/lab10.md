# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud

## Task 1 — CI-Automated Push to ghcr.io

### Release workflow
`.github/workflows/release.yml`

### Registry URL
`ghcr.io/abdra04-gif/quicknotes:v0.1.5`

### Successful clean pull
```bash
$ docker pull ghcr.io/abdra04-gif/quicknotes:v0.1.5
$ docker run --rm -p 8080:8080 ghcr.io/abdra04-gif/quicknotes:v0.1.5
$ curl -s http://localhost:8080/health
{"notes":0,"status":"ok"}
Green CI run

Successful run for v0.1.5

Answers to design questions 1.2

a) OIDC vs GITHUB_TOKEN
GITHUB_TOKEN with packages: write is enough for pushing to ghcr.io from the same repo. OIDC is used for external cloud providers (AWS, GCP) to avoid storing long-lived credentials.

b) :latest vs :v0.1.0
:latest is mutable for convenience, :v0.1.0 is immutable for releases. Shipping both enables easy rollbacks while providing a "latest" alias.

c) packages: write scope only
Principle of least privilege – prevents accidental modification of code or settings, reducing attack surface.

Task 2 — Deploy to Hugging Face Spaces

Space URL

https://Abdirakhim-quicknotes-lab10.hf.space

Verification
$ curl -s https://Abdirakhim-quicknotes-lab10.hf.space/health
{"notes":0,"status":"ok"}
Space repo files

Dockerfile:
FROM ghcr.io/abdra04-gif/quicknotes:v0.1.5
EXPOSE 8080
CMD ["/app/quicknotes"]
README.md:
---
title: QuickNotes Lab10
emoji: 🚀
colorFrom: blue
colorTo: purple
sdk: docker
app_port: 8080
---
Latency measurements
Warm p50 (5 consecutive requests): 1.29 s
(values: 1.158, 1.194, 1.297, 1.306, 1.386)
Cold average (3 measurements after sleep/wake): 3.2 s
Answers to design questions 2.4

d) HF Spaces "sleep" vs Cloud Run "scale to zero"
HF Spaces on free tier are designed for prototyping – they wake up slowly because the container must be restored from disk and network routes re-established. Cloud Run is optimized for faster cold starts (< 1s). HF prioritizes zero cost over speed.

e) Why app_port: 8080?
HF expects port 7860 by default (Python SDK). QuickNotes uses 8080, so we override with app_port: 8080. Without it, the Space would try the wrong port and report unhealthy.

f) Pull from ghcr.io vs building inside the Space
Pulling a pre-built image ensures reproducibility – the same image that passed CI is deployed. Building inside the Space is slower, less reproducible, and harder to debug. Pulling is the production best practice.

Bonus — not attempted

