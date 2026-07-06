# Lab 10 Submission

## Task 1 - CI-Automated Push to GHCR

### Release workflow

Workflow file: `.github/workflows/release.yml`

```yaml
name: release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

env:
  IMAGE_NAME: ghcr.io/software-engineering-toolkit/devops-intro/quicknotes

jobs:
  build-and-push:
    name: build and push QuickNotes image
    runs-on: ubuntu-24.04

    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

      - name: Log in to GHCR
        uses: docker/login-action@74a5d142397b4f367a81961eba4e8cd7edddf772 # v3.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@b5ca514318bd6ebac0fb2aedd5d36ec1b5c232a2 # v3.10.0

      - name: Build and push
        uses: docker/build-push-action@263435318d21b8e681c14492fe198d362a7d2c83 # v6.18.0
        with:
          context: ./app
          push: true
          tags: |
            ${{ env.IMAGE_NAME }}:${{ github.ref_name }}
            ${{ env.IMAGE_NAME }}:latest
```

### Registry image

Versioned image:

```text
ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
```

Latest image:

```text
ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:latest
```

### Successful release run

GitHub Actions run:

```text
https://github.com/software-engineering-toolkit/DevOps-Intro/actions/runs/28813808781
```

### Clean pull evidence

Commands:

```bash
docker rmi ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
docker pull ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
docker run --rm -p 8080:8080 ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
```

Output:

```text
mostafa@pc:~/git_repos/DevOps_Course/DevOps-Intro$ docker rmi ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
Untagged: ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
Untagged: ghcr.io/software-engineering-toolkit/devops-intro/quicknotes@sha256:b2b3b6bfbafbfae83be4dc39bb774c98c938eec2a202726d484b24682b96453d
Deleted: sha256:ba74e0c0ad9eced5e6b0252e5c9cc33baae1874af79c07df859ec68d59f4ada1
Deleted: sha256:d558f5619d21964c6daaed860b67feec646bf416310516d2c314e81285333373
Deleted: sha256:a3ee2c1b145b25e92eef6c8aee06f35e901a4a455f67e90fd39f035989ebf17f
Deleted: sha256:b8ab7170914d975913043f8460fc3f0adc5bf5443652f2d5a567befc0c40e00d
Deleted: sha256:3d66c9a46adf8207ae838dc62b4a3be6b45d6f0d5a20a2b4327a2c042c15850a
Deleted: sha256:5d3cbdc798c0da254c05fff20f808271443c8d247f9cf88b198f0ac610caae6d
mostafa@pc:~/git_repos/DevOps_Course/DevOps-Intro$ docker pull ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
v0.1.0: Pulling from software-engineering-toolkit/devops-intro/quicknotes
47de5dd0b812: Already exists
c172f21841df: Already exists
99515e7b4d35: Already exists
99ba982a9142: Already exists
d6b1b89eccac: Already exists
2780920e5dbf: Already exists
7c12895b777b: Already exists
3214acf345c0: Already exists
52630fc75a18: Already exists
dd64bf2dd177: Already exists
b839dfae01f6: Already exists
ebddc55facdc: Already exists
bdfd7f7e5bf6: Already exists
18e47a42937c: Pull complete
283a1710a7ca: Pull complete
638445068748: Pull complete
3da6f5e3b82e: Pull complete
c7e18dcac92e: Pull complete
Digest: sha256:b2b3b6bfbafbfae83be4dc39bb774c98c938eec2a202726d484b24682b96453d
Status: Downloaded newer image for ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0

mostafa@pc:~/git_repos/DevOps_Course/DevOps-Intro$ docker run --rm -p 8080:8080 ghcr.io/software-engineering-toolkit/devops-intro/quicknotes:v0.1.0
2026/07/06 18:43:36 quicknotes listening on :8080 (notes loaded: 4)
```

Runtime health check:

```bash
curl -s http://localhost:8080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

### Design question a: OIDC vs `GITHUB_TOKEN`

For pushing an image from this repository to this repository's GHCR package, `GITHUB_TOKEN` is enough. The workflow only needs repository-scoped package publishing, so `packages: write` gives it the required access without creating a separate long-lived secret.

OIDC is more useful when the workflow needs to authenticate to an external cloud provider or registry, such as AWS, GCP, Azure, or another deployment platform. With OIDC, GitHub Actions can exchange the workflow identity for short-lived external credentials. This avoids storing static cloud secrets in GitHub and lets the external provider enforce trust conditions such as repository, branch, tag, workflow, or environment.

### Design question b: `latest` tag vs `v0.1.0` immutable tag

The `v0.1.0` tag is the reproducible release reference. It should be used when exact rollback, debugging, auditing, or deployment reproducibility matters because it points to a specific release version.

The `latest` tag is still useful as a convenience pointer to the newest published release. It is practical for local testing, demos, examples, and consumers that intentionally want to track the newest stable image without changing the tag each time. In production, the immutable version tag is safer, while `latest` is a human-friendly shortcut.

### Design question c: `packages: write` scope only

This follows the principle of least privilege: a workflow should receive only the permissions needed for its job.

For this release workflow, the job needs to read repository contents and write container packages. It does not need broad repository write access. Compared with `write-all`, the narrow `contents: read` and `packages: write` permissions reduce the impact of a compromised workflow step or third-party action. An attacker might still try to publish a malicious package, but the token should not also allow unrelated actions such as modifying repository files, changing pull requests, creating releases, or writing to other GitHub resources.
