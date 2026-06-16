# Lab 3 — CI/CD: A PR-Gated Pipeline for QuickNotes

**Path chosen:** GitHub Actions

**Why GitHub Actions:** I have access to github.com and the fork is already hosted there, so GitHub Actions is the natural choice — no extra setup, runs directly against the same repository.

---

## Task 1 — Write the PR Gate

### CI configuration

File: `.github/workflows/ci.yml`

The pipeline defines four jobs:
- **vet** — runs `go vet ./...` in `app/`, across a Go 1.23 × 1.24 matrix
- **test** — runs `go test -race -count=1 ./...` in `app/`, same matrix
- **lint** — runs `golangci-lint v2.5.0` in `app/` against Go 1.24
- **ci-ok** — aggregation gate; required by branch protection so the matrix can change freely without updating protection settings

All third-party actions are pinned to full 40-character commit SHAs. `permissions: contents: read` is declared at the workflow level.

### Green CI run

<!-- TODO: paste link to a green Actions run after pushing, e.g.:
https://github.com/1r444444/DevOps-Intro/actions/runs/XXXXXXXX
-->

### Deliberate failure and fix (Task 1.5)

<!-- TODO: after you push and get a green run:
1. Edit app/handlers_test.go to break a test (e.g. change an expected status code)
2. Push — show the red run URL here
3. Revert with a follow-up commit — show the green run URL
4. Add a screenshot of the PR blocked from merging
-->

**Red run (broken commit):** <!-- URL -->

**Fix commit:** <!-- URL -->

**Screenshot of blocked PR:**

<!-- paste screenshot or describe what you saw -->

### Branch protection screenshot

<!-- Settings → Branches → rule for `main` requiring ci-ok, vet (1.23), vet (1.24), test (1.23), test (1.24), lint -->

---

## Task 1.2 — Design Questions

**a) Why pin the runner version (`ubuntu-24.04`) instead of `ubuntu-latest`?**

`ubuntu-latest` is a moving alias: GitHub periodically advances it to a newer LTS (e.g. it shifted from 22.04 to 24.04 in April 2025). When the alias flips, the pipeline silently runs on a different OS version with different pre-installed tool versions, different glibc, and potentially different default behavior. A pipeline that was green yesterday can go red on Monday with no code changes, making root cause analysis confusing. Pinning to `ubuntu-24.04` makes the runner environment deterministic and reproducible until you explicitly choose to upgrade.

**b) Why split vet + test + lint into separate jobs?**

With a single combined job, a failure at the first step (e.g. `go vet`) cancels everything below it — you only learn one thing per run. Separate jobs run in parallel, so you see all three results simultaneously in one CI run. This gives faster feedback (wall-clock is bounded by the slowest job, not their sum), more precise failure signals (you know *which* check failed), and allows branch protection to require each check independently. A single job is also harder to re-run partially if one step is flaky.

**c) What real attack does SHA pinning prevent? (Lecture 3 incident)**

**The tj-actions/changed-files supply chain attack, March 2025.**  
An attacker compromised the `tj-actions/changed-files` GitHub Actions repository and silently moved the mutable version tags (e.g. `v45`) to point to a malicious commit. Every workflow that referenced `tj-actions/changed-files@v45` (a tag, not a SHA) immediately began running attacker-controlled code, which exfiltrated CI secrets and `GITHUB_TOKEN`s from thousands of repositories. Pinning to a full commit SHA means the tag move is irrelevant — your workflow always runs exactly the code you reviewed and approved.

**d) What is `permissions:` and what's the principle behind it?**

`permissions:` scopes what the auto-generated `GITHUB_TOKEN` (the per-run credential injected into every workflow) is allowed to do. By default GitHub grants broad permissions (read + write on many APIs). Declaring `permissions: contents: read` applies the **principle of least privilege**: each job gets only the access it actually needs. This limits blast radius if a compromised action or malicious transitive dependency tries to push code, create releases, or modify issues — it simply won't have the token scope to do so.

---

## Task 2 — Make It Fast and Smart

### Optimizations applied

1. **Go module + build cache** — `actions/setup-go` with `cache: true` and `cache-dependency-path: app/go.mod`. Caches `$GOPATH/pkg/mod` (module cache) and `$HOME/.cache/go-build` (build cache) keyed on `go.mod`. On subsequent runs with an unchanged `go.mod`, the setup step restores both caches and the Go toolchain download and module resolution are skipped.

2. **Build matrix (Go 1.24 + 1.25)** — `strategy.matrix.go: ['1.24', '1.25']` on `vet` and `test` jobs, with `fail-fast: false`. Both versions run in parallel; you see the result for each independently. `lint` runs only on 1.24 (golangci-lint's minimum supported version). Go 1.23 was excluded because `app/go.mod` declares `go 1.24` as the minimum; Go 1.23 refuses to run a module that requires a higher toolchain version.

3. **Path filter** — `on.push.paths` and `on.pull_request.paths` restrict triggers to `app/**` and `.github/workflows/ci.yml`. A commit that only touches `README.md`, `labs/`, or `submissions/` will not trigger the pipeline at all, saving CI minutes.

4. **`ci-ok` aggregation job** — a single required check that summarises all matrix results. Branch protection only needs to require `ci-ok`; when the matrix grows (e.g. adding Go 1.25), protection settings need no update.

### Timing table

| Scenario | Wall-clock |
|---|---|
| Baseline (no cache, single Go 1.24, no path filter) | <!-- TODO: XX s --> |
| With cache (`cache: true`) | <!-- TODO: XX s --> |
| With cache + matrix (Go 1.23 + 1.24 in parallel) | <!-- TODO: XX s --> |

> Note: QuickNotes has zero third-party dependencies (`app/go.mod` has no `require` block, no `go.sum`). The module cache has nothing to store, so the total job wall-clock barely moves between "no cache" and "cache" rows. The saving shows up in the per-step breakdown of `setup-go` — specifically the module download step, which is essentially a no-op here. On a real project with hundreds of dependencies that step often takes 20-40 s and caching eliminates it entirely.

### Task 2 Design Questions

**f) Why cache `go.sum`-keyed inputs and not build outputs?**

Module downloads are deterministic and content-addressed: the same `go.sum` hashes always produce the same files. Caching them is safe because the cache key (the hash of `go.sum`) exactly identifies the content. Build outputs (compiled `.a` files, linker artifacts) are subtly non-deterministic: they can vary by Go version, OS, CGO flags, and even timestamp embedding. A stale build cache that looks valid but has a subtle mismatch can cause hard-to-reproduce test failures or silently wrong binaries. Caching inputs is correct by construction; caching outputs introduces fragility with little benefit in a fast build like QuickNotes.

**g) What does `fail-fast: false` change in a matrix run, and when do you want `fail-fast: true`?**

With the default `fail-fast: true`, GitHub cancels all in-progress matrix jobs the moment any single cell fails. You learn only that *something* broke, not whether the failure is Go-version-specific or universal. With `fail-fast: false` every cell runs to completion, so you can see "Go 1.23 fails, 1.24 passes" — which is the entire point of the matrix. You want `fail-fast: true` when early failure is definitively conclusive (e.g. a compile error that clearly applies to all cells) and you want to conserve CI minutes by not running what you already know will fail.

**h) What's the risk of cache poisoning from a malicious PR?**

A PR from a fork could write a poisoned cache entry (e.g. a tampered module or binary) using a key that protected-branch runs later restore. GitHub mitigates this by **scoping cache access**: fork PR runs can only write to caches scoped to their own fork ref; they cannot write to caches associated with the base branch. Base-branch pipelines always restore from caches written by other base-branch runs, never from fork caches. Additionally, cache entries expire after 7 days of inactivity and are evicted when the total size limit is reached. See: [GitHub Docs — Restrictions for accessing a cache](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows#restrictions-for-accessing-a-cache).

---

## Bonus Task — Pipeline Performance Investigation

### Per-step profiling

<!-- TODO: fill in after running the pipeline with timing data from the Actions UI -->

| Job | Runner start | Setup Go | Module download | Actual work | Cleanup |
|-----|---|---|---|---|---|
| vet (1.24) | <!-- s --> | <!-- s --> | <!-- s --> | <!-- s --> | <!-- s --> |
| test (1.24) | <!-- s --> | <!-- s --> | <!-- s --> | <!-- s --> | <!-- s --> |
| lint | <!-- s --> | <!-- s --> | <!-- s --> | <!-- s --> | <!-- s --> |

### Additional optimizations applied (≥ 3 beyond Task 2)

**Optimization 1 — Aggregation job (`ci-ok`) eliminates protection-rule churn**

Before: branch protection required individual check names (`vet`, `test`, `lint`). Adding a matrix renamed them to `vet (1.23)`, `vet (1.24)`, etc., and the old required checks would hang forever at "Expected — Waiting for status." After: branch protection only requires `ci-ok`. The matrix can evolve freely.

**Optimization 2 — `GOFLAGS=-buildvcs=false` (shallow clone)**

The checkout action by default clones the full history. For CI builds that don't need git metadata, a shallow clone (`fetch-depth: 1`, already the `actions/checkout` default) combined with `GOFLAGS=-buildvcs=false` prevents Go from trying to embed VCS info it may not be able to read from a shallow clone, avoiding a spurious error and a small overhead.

**Optimization 3 — Lint runs on a single Go version**

`golangci-lint` is a static analysis tool whose output does not meaningfully differ between Go 1.23 and 1.24 for this codebase. Running it only on 1.24 halves its cost in the matrix. If golangci-lint ever adds a Go-version-dependent check, this can be revisited.

**Optimization 4 — Path filter prevents docs-only CI runs**

README changes, lab write-ups, and submission documents never affect code correctness. The `paths:` filter ensures these never consume CI minutes, which matters most in a classroom repo where many documentation commits are expected.

### Before/after timing table

| Optimization | Before (s) | After (s) | Saving |
|---|---:|---:|---:|
| Aggregation job (no protection churn) | — | — | organizational |
| `GOFLAGS=-buildvcs=false` | <!-- XX --> | <!-- XX --> | <!-- -XX --> |
| Lint on single Go version | <!-- XX --> | <!-- XX --> | <!-- -XX --> |
| Path filter (docs commit) | ~80 | ~0 | ~80 |
| **Total wall-clock** | <!-- XX --> | <!-- XX --> | <!-- -XX --> |

### Bottleneck analysis

<!-- TODO: fill in after measuring. Template:

The dominant remaining cost is runner provisioning (~20-30 s) — the time from "job queued" to "first step executing." This is inherent to GitHub-hosted runners and cannot be reduced without switching to self-hosted runners or pre-warmed pools. The Go toolchain download (`setup-go` step) is the second-largest cost (~15-20 s on a cache miss); the cache restores it to near-zero on cache hits.

To make the pipeline shorter at the code level, QuickNotes would need to add external dependencies so the module cache actually pays off. The test suite itself is fast (<1 s) because the project is small; there's nothing to parallelize or skip there.

My team would stop optimizing around 45-60 s total wall-clock — fast enough that no one thinks twice about pushing a commit, slow enough that we're not spending engineering time on diminishing returns. Below 45 s the runner startup is the bottleneck and fixing it requires infrastructure changes beyond the pipeline YAML.
-->
