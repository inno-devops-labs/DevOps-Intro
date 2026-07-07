# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud

## Task 1 — CI Automated Push to GHCR

### Release workflow

Workflow file:

```
.github/workflows/release.yml
```

The workflow is triggered by git tags matching:

```
v*
```

It builds the QuickNotes Docker image from:

```
app/
```

and pushes it to GitHub Container Registry (GHCR).

The workflow uses minimum required permissions:

```yaml
contents: read
packages: write
```

All third-party GitHub Actions are pinned by commit SHA.

---

## Image

GHCR image:

```
ghcr.io/infernaltiger/devops-intro/quicknotes:v0.1.0
```

Latest tag:

```
ghcr.io/infernaltiger/devops-intro/quicknotes:latest
```

The package is public and can be pulled without authentication.

---

## Successful pull

The image was tested using Docker:

```bash
docker pull ghcr.io/infernaltiger/devops-intro/quicknotes:v0.1.0
```

Result:

```
Status: Downloaded newer image for ghcr.io/infernaltiger/devops-intro/quicknotes:v0.1.0
```

Image digest:

```
sha256:b6251f58ebe556648978b7348eff0f0d35ee0abcfe7fbde0130b6fb51912602f
```

---

## CI run

GitHub Actions successful run:

https://github.com/infernaltiger/DevOps-Intro/actions/runs/28867091243


---

# Design questions

## a) OIDC vs GITHUB_TOKEN

For pushing an image to GHCR from the same GitHub repository,
`GITHUB_TOKEN` is enough because GitHub automatically provides a short-lived
token with the required permissions.

OIDC is useful when accessing external cloud providers such as AWS, GCP or Azure.
It allows GitHub Actions to exchange its identity for temporary cloud credentials
without storing long-lived secrets.

---

## b) Why ship both latest and immutable version tags?

The immutable version tag (`v0.1.0`) allows reproducible deployments because it
always points to the same image.

The `latest` tag is convenient for development and environments where the newest
release should automatically be used.

---

## c) Why only packages: write?

The principle is least privilege.

`packages: write` allows the workflow to push container images to GHCR but does
not allow unnecessary changes to repository contents or settings.

A broader permission such as `write-all` could allow a compromised workflow to
modify source code, create releases, or perform other unwanted repository actions.

---

# Task 2 — Hugging Face Spaces Deployment

## Space

Hugging Face Space URL:

https://infernaltiger-quicknotes-lab10.hf.space

The Space uses Docker SDK.

The container listens on:

```
8080
```

because QuickNotes exposes port 8080 while Hugging Face Spaces defaults to port
7860.

---

## Docker image source

The Space runs the published GHCR image:

```
ghcr.io/infernaltiger/devops-intro/quicknotes:v0.1.0
```

Using the same image from GHCR provides reproducibility between CI and deployment.

---

## Health check

Command:

```bash
curl https://infernaltiger-quicknotes-lab10.hf.space/health
```

Response:

```json
{
  "notes":4,
  "status":"ok"
}
```

---

# Latency measurements

## Warm latency

Five consecutive requests:

```
0.608043
0.592073
0.472836
0.573691
0.695209
```

Sorted values:

```
0.472836
0.573691
0.592073
0.608043
0.695209
```

Warm p50:

```
0.592073 seconds
```

---

## Cold latency

The lab specification expects Hugging Face Spaces to automatically sleep after
approximately 30 minutes of inactivity.

However, the current free `cpu-basic` Hugging Face Spaces runtime does not
provide a practical short sleep cycle. The sleep timeout is much longer and
cannot be configured on free hardware.

Therefore, automatic scale-to-zero wake-up measurements were replaced with a
reproducible pause/restart experiment.

The Space was explicitly paused using the Hugging Face API and then restarted.
The first successful `/health` request time was measured after each restart cycle.
Three pause/restart cycles were measured:

```
3.394110
7.427519
6.802102
```

Average restart startup latency:

```
5.874577 seconds
```

This measurement includes container scheduling, application startup and routing
recovery. It represents a cold restart scenario, but not the exact automatic
sleep-triggered wake-up path.

---

# Design questions

## d) HF Spaces sleep vs Cloud Run scale-to-zero

Both platforms stop inactive containers to reduce resource usage.

HF Spaces has slower wake-up because it is optimized for free hosting and
interactive demos, while production platforms such as Cloud Run optimize more for
fast autoscaling and production workloads.

---

## e) Why app_port: 8080?

Hugging Face Spaces Docker deployments use port 7860 by default.

QuickNotes listens on port 8080, therefore the Space configuration requires:

```yaml
app_port: 8080
```

---

## f) Pulling image from GHCR vs building inside Space

Pulling the image from GHCR provides reproducibility because the exact tested
container image is deployed.

Building inside the Space simplifies debugging because the build process and
application source are located in one repository.

The trade-off is between reproducibility and easier development/debugging.