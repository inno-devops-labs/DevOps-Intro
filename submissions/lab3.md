# Lab 3 — CI/CD: PR-Gated Pipeline for QuickNotes

**Student:** Mahmoud Hassan (`selysecr332`)  
**Path:** GitHub Actions (default — GitHub account available, matches Labs 1–2 workflow)

---

## Task 1 — PR gate

### 1.1 Pipeline

Workflow: `.github/workflows/ci.yml`

- **Triggers:** `push` and `pull_request` to `main`, path-filtered to `app/**` and `.github/workflows/ci.yml`
- **Jobs:** `vet`, `test`, `lint` (separate units) + `ci-ok` aggregation gate
- **Runner:** `ubuntu-24.04` (pinned)
- **Go:** matrix `1.23` + `1.24` for vet/test; `golangci-lint` **v2.5.0** for lint
- **Hardening:** third-party actions pinned by full SHA; `permissions: contents: read`

### 1.2 Design questions

**a) Why pin `ubuntu-24.04` instead of `ubuntu-latest`?**

`ubuntu-latest` is a moving target — GitHub retargets it when a new LTS image ships. A green run today can fail tomorrow because a system package, glibc, or preinstalled tool changed. Pinning `ubuntu-24.04` makes the environment reproducible and makes CI failures attributable to *our* code or config, not a silent runner image upgrade.

**b) Why split vet + test + lint into separate jobs?**

Each job reports its own status (`vet`, `test`, `lint`), so failures are visible at a glance and jobs run in parallel on separate runners. One combined job would serialize the steps, mix failure signals into a single log, and hide which concern (static analysis vs tests vs linter rules) broke first.

**c) What attack does SHA pinning prevent? (Lecture 3 incident)**

Tag-based action references (`@v4`) are mutable — a compromised maintainer account can retag malicious code. In **March 2025**, the **`tj-actions/changed-files`** action was compromised; attackers rewrote tags so CI runs pulled malicious versions and **leaked secrets** from thousands of repositories. Pinning by **40-character commit SHA** makes the resolved source immutable for that workflow revision.

**d) What is `permissions:` and what principle is behind it?**

`permissions:` sets the maximum GitHub token scopes available to the workflow (here `contents: read`). The principle is **least privilege**: the workflow only gets write access to resources it truly needs, limiting blast radius if a step or third-party action is compromised.

**e)** *(GitLab path — N/A; chose GitHub Actions.)*

### 1.5 Failure / fix evidence

| Step | Status | Notes |
|------|--------|-------|
| Deliberate break commit | _TODO after push_ | e.g. wrong expected value in `handlers_test.go` |
| Red CI run link | _TODO_ | |
| Fix / revert commit | _TODO_ | |
| Green CI run link | _TODO_ | |

### 1.6 Branch protection

On fork `selysecr332/DevOps-Intro` → **Settings → Branches → `main`**:

- Require status checks before merging
- Require branches up to date
- **Required check:** `ci-ok` only (matrix renames `vet`/`test` to `vet (1.23)` etc.; aggregation job stays stable)

Screenshot: _TODO — `submissions/screenshots/Lab_3/branch-protection.png`_

### 1.7 Green CI run

Link: _TODO — paste Actions run URL after first green workflow on `feature/lab3`_

---

## Task 2 — Cache, matrix, path filter

### Optimizations applied (description, not YAML)

1. **Module/build cache** — `actions/setup-go` with `cache: true` and `cache-dependency-path: app/go.mod`
2. **Matrix** — vet + test on Go **1.23** and **1.24** in parallel; `fail-fast: false`
3. **Path filter** — workflow runs only when `app/**` or `ci.yml` changes
4. **`GOFLAGS=-buildvcs=false`** — avoids VCS metadata errors in shallow CI clones (bonus-oriented)

### 2.4 Timing table

> QuickNotes has **no third-party modules** (`go.mod` has no `require` block). Expect small deltas between cache on/off — document what you actually measured.

| Scenario | Wall-clock |
|----------|-----------|
| Baseline (no cache, single Go version, no path filter) | _TODO_ s |
| With cache | _TODO_ s |
| With cache + matrix | _TODO_ s |

### 2.5 Design questions

**f) Why cache `go.sum`-keyed inputs and not build outputs?**

Module download inputs are deterministic for a given `go.sum` — the same hashes always resolve to the same module bytes. Build outputs depend on toolchain version, flags, and environment; caching them risks stale or incompatible artifacts. Caching inputs (modules) is safe and portable; caching outputs can hide real rebuild problems.

**g) What does `fail-fast: false` change, and when use `fail-fast: true`?**

With `fail-fast: false`, all matrix cells run even after one fails — you see every broken Go version. With `fail-fast: true` (GH default), the first failing cell cancels siblings, saving minutes but hiding which versions still pass. Use `fail-fast: true` when cells are redundant smoke tests and cost matters; use `false` when diagnosing version-specific failures.

**h) Cache poisoning risk from malicious PRs**

An attacker on a fork PR could try to populate the Actions cache with malicious artifacts that later runs restore. GitHub mitigates this by **restricting cache access to the same branch/PR scope** — caches from pull requests are not available to protected branches like `main`. See [GitHub Docs — Dependency caching restrictions](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows#restrictions-for-accessing-a-cache).

---

## Bonus — Performance (optional)

_Not started — complete after Task 1+2 are green._

---

## Submission — Pull requests

| PR | URL |
|----|-----|
| **Course** (`feature/lab3` → `inno-devops-labs/main`) | _TODO_ |
| **Fork** (`feature/lab3` → `selysecr332/main`) | _TODO_ |

**Moodle:** submit both URLs before the deadline.

---

## Lab 3 completion checklist

### Task 1 (6 pts)

- [x] `.github/workflows/ci.yml` with vet + test + lint
- [x] Pinned runner + action SHAs; `permissions: contents: read`
- [ ] CI green on `feature/lab3`
- [ ] Deliberate failure → blocked → fix → green
- [ ] Branch protection with `ci-ok` required
- [x] Design questions a–d answered

### Task 2 (4 pts)

- [x] Cache, matrix, path filter in workflow
- [ ] Timing table filled from real runs
- [x] Design questions f–h answered

### Submission

- [ ] Course PR opened
- [ ] Fork PR opened
- [ ] Both URLs on Moodle

### Bonus (2 pts)

- [ ] Not attempted
