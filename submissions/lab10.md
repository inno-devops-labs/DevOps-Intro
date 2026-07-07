# Lab 10 — Cloud Computing: Ship QuickNotes to a Real Cloud

## Task 1 — CI-Automated Push to `ghcr.io`

### 1.1 Release workflow

[`.github/workflows/release.yml`](../.github/workflows/release.yml):

```yaml
name: Release

permissions:
  contents: read

on:
  push:
    tags:
      - 'v*'

jobs:
  push-image:
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Compute image ref
        id: image
        run: |
          repo_lower="${GITHUB_REPOSITORY,,}"
          version="${GITHUB_REF_NAME#v}"
          echo "name=ghcr.io/${repo_lower}/quicknotes" >> "$GITHUB_OUTPUT"
          echo "version=${version}" >> "$GITHUB_OUTPUT"

      - uses: docker/login-action@af1e73f918a031802d376d3c8bbc3fe56130a9b0 # v4.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@53b7df96c91f9c12dcc8a07bcb9ccacbed38856a # v7.3.0
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ${{ steps.image.outputs.name }}:${{ steps.image.outputs.version }}
            ${{ steps.image.outputs.name }}:latest
```

Requirements checklist:
1. ✅ Triggers only on `v*` tag pushes (`on.push.tags`)
2. ✅ Builds from the repo root (`context: .`, `file: ./Dockerfile`) — the same `Dockerfile` Lab 6/9 use, which `COPY`s `app/` in
3. ✅ Pushes to `ghcr.io/<owner>/<repo>/quicknotes`, computed dynamically from `GITHUB_REPOSITORY` (lowercased — ghcr.io requires lowercase repo paths) so the workflow works unmodified on any fork
4. ✅ Tags both the version from the pushed tag (`v0.1.0` → `0.1.0`) and `latest`
5. ✅ Permissions scoped to `contents: read` + `packages: write` at the job level — nothing else
6. ✅ All third-party actions pinned by 40-char commit SHA (`actions/checkout`, `docker/login-action`, `docker/build-push-action`), resolved from each action's real tag via `git ls-remote --tags`, with the human-readable version kept as a trailing comment
7. Validated with `actionlint` (clean) and a local `docker build -f Dockerfile .` using the same context/file args before pushing

### 1.2 Tagging and pushing

```bash
git tag -a -s v0.1.0 -m "Lab 10 release"
git push origin v0.1.0
```

<!-- TODO: fill in after pushing — registry URL, clean-pull evidence, green run URL -->

### 1.3 Design questions

**a) OIDC vs `GITHUB_TOKEN` — when would you reach for OIDC instead?**
For pushing to `ghcr.io` from a workflow running *in the same repository* it's pushing to, the ephemeral, repo-scoped `GITHUB_TOKEN` (with `packages: write`) is sufficient and simpler — GitHub mints and revokes it automatically per workflow run, so there's no long-lived secret to manage. OIDC earns its complexity when the *target* is a **different** trust domain that can't consume a GitHub-issued token directly — pushing to AWS ECR, Azure ACR, or GCP Artifact Registry, deploying to a cloud provider, or signing with an external KMS. There, the workflow exchanges its GitHub-issued OIDC token for short-lived cloud credentials via a trust relationship configured once on the cloud side, so you never store a static cloud access key as a GitHub secret at all. The win isn't security theater — it's removing a long-lived credential that could leak from Actions logs, forks, or a compromised dependency, in favor of a token that's scoped to *this run*, *this repo*, and expires when the job ends.

**b) Why ship `:latest` alongside the immutable `:v0.1.0` tag?**
`:latest` is for humans and tooling doing "give me whatever's current" without wanting to track version numbers — a quick `docker pull ghcr.io/.../quicknotes:latest` for local testing, a doc example, or a dev/staging manifest that intentionally always wants the newest build. It's never meant for anything that needs reproducibility or rollback — those pin `:v0.1.0` (or better, the immutable digest) so "what's actually running" is answerable months later even after ten more tags have shipped. Shipping both isn't a contradiction: `:latest` is a *convenience alias* pointed at whatever the most recent immutable tag is, not a substitute for it. Production deployments should always reference the immutable tag/digest; `:latest` rides along for everyone else.

**c) `packages: write` scope only — what attack does the narrow scope prevent?**
The principle is least privilege applied to the *ephemeral* `GITHUB_TOKEN`: a workflow run should only be able to do the one thing it's actually there to do. This workflow's job needs to push an image to `ghcr.io` and nothing else, so the job-level `permissions:` block grants exactly `contents: read` (to check out the repo) and `packages: write` (to push) — no `contents: write`, no `issues: write`, no `actions: write`. The concrete attack this blocks: if a dependency in the build step (or a malicious PR that somehow triggers this workflow) manages to run arbitrary code inside the job, the blast radius is capped at "can push a package" — it *cannot* rewrite repository contents, open/modify PRs, edit other workflows, or touch anything else `GITHUB_TOKEN` could reach under the repository's default (broader) permission set. `write-all` would hand a compromised build step every one of those capabilities simultaneously; scoping to exactly what's needed turns a potential full-repo-compromise into a much smaller, contained one.
