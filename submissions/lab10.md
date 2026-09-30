# Lab 10 — CI Image Release and Cloud Deployment

## Task 1 — CI-Automated Push to GHCR

I created `.github/workflows/release.yml` to build and publish the QuickNotes Docker image automatically when a Git tag matching `v*` is pushed.

The workflow:

- builds the image from `app/`;
- authenticates to GHCR using `GITHUB_TOKEN`;
- publishes the image to `ghcr.io/rslwqr/devops-intro/quicknotes`;
- publishes both an immutable version tag and `latest`;
- uses only `contents: read` and `packages: write` permissions;
- pins third-party GitHub Actions to full commit SHAs;
- triggers the Render deploy hook after publishing the image.

The release workflow was successfully tested with `v0.1.0` and `v0.1.1`.

The GHCR package was made public. An unauthenticated pull of the released image was verified with:

```bash
tmp=$(mktemp -d)
DOCKER_CONFIG="$tmp" docker pull \
  --platform linux/amd64 \
  ghcr.io/rslwqr/devops-intro/quicknotes:v0.1.0
rm -rf "$tmp"
```

The pull completed successfully with image digest:

```text
sha256:a2a3f57d5dd926001debac935739db51e6e9fe8182d95022bd6a8a84de0c2570
```

The image is built for `linux/amd64`, which is the target platform used for the Render deployment.

### Design questions

#### a. OIDC vs `GITHUB_TOKEN`

`GITHUB_TOKEN` is sufficient for this task because the workflow publishes a package to GHCR from the same GitHub repository. It is automatically created for the workflow and can be restricted with repository permissions.

OIDC is more useful when GitHub Actions needs to authenticate to an external cloud provider. It allows the workflow to obtain short-lived credentials instead of storing long-lived cloud credentials as repository secrets.

#### b. `latest` vs immutable version tags

The `latest` tag is convenient because it points to the most recently published image, but it is mutable and can refer to different image contents over time.

A version tag such as `v0.1.1` is immutable in the release workflow and makes deployments reproducible. Versioned images are therefore preferable for production deployments, debugging and rollback.

#### c. Why `packages: write` is least privilege

The workflow needs `packages: write` to publish the Docker image to GHCR, while `contents: read` is enough to read the repository.

Giving the workflow broader repository write permissions would increase the impact of a compromised workflow or third-party action. With the restricted permissions, an attacker cannot modify repository contents simply through the release job.

---

## Task 2 — Deploy to Render

I used **Option A: Render**. Render did not require card verification for my account, so the Codespaces fallback was not necessary.

### Deployment configuration

The QuickNotes service was deployed using the existing public GHCR image.

- Service: `quicknotes-lab10`
- Region: Frankfurt
- Instance type: Free
- Initial image: `ghcr.io/rslwqr/devops-intro/quicknotes:v0.1.0`
- Public URL: `https://quicknotes-lab10.onrender.com`
- Health check: `/health`

Environment variables:

```text
PORT=10000
ADDR=:10000
DATA_PATH=/data/notes.json
SEED_PATH=/app/seed.json
```

The public health endpoint was verified successfully:

```bash
curl -i https://quicknotes-lab10.onrender.com/health
```

Result:

```text
HTTP/2 200
{"notes":4,"status":"ok"}
```

### CI deployment

A Render deploy hook is stored in GitHub as the `RENDER_DEPLOY_HOOK` Actions secret. The secret value is not stored in the repository.

After publishing a release image, the GitHub Actions workflow calls the deploy hook with the newly created image tag.

This was verified with tag `v0.1.1`. The release workflow completed successfully and Render started a new deployment through the deploy hook. The deployment reached the Live state.

### Warm latency

Five consecutive requests to the warm service produced:

| Request | Latency |
|---|---:|
| 1 | 0.756575 s |
| 2 | 0.522607 s |
| 3 | 0.545513 s |
| 4 | 0.508955 s |
| 5 | 0.677659 s |

Warm p50:

```text
0.545513 s
```

### Cold starts

The service was left idle for at least 20 minutes before each cold-start measurement.

Three cold-start samples were:

```text
13.084200 s
14.023523 s
13.059400 s
```

These measurements show the additional latency caused by waking a free Render service after it has spun down.

### Persistence after spin-down

A new note was created:

```json
{
  "id": 5,
  "title": "Lab 10 persistence test",
  "body": "Testing note persistence after Render spin-down"
}
```

After leaving the service idle for more than 20 minutes and waking it again, `GET /notes` returned only the four original seed notes. The newly created note had disappeared.

This confirms that the writable local filesystem of the free Render instance is ephemeral and should not be used for durable application data.

### Design questions

#### d. Render spin-down vs Cloud Run scale-to-zero

Both approaches reduce resource usage when the application receives no traffic, but they are implemented for different hosting models.

A free Render web service can spin down the whole service after inactivity. Waking it requires the service to be scheduled and started again, which produces a noticeable cold start.

Cloud Run is designed as a serverless container platform with request-driven instance creation and automatic scaling. It also supports scaling to zero, but its infrastructure is specifically designed around dynamically starting container instances.

#### e. Why Render injects `PORT`

Render needs to know which port the application listens on so its routing layer can forward requests to the service.

Docker `EXPOSE` is image metadata and does not force the application to bind to that port at runtime. Therefore the application must use the runtime port expected by the platform.

For this deployment both variables were configured consistently:

```text
PORT=10000
ADDR=:10000
```

This allows QuickNotes to listen on the expected port immediately and avoids an unnecessary port-detection restart.

#### f. Existing image vs building from the repository

Deploying the existing GHCR image means that Render runs the same artifact that was built and released by CI. This improves reproducibility because deployment does not rebuild the application in another environment.

Building directly from the Git repository can be convenient and may benefit from platform build caching, but it creates another build process that can produce an artifact different from the one already tested and published by CI.

The persistence experiment also showed that application data must not rely on the local filesystem of a free Render instance. Durable data should be stored in persistent external storage such as a database.

---

## Teardown

Teardown instructions are documented in `cloud/teardown.md`.

Detailed Render configuration and measurements are documented in `cloud/render.md`
