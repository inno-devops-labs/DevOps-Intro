# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud

---

## Task 1 — CI-Automated Push to ghcr.io

### Workflow

The release workflow is located at `.github/workflows/release.yml`. It triggers on push of tags matching `v*` pattern. The workflow builds the Docker image from the root of the repository and pushes it to GitHub Container Registry. The image is tagged with both the version number and `latest`.

The workflow ran successfully for tag `v0.1.0`. The image is publicly pullable from:

```
ghcr.io/venerabikbulatova/devops-intro/quicknotes:latest
```

Verification of successful pull:

```bash
docker pull ghcr.io/venerabikbulatova/devops-intro/quicknotes:latest
```

### Design Questions

a) OIDC vs GITHUB_TOKEN

For pushing to ghcr.io from the same repository, `GITHUB_TOKEN` with `packages: write` permission is sufficient. OIDC would be needed when accessing resources in other cloud providers like AWS or GCP, as it provides temporary credentials without storing long-lived secrets. OIDC also gives better auditability and more precise access control.

b) :latest tag vs immutable version tag

The `:latest` tag is useful for development and staging environments where you want the most recent version without updating version numbers. The immutable version tag like `v0.1.0` ensures reproducibility and enables easy rollback in production. Both serve different purposes in the deployment pipeline.

c) packages: write scope only

This follows the principle of least privilege. If the workflow is compromised, the attacker only gets access to container packages, not to source code, secrets, or other repository resources. A broader `write: all` scope would be unnecessarily dangerous.

---

## Task 2 — Deploy to Hugging Face Spaces

### Space Deployment

The QuickNotes application is deployed at:

https://venerabikbulatova-quicknotes.hf.space

Verification that the service works:

```bash
curl https://venerabikbulatova-quicknotes.hf.space/health
```

Response: `{"notes":4,"status":"ok"}`

### Configuration

The Space uses a simple Dockerfile that pulls the pre-built image from ghcr.io:

```dockerfile
FROM ghcr.io/venerabikbulatova/devops-intro/quicknotes:latest
```

The README.md metadata declares the SDK and port:

```yaml
---
title: QuickNotes
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 8080
---
```

### Latency Measurements

Warm latency was measured on requests where the Space was already active. The following results were obtained:

| Request | Time   |
| ------- | ------ |
| 1       | 0.640s |
| 2       | 0.508s |
| 3       | 0.499s |

Sorted values: 0.499, 0.508, 0.640

Warm p50 (median): 0.508s

Cold start was observed on requests that woke up the Space from sleep. These requests took significantly longer because the container needed to start from scratch:

| Measurement | Time    |
| ----------- | ------- |
| Cold 1      | 10.001s |
| Cold 2      | 10.001s |

Average cold start: 10.001s

The difference between warm and cold latency is about 20x, which shows the impact of HF Spaces sleep mechanism on response time. Cold starts add noticeable delay for the first user after a period of inactivity, while subsequent requests are much faster.

### Design Questions

d) HF Spaces "sleep" vs Cloud Run "scale to zero"

Both platforms put inactive containers to sleep to save resources, but the wake-up time differs significantly. HF Spaces is optimized for simplicity and cost efficiency, not for fast wake-up. Cloud Run is optimized for serverless workloads with low latency expectations. HF takes seconds to restart while Cloud Run typically restarts in milliseconds.

e) Why app_port: 8080 is needed

Hugging Face Spaces default port is 7860 because they primarily support Gradio and Streamlit applications which use that port. Since QuickNotes is configured to listen on port 8080, the port must be explicitly declared so HF knows where to route incoming traffic.

f) Pulling image from ghcr.io vs building inside Space

Pulling the pre-built image is faster and more reliable because the image is already built and tested. Building inside the Space would take longer and could fail due to missing dependencies or network issues. On the other hand, building inside the Space would make the deployment self-contained and not depend on an external registry. I chose to pull because it simplifies the deployment process and reduces build time.

---

## Summary

Task 1 (CI to ghcr.io) is complete. The workflow successfully builds and pushes the image on tagged releases.

Task 2 (HF Spaces deployment) is complete. The Space serves QuickNotes at a public URL with measured warm and cold latency.

Bonus Task (Cloudflare Tunnel) was not attempted due to time constraints.
