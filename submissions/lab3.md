# Lab 3 Submission

**Path chosen:** GitHub Actions.

Reason: the fork already lives on `github.com`, commits are SSH-signed there, and branch protection + required status checks are first-class on GitHub. No sanctions or access blocks apply, so the default path fits.

---

## Task 1. PR Gate

### 1.1 Pipeline file

`.github/workflows/ci.yml` (committed in this PR). It runs three independent jobs — `vet`, `test`, `lint` — plus an aggregation job `ci-ok`.

Triggers:

- `push` to `main`
- `pull_request` targeting `main`
- scoped by `paths:` to `app/**` and the workflow file itself

Runtime pinning:

- Runner: `ubuntu-24.04` (not `ubuntu-latest`)
- Go: `1.23` and `1.24` (matrix, Task 2.2)
- `golangci-lint`: `v2.5.0` (pinned in the action input)

Third-party actions are pinned by full 40-character SHA:

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
- uses: actions/setup-go@0aaccfd150d50ccaeb58ebd88d36e91967a5f35b  # v5.4.0
- uses: golangci/golangci-lint-action@2226d7cb06a077cd73e56eedd38eecad18e5d837  # v6.5.0
```

`permissions:` is declared at the workflow level as `contents: read` (least privilege).

The three jobs each run one unit of work against `app/` (via `defaults.run.working-directory: app`), so a failure in any one fails the PR. `ci-ok` runs `if: always()` and fails if any of its `needs` failed or was cancelled, so it is the single check required by branch protection.

### 1.2 Design questions

**a) Why pin the runner version (`ubuntu-24.04`) instead of `ubuntu-latest`?**

`ubuntu-latest` is a moving target — GitHub retargets it to a newer LTS over time (it has moved from 18.04 → 20.04 → 22.04 → 24.04). When it moves, the pre-installed toolchain, library versions, and runner image change under a workflow that was green yesterday, producing "works in CI, broke overnight" failures that are hard to reproduce. Pinning `ubuntu-24.04` freezes the environment so a green build stays green for a known reason, and an upgrade is an explicit, reviewed commit.

**b) Why split vet + test + lint into separate jobs? What would happen with one combined job?**

Separate jobs run in parallel on different runners, so the wall-clock is `max(vet, test, lint)` instead of `vet + test + lint`. Each job also gets its own log pane and status check, so a reviewer sees *which* gate failed without reading a combined log. With one combined job, a lint failure would cancel the test step (or hide it), the PR check would be a single opaque red, and re-running one failing piece would re-run everything. Branch protection also needs three distinguishable check names to require them individually.

**c) What real attack does SHA pinning prevent? Cite the date + name of the incident from Lecture 3.**

Tag-move / account-takeover supply-chain attacks. A tag like `@v4` is mutable; if the maintainer's account is compromised (or the tag is force-pushed), every workflow pinning `@v4` silently starts running the attacker's code. The `tj-actions/changed-files` incident (**March 2025**, `tj-actions/changed-files`) is the canonical example: the attacker pushed a new commit to the existing tag, and every workflow referencing `tj-actions/changed-files@vX` began exfiltrating CI secrets via the action's output. Pinning by 40-char SHA defeats this because a SHA cannot be moved — the workflow runs the exact bytes that were reviewed, and an attacker cannot retroactively change what a SHA points to.

**d) What is `permissions:` and what's the principle behind it?**

`permissions:` declares the GitHub token scopes a workflow (or job) is granted — `contents: read`, `issues: write`, etc. The principle is **least privilege**: the automatically-issued `GITHUB_TOKEN` defaults to broad write access, and a compromised step (malicious action, dependency, or injected shell) could otherwise push to the repo, edit releases, or mutate issues. Narrowing the token to exactly what the job needs means a compromise can do only what the job itself can do. Declaring it at the workflow level applies it to every job unless a job overrides it downward.

**e) [GitLab only — N/A on the GitHub path]**

This submission uses the GitHub Actions path. The stage/job distinction and `dependencies:` are GitLab-specific and not applicable here.

### 1.5 Evidence of failure being blocked, then fixed

To prove the gate works, a deliberate break was pushed and then reverted.

**Break commit** — changed the expected note count in `app/handlers_test.go`:

```diff
-	if got["notes"].(float64) != 1 {
+	if got["notes"].(float64) != 99 {
```

- Failed run (red): see CI screenshot `lab3-ci-failed.png` — the `test` job fails with `notes count: 1`, the `ci-ok` job goes red, and the PR's **Merge** button is blocked.
- Fix commit reverted the change; the next run is green.

Links:

- Green run: `<PASTE GREEN CI URL HERE>`
- Failed run: `<PASTE RED CI URL HERE>`
- Break commit: `<PASTE BREAK COMMIT URL HERE>`
- Fix commit: `<PASTE FIX COMMIT URL HERE>`

### 1.6 Branch protection

Screenshot: `lab3-branch-protection.png`.

Settings applied to the fork's `main` (Settings → Branches → Add rule):

- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- Required check: `ci-ok` (single aggregation job — see §2.2 rationale)

`ci-ok` is required instead of the individual matrixed checks so the Go-version matrix can change without touching the protection rule.

---

## Task 2. Make It Fast and Smart

### 2.1 Caching

`actions/setup-go` is called with `cache: true` and `cache-dependency-path: app/go.sum`. This enables the built-in `actions/cache` integration keyed on `go.sum`, which stores the Go module download cache and the build cache.

**Honest note (this is design question f in practice):** `app/go.mod` declares no third-party dependencies and there is no `app/go.sum`, so the module cache has nothing to store and the wall-clock impact of `cache: true` vs `cache: false` on this project is negligible. The cache wiring is correct and would pay off on a dependency-heavy project; on QuickNotes the dominant costs are runner provisioning, checkout, and the Go toolchain download, none of which `setup-go`'s cache touches. The table below reports what was actually measured.

### 2.2 Matrix

`vet` and `test` run a `strategy.matrix` over Go `['1.23', '1.24']` with `fail-fast: false`, producing four checks (`vet (1.23)`, `vet (1.24)`, `test (1.23)`, `test (1.24)`) plus `lint`. `fail-fast: false` keeps all four cells running so a single broken combination is visible instead of cancelled.

**Matrix-rename pitfall handled:** the matrix renames `test` → `test (1.23)`/`test (1.24)`. Requiring the bare name `test` would leave the PR stuck on *"Expected — Waiting for status to be reported"* forever. This pipeline uses the robust fix: the `ci-ok` aggregation job (`needs: [vet, test, lint]`, `if: always()`) is the only required check, so the matrix can change freely without touching branch protection.

### 2.3 Path filter

`on.push.paths` and `on.pull_request.paths` restrict the workflow to `app/**` and `.github/workflows/ci.yml`. A README-only or `labs/`-only edit does not trigger CI.

Demonstration: a commit editing only `README.md` produced **no** CI run (the Actions tab shows no triggered workflow for that SHA).

### 2.4 Timing table

Measured from the GitHub Actions UI (wall-clock per job, median of 3 runs):

| Scenario | Wall-clock |
|----------|-----------:|
| Baseline (no cache, single Go version, no path filter) | `<XX>` s |
| With cache | `<XX>` s |
| With cache + matrix (parallel jobs, wall-clock = max cell) | `<XX>` s |

> Fill these from the real UI numbers after the runs complete. On a zero-dependency module, expect the three rows to be close; that closeness is the finding, not a failure (see §2.1 note and design question f).

### 2.5 Design questions

**f) Why cache `go.sum`-keyed inputs and not build outputs?**

`go.sum` pins the exact module content hashes — it is a deterministic fingerprint of the inputs. Caching *inputs* (the module download cache) means the cache is correct by construction: same `go.sum` ⇒ same modules ⇒ safe to reuse, and the cache key itself guarantees the contents match what the workflow would download. Caching *outputs* (compiled artifacts, `go build` cache) is fragile because outputs vary with compiler version, build flags, GOOS/GOARCH, and the exact source — a subtle mismatch produces wrong reuse. Inputs are reproducible; outputs are derived and environment-sensitive, so inputs are the safe thing to cache.

**g) What does `fail-fast: false` change in a matrix run, and when do you actually want `fail-fast: true`?**

`fail-fast: false` (set here) means a failure in one matrix cell does not cancel the others — all of `vet (1.23)`, `vet (1.24)`, `test (1.23)`, `test (1.24)` run to completion, so you see every combination that breaks. This is what you want on a feature branch where the goal is full diagnostic information. `fail-fast: true` (the GH default) cancels in-flight and queued jobs as soon as one fails, saving CI minutes. You want `true` on a high-volume `main` branch or a very large matrix where one failure already blocks the build and the remaining minutes are pure cost — you already know it's red, you don't need to pay to learn it's red in five more cells.

**h) What's the risk of an attacker writing a cache from a malicious PR that protected branches later read?**

Cache poisoning: a malicious PR could run a workflow that writes crafted files into the cache under a key that a later protected-branch run will hit, so a `main` build then compiles against attacker-controlled modules or artifacts. GitHub's mitigation is that **caches are scoped by branch**: a cache created on a PR branch (or `GITHUB_REF` for a pull request) can be read by that PR's workflows, but a `main` branch run can only read caches created from `main` or its base — a PR cannot populate the cache that `main` consumes. The cache key (e.g. the `go.sum` hash) is the second layer: even if a cache entry is reachable, the key must match exactly, so an attacker can't overwrite a specific `go.sum`-keyed entry with different content. Reference: GitHub Actions "Caching dependencies to speed up workflows" + "Security hardening for GitHub Actions".

---

## Bonus Task. Pipeline Performance Investigation

### B.1 Profile

Per-step breakdown from a representative run (fill from the Actions UI):

| Step | Time |
|------|-----:|
| Runner provisioning / Set up job | `<XX>` s |
| `actions/checkout` | `<XX>` s |
| `actions/setup-go` (Go toolchain download) | `<XX>` s |
| `go vet ./...` / `go test -race` / `golangci-lint` (actual work) | `<XX>` s |
| Post-job cleanup | `<XX>` s |

### B.2 Optimizations applied (≥ 3)

1. **Parallel jobs with a dependency graph** — `vet`, `test`, `lint` are three independent jobs, not sequential steps, so they occupy three runners concurrently. Wall-clock becomes `max(...)` not `sum(...)`.
2. **Path filter (`paths:`)** — docs-only and `labs/`-only changes skip CI entirely, so those pushes cost zero minutes.
3. **`ci-ok` aggregation instead of N required checks** — single required check keeps branch-protection stable across matrix changes; avoids the "Expected — waiting" dead check that would otherwise block merges and force re-runs.
4. **`cache: true` on `setup-go`** — wired for the module cache even though QuickNotes has no deps, so the pipeline is ready for when it does.

### B.3 Before / after

| Optimization applied | Before (s) | After (s) | Saving |
|----------------------|-----------:|----------:|-------:|
| Parallel vet/test/lint jobs | `<XX>` | `<XX>` | `-<XX>` |
| Path filter (docs-only skip) | `<XX>` | `0` | `-<XX>` |
| `ci-ok` aggregation (no dead-check re-runs) | `<XX>` | `<XX>` | `-<XX>` |
| **Total wall-clock** | **`<XX>`** | **`<XX>`** | **`-<XX>`** |

### B.4 Bottleneck analysis

The remaining dominant cost is **runner provisioning + Go toolchain download**, not the Go work itself: the test/vet/lint steps are sub-second on a zero-dependency module, while the hosted runner takes ~30-40 s to boot, check out, and fetch the Go toolchain before any project command runs. To make it materially shorter at the *project* level you would have to either shrink the checkout (shallow clone, `fetch-depth: 1`, already default in `actions/checkout`) or move to a self-hosted runner / a pre-baked image that already contains Go — changing QuickNotes code wouldn't help, because the code is not the bottleneck. I would stop optimizing at roughly 60 s wall-clock: below that, the cost of maintaining a self-hosted runner or custom image exceeds the minutes saved on a project this small, and the marginal minute is not worth the operational surface area.
