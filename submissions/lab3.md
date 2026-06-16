# Lab 3 submission

**Path chosen:** GitHub Actions — already using GitHub for the course fork, SSH signing, and branch protection from Labs 1–2.

## Task 1 — PR Gate

### CI workflow

Workflow file: `.github/workflows/ci.yml`

- Triggers on push/PR to `main` (path-filtered to `app/**` and `.github/workflows/**`)
- Three parallel jobs: `vet`, `test`, `lint`
- Runner: `ubuntu-24.04` (pinned)
- `go vet ./...`, `go test -race -count=1 ./...`, `golangci-lint run` (v2.5.0) in `app/`
- Third-party actions pinned by full SHA; `permissions: contents: read`

### Green CI run

<!-- TODO: paste link to a green Actions run after pushing feature/lab3 -->

### Deliberate failure + fix

<!-- TODO: paste failed run link/log after breaking handlers_test.go, then fix commit link -->

### Branch protection

<!-- TODO: add screenshot submissions/lab3-branch-protection.png -->

Required checks on fork `main`: `vet`, `test`, `lint` (all matrix variants), branches up to date.

### Design questions (Task 1.2)

**a) Why pin `ubuntu-24.04` instead of `ubuntu-latest`?**

`ubuntu-latest` is a moving target — GitHub can retarget it to a newer image without warning. A pipeline that passed yesterday may fail tomorrow because preinstalled packages, kernel, or tool versions changed. Pinning `ubuntu-24.04` makes CI reproducible: the same runner image behaves the same across runs until you consciously upgrade.

**b) Why split vet, test, and lint into separate jobs?**

Each job runs on its own runner in parallel, so wall-clock time is roughly the slowest job, not the sum of all three. Failures are isolated — a lint error does not hide a test failure behind a combined log. In branch protection you can require each check independently. One combined job would serialize the work, produce one opaque log, and make it harder to see which quality gate failed.

**c) What attack does SHA pinning prevent? (GH path)**

Tag-based action references (`@v4`, `@v4.2.2`) are mutable — a compromised maintainer account can retag a release to malicious code. In **March 2025**, the `tj-actions/changed-files` action was compromised; attackers rewrote tags and leaked secrets from thousands of CI runs. Pinning the full 40-character commit SHA means the workflow always checks out the exact audited revision unless someone deliberately updates the SHA in a reviewed PR.

**d) What is `permissions:` and what principle is behind it?**

`permissions:` sets the GitHub token scope available to the workflow (here `contents: read`). The principle is **least privilege**: the token should only access what the job needs. A compromised step or malicious action cannot write to the repo, open PRs, or modify packages if the token is read-only.

**e) GitLab path (not used):** N/A — chose GitHub Actions.

---

## Task 2 — Make It Fast and Smart

### Optimizations applied

1. **Go module cache** — `actions/setup-go` with `cache: true` and `cache-dependency-path: app/go.sum`
2. **Build matrix** — `vet` and `test` run on Go `1.23` and `1.24` in parallel with `fail-fast: false`
3. **Path filter** — workflow runs only when `app/**` or `.github/workflows/**` change
4. **Bonus:** `concurrency` with `cancel-in-progress: true` — superseded runs on the same branch are cancelled
5. **Bonus:** `GOFLAGS=-buildvcs=false` — skips VCS metadata embedding when clone history is shallow
6. **Bonus:** `timeout-minutes: 10` per job — fails fast instead of hanging on a stuck runner

### Timing table

| Scenario | Wall-clock |
|----------|-----------|
| Baseline (no cache, single Go version, no path filter) | <!-- TODO: XX s --> |
| With cache | <!-- TODO: XX s --> |
| With cache + matrix | <!-- TODO: XX s --> |

<!-- Measure from GitHub Actions UI. Temporarily disable each optimization in a commit to get baseline numbers. -->

### Design questions (Task 2)

**f) Why cache `go.sum`-keyed inputs and not build outputs?**

Module download cache is keyed on `go.sum`, which pins exact dependency versions — the same inputs produce the same modules on every run. Build outputs depend on Go version, compiler flags, and runner environment; caching them risks stale or incompatible artifacts. Caching inputs (modules) is safe and speeds up `go mod download`; caching outputs can silently serve wrong binaries.

**g) What does `fail-fast: false` change in a matrix, and when use `fail-fast: true`?**

With `fail-fast: false`, all matrix cells run to completion even if one fails — you see whether Go 1.23, 1.24, or both broke. With `fail-fast: true` (the default), the first failing cell cancels the rest, hiding which versions still pass. Use `fail-fast: true` when cells are redundant smoke tests and you only need one signal (e.g. identical deploy previews); use `false` when each cell is meaningful (different Go versions).

**h) Cache poisoning risk from a malicious PR**

An attacker on an unprotected branch could write a poisoned cache (e.g. malicious `go.sum` resolution or corrupted module cache) keyed the same way as protected branches. Later PRs on protected branches might restore that cache and run with tainted dependencies. GitHub mitigates this by scoping caches to the branch and restricting cache write access from fork PRs (`GITHUB_TOKEN` from fork PRs is read-only for caches from the base branch). Official doc: [Dependency caching — Restrictions for accessing a cache](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows#restrictions-for-accessing-a-cache).

---

## Bonus Task — Pipeline Performance Investigation

### Before/after optimizations

| Optimization applied | Before (s) | After (s) | Saving |
|----------------------|-----------:|----------:|-------:|
| Go module cache (`setup-go cache`) | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |
| Path filter (skip docs-only) | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |
| `concurrency` cancel-in-progress | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |
| **Total wall-clock** | **<!-- TODO -->** | **<!-- TODO -->** | **<!-- TODO -->** |

### Per-step profile

<!-- TODO: fill from Actions UI after green run -->

| Job | Runner start | Setup / cache | Work (vet/test/lint) | Cleanup |
|-----|-------------|---------------|----------------------|---------|
| vet | | | | |
| test | | | | |
| lint | | | | |

### Bottleneck analysis

<!-- TODO: 4-6 sentences after reviewing CI timings -->
