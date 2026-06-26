# Lab 10 — Cloud: GHCR Release + Hugging Face Spaces

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + Docker + GitHub Actions + Hugging Face Spaces

---

## Task 1 — CI push to ghcr.io

### Release workflow

[`.github/workflows/release.yml`](../.github/workflows/release.yml) — triggers on `v*` tags, builds `app/Dockerfile`, pushes:

```text
ghcr.io/selysecr332/devops-intro/quicknotes:<tag>
ghcr.io/selysecr332/devops-intro/quicknotes:latest
```

Permissions: `contents: read`, `packages: write` only.

### Release

```bash
git tag -a v0.1.0 -m "Lab 10 release"
git push origin v0.1.0
```

> After first push: GitHub → **Packages** → `devops-intro/quicknotes` → **Package settings** → **Change visibility** → **Public**.

### Evidence

| Item | Value |
|------|-------|
| Registry URL | `ghcr.io/selysecr332/devops-intro/quicknotes:v0.1.0` |
| Digest | `sha256:4887e6d9ea54c73efda95a9f1cfba272d09294c3f4e6db6088160962b1764c8a` |
| Clean pull | See below — pull succeeded without login |
| Green release run | https://github.com/selysecr332/DevOps-Intro/actions/workflows/release.yml (run #2, tag `v0.1.0`, commit `362e64a`) |

```text
$ docker pull ghcr.io/selysecr332/devops-intro/quicknotes:v0.1.0
v0.1.0: Pulling from selysecr332/devops-intro/quicknotes
...
Status: Downloaded newer image for ghcr.io/selysecr332/devops-intro/quicknotes:v0.1.0
Digest: sha256:4887e6d9ea54c73efda95a9f1cfba272d09294c3f4e6db6088160962b1764c8a
```

### Design questions (Task 1)

**a) OIDC vs `GITHUB_TOKEN` for ghcr?**

For pushes from the **same repo**, `GITHUB_TOKEN` with `packages: write` is enough — no long-lived secret to store. **OIDC** is for federated trust to **external** clouds (AWS, GCP, Azure): short-lived tokens bound to workflow identity, no static PAT, and cross-repo/org policies. OIDC gives auditable, scoped federation that `GITHUB_TOKEN` cannot provide outside GitHub's own registry/API surface.

**b) Why ship `:latest` alongside `:v0.1.0`?**

`:v0.1.0` is **immutable** — the audit trail for rollbacks and HF Spaces pin. `:latest` is a **mutable pointer** for convenience (`docker pull` without looking up tags, dev/Spaces defaults). Production deploys should pin semver; `latest` is ergonomics, not the source of truth.

**c) `packages: write` only — what attack does narrow scope prevent?**

Principle of least privilege. If a compromised action or script exfiltrates the job token, `packages: write` limits blast radius to **container packages** — not rewriting `main`, deleting repos, modifying other workflows, or reading unrelated secrets with `contents: write` / admin scopes.

---

## Task 2 — Hugging Face Spaces

### Space files (in repo + pushed to HF Space Git)

- [`cloud/hf-space/Dockerfile`](../cloud/hf-space/Dockerfile) — `FROM ghcr.io/.../quicknotes:v0.1.0`
- [`cloud/hf-space/README.md`](../cloud/hf-space/README.md) — `sdk: docker`, `app_port: 8080`

### Space URL

```text
https://<user>-<spacename>.hf.space
```

### Health check

```bash
curl -v https://<your-space>.hf.space/health
```

```text
<!-- paste curl -v excerpt -->
```

### Latency (scale-to-zero)

| Measurement | Value |
|-------------|------:|
| Warm p50 (5 runs) | <!-- s --> |
| Cold #1 (after 35+ min idle) | <!-- s --> |
| Cold #2 | <!-- s --> |
| Cold #3 | <!-- s --> |

```bash
bash cloud/scripts/measure-warm.sh https://<your-space>.hf.space/health
```

### Design questions (Task 2)

**d) HF sleep vs Cloud Run scale-to-zero?**

<!-- TODO -->

**e) Why `app_port: 8080`?**

<!-- TODO -->

**f) Pull from ghcr vs build in Space?**

<!-- TODO -->

---

## Bonus — Cloudflare Tunnel

<!-- TODO if attempted -->

| Metric | HF Spaces | Cloudflare Tunnel |
|--------|----------:|------------------:|
| Warm p50 | | |
| Warm p95 | | |
| Cold start | | N/A |
| URL stability | stable | ephemeral |
| Cost | free | free |

Tear down: [`cloud/teardown.md`](../cloud/teardown.md)

---

## Lab 10 completion checklist

### Task 1 (6 pts)

- [x] `release.yml` on `feature/lab10`
- [x] Tag `v0.1.0` pushed; image public on ghcr.io
- [x] Design questions a–c answered

### Task 2 (4 pts)

- [ ] HF Space live; `/health` and `/notes` work
- [ ] Warm + cold latency measured
- [ ] Design questions d–f answered

### Bonus (2 pts)

- [ ] Quick tunnel + comparison table

### Submission

- [ ] Course PR (`feature/lab10` → `inno-devops-labs/main`)
- [ ] Fork PR
- [ ] Moodle URL
