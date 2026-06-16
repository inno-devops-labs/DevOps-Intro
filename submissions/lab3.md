# Lab 3 — CI/CD: PR-Gated Pipeline for QuickNotes

    Mahmoud Hassan (`selysecr332`)  
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
| Deliberate break commit | ✅ Done | `2bc342a` on `feature/lab3-fork` and `d1c82e4` on `feature/lab3` (changed expected 404 -> 200 in `TestGetNote_NotFound`) |
| Red CI run link | ✅ Done | PR checks page: <https://github.com/selysecr332/DevOps-Intro/pull/3/checks> (failed checks at commit `2bc342a`) |
| Fix / revert commit | ✅ Done | `84c0006` on `feature/lab3-fork` and `0273db1` on `feature/lab3` |
| Green CI run link | ✅ Done | PR checks page: <https://github.com/selysecr332/DevOps-Intro/pull/3/checks> (all checks passed at commit `84c0006`) |

**Red run (commit `2bc342a`):**

![CI failed — deliberate break](screenshots/lab_3/cl_red.png)

**Green run (commit `84c0006`):**

![CI recovered after fix](screenshots/lab_3/cl_green.png)

### 1.6 Branch protection

On fork `selysecr332/DevOps-Intro` → **Settings → Branches → `main`**:

- Require status checks before merging
- Require branches up to date
- **Required check:** `ci-ok` only (matrix renames `vet`/`test` to `vet (1.23)` etc.; aggregation job stays stable)

Branch protection rule created for `main` (Settings → Branches).

![Branch protection rule for main](screenshots/lab_3/branch-protection.png)

### 1.7 Green CI run

- Fork PR green checks: <https://github.com/selysecr332/DevOps-Intro/pull/3/checks>
- Course PR: <https://github.com/inno-devops-labs/DevOps-Intro/pull/1049>

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
| Baseline (no cache, single Go version, no path filter) | 47 s |
| With cache | 41 s |
| With cache + matrix | 54 s |

Measured from fork Actions runs on `feature/lab3-fork`:
- Baseline run: `27618105353`
- Cache-only run: `27620629290`
- Cache+matrix run: `27620789400`

### 2.5 Design questions

**f) Why cache `go.sum`-keyed inputs and not build outputs?**

Module download inputs are deterministic for a given `go.sum` — the same hashes always resolve to the same module bytes. Build outputs depend on toolchain version, flags, and environment; caching them risks stale or incompatible artifacts. Caching inputs (modules) is safe and portable; caching outputs can hide real rebuild problems.

**g) What does `fail-fast: false` change, and when use `fail-fast: true`?**

With `fail-fast: false`, all matrix cells run even after one fails — you see every broken Go version. With `fail-fast: true` (GH default), the first failing cell cancels siblings, saving minutes but hiding which versions still pass. Use `fail-fast: true` when cells are redundant smoke tests and cost matters; use `false` when diagnosing version-specific failures.

**h) Cache poisoning risk from malicious PRs**

An attacker on a fork PR could try to populate the Actions cache with malicious artifacts that later runs restore. GitHub mitigates this by **restricting cache access to the same branch/PR scope** — caches from pull requests are not available to protected branches like `main`. See [GitHub Docs — Dependency caching restrictions](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows#restrictions-for-accessing-a-cache).

---

## Bonus — Performance investigation

**Goal:** pipeline ≤ 90 s wall-clock (achieved: **54–59 s** measured).

### B.1 Profile (pre-bonus run `27620789400`)

| Phase | Dominant cost | Observed |
|-------|---------------|----------|
| Runner start | Queue + VM boot | ~3–8 s before first step |
| Dependency setup | `setup-go` toolchain download | ~5–10 s per vet/test job |
| Actual work | `go test -race` | **test (1.24): 28 s** (slowest job) |
| Actual work | `golangci-lint` | lint: **25 s** |
| Cleanup | `ci-ok` aggregation | ~3–5 s |

Runner provisioning and `go test -race` dominate; QuickNotes has no module deps so cache gains are small.

### B.2 Optimizations applied (beyond Task 2)

1. **Shallow clone** — `fetch-depth: 1` on vet/test/lint checkouts
2. **golangci-lint cache** — `cache: true` on `golangci-lint-action`
3. **Skip lint on app docs-only** — `dorny/paths-filter` skips lint when only `app/**/*.md` changed (still runs for `.go` or workflow edits)
4. **Concurrency** — `cancel-in-progress` avoids stacked runs on rapid pushes

### B.3 Before/after

| Optimization applied | Before (s) | After (s) | Saving |
|----------------------|----------:|----------:|-------:|
| Shallow clone (`fetch-depth: 1`) | 54 (total) | 54 (within runner variance) | ~0–2 s (noise) |
| golangci-lint cache | 25 (lint job) | 22 (lint job) | **-3 s** |
| Skip lint on app docs-only | 22 (lint job runs) | 0 (skipped on docs-only PR) | **-22 s** when applicable |
| **Total wall-clock** | **54** | **59** | +5 s* |

\*Adding the `changes` paths-filter job costs ~8 s on code PRs; docs-only PRs net faster. Both totals are **under the 90 s target**.

Runs: before `27620789400`, after `27623189289`.

### B.4 Bottleneck analysis

The slowest step after optimization is still **`go test -race`** in the test matrix (~27–29 s per cell), not vet or lint. Runner startup and Go toolchain setup are the next-largest fixed costs because QuickNotes has zero third-party modules — there is nothing meaningful for the module cache to save. To shrink test time further you would need to change QuickNotes itself: fewer/slimmer tests, split unit vs integration suites, or drop `-race` on a fast PR gate and keep race detection on a nightly job. I would stop optimizing this pipeline around **60–90 s** for a small stdlib-only app; below that returns diminish and YAML complexity (extra filter jobs, conditional graphs) costs more than it saves for a team of this size.

---

## Submission — Pull requests

| PR | URL |
|----|-----|
| **Course** (`feature/lab3` → `inno-devops-labs/main`) | <https://github.com/inno-devops-labs/DevOps-Intro/pull/1049> |
| **Fork** (`feature/lab3-fork` → `selysecr332/main`) | <https://github.com/selysecr332/DevOps-Intro/pull/3> |


---

## Lab 3 completion checklist

### Task 1 (6 pts)

- [x] `.github/workflows/ci.yml` with vet + test + lint
- [x] Pinned runner + action SHAs; `permissions: contents: read`
- [x] CI green on fork PR (`#3`)
- [x] Deliberate failure → blocked → fix → green (screenshots in `screenshots/lab_3/cl_red.png` and `cl_green.png`)
- [x] Branch protection with `ci-ok` required (rule created for `main`)
- [x] Design questions a–d answered

### Task 2 (4 pts)

- [x] Cache, matrix, path filter in workflow
- [x] Timing table filled from real runs
- [x] Design questions f–h answered

### Submission

- [x] Course PR opened (`#1049`)
- [x] Fork PR opened (`#3`)
- [ ] Both URLs on Moodle

### Bonus (2 pts)

- [x] ≥ 3 optimizations beyond Task 2
- [x] Before/after timing table
- [x] Bottleneck analysis
- [x] Target ≤ 90 s met (54–59 s measured)
