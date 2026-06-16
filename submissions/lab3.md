# Lab 3 — CI/CD: PR-Gated Pipeline for QuickNotes

**Chosen path:** GitHub Actions
**Why:** I already had a working GitHub fork from Labs 1–2 with SSH-signed commits set up, and full access to github.com, so GitHub Actions was the natural choice.

---

## Task 1 — PR Gate

### Evidence

- **Green CI run:** https://github.com/ivanalpatov2003-design/DevOps-Intro/actions/runs/27615466948 (run #10, all five checks green, 35 s)
  - Screenshot: `submissions/img/green_run.png`
- **Failed run (deliberate breakage):** I changed the expected metric value in `app/handlers_test.go` from `quicknotes_notes_created_total 1` to `... 99`. The `test (1.23)` and `test (1.24)` jobs went red while `vet` and `lint` stayed green, proving the gate catches real failures.
  - Screenshot: `submissions/img/red_run.png`
  - Fix commit: reverted the assertion back to `1`; all five checks green again.
- **Branch protection:** `main` on my fork requires the status checks `vet (1.23)`, `vet (1.24)`, `test (1.23)`, `test (1.24)`, `lint` to pass before merging, and requires branches to be up to date.
  - Screenshot: `submissions/img/branch_protection.png`

### Design questions

**a) Why pin the runner version (`ubuntu-24.04`) instead of `ubuntu-latest`?**
`ubuntu-latest` is a moving target — GitHub repoints it to a new Ubuntu LTS image on their own schedule. When that happens, pre-installed tool versions, system libraries, and default paths can change overnight, so a pipeline that was green yesterday can break today without any change to my code. Pinning `ubuntu-24.04` makes the build environment reproducible: the same inputs produce the same result until *I* decide to bump the version deliberately.

**b) Why split vet + test + lint into separate jobs?**
Each job runs on its own runner in parallel, so the wall-clock time is the slowest single job rather than the sum of all three. Each also reports an independent status check, so when something fails I see immediately *which* of the three broke instead of scrolling one combined log. A single combined job would also stop at the first failing command (e.g. a `vet` failure would mean I never find out whether the tests pass), losing information on every run.

**c) What real attack does SHA pinning prevent?**
The **tj-actions/changed-files** supply-chain compromise (CVE-2025-30066), March 2025. The attacker gained write access and **retroactively moved existing version tags** (v1 through v45.0.7) to point at a malicious commit that dumped the runner's memory and leaked CI/CD secrets into the workflow logs; over 23,000 repositories were affected. The key lesson: a tag like `@v4` is mutable — whoever controls the repo can repoint it. A full 40-character commit SHA is immutable: even if an attacker moves the tag, my workflow keeps using the exact reviewed commit. That is why every third-party action in my `ci.yml` is pinned by SHA with the human-readable tag in a trailing comment.

**d) What is `permissions:` and what's the principle behind it?**
`permissions:` controls the scopes granted to the automatic `GITHUB_TOKEN` that every workflow run receives. The principle is **least privilege**: a CI job that only needs to read the repository to vet/test/lint it should not also be able to push commits, publish packages, or open PRs. I set `permissions: contents: read` at the workflow level, so even if a dependency or action were compromised, the token it could steal can only read this repo — it cannot write to it or reach other resources.

**e) (GitLab path)** — Not applicable; I chose GitHub Actions.

---

## Task 2 — Make It Fast and Smart

### Optimizations applied

1. **Dependency / build caching** via `actions/setup-go` (`cache: true`). Because QuickNotes has **no external dependencies**, there is no `go.sum`; I keyed the cache on `app/go.mod` instead. The run log shows `Cache restored from key: setup-go-Linux-x64-ubuntu24-go-1.24.13-...` and `Cache restored successfully` (~22 MB) on warm runs, confirming caching is active.
   - Screenshot (cache hit): `submissions/img/cache_hit.png`
2. **Build matrix** running `vet` and `test` against Go **1.23** and **1.24** in parallel, with `fail-fast: false` so a failure in one toolchain version does not cancel the other cell.
3. **Path filter** (`on.*.paths`) so the pipeline runs only when something under `app/**` or the workflow file itself changes — README-only PRs no longer burn CI minutes.

### Timing table

| Scenario | Wall-clock |
|----------|-----------|
| Baseline (no cache, single Go 1.24, no path filter) | ~35 s |
| With cache (single Go 1.24) | ~37 s |
| With cache + matrix (Go 1.23 + 1.24) | ~40–44 s |

> Note: each scenario was measured once (not a 3–5 run median) due to time constraints. Numbers are dominated by runner startup and Go install; the actual vet/test/lint work is only ~15 s per job. Caching gave no net speed-up here because the project has **zero external modules** — there is simply nothing for the module cache to restore (see question f). The matrix adds wall-clock because it introduces extra parallel cells, but it is a correctness investment, not a speed one.

### Design questions

**f) Why cache `go.sum`-keyed inputs and not build outputs?**
Inputs pinned by `go.sum` (the exact module versions + their checksums) are **deterministic**: the same `go.sum` always maps to the same downloaded modules, so the cache key is stable and a hit is always safe to reuse. Build *outputs* depend on the toolchain version, build flags, OS, and environment, and can vary subtly between runs — caching them risks serving a stale or environment-mismatched artifact. So you key the cache on the deterministic input and let the deterministic build regenerate outputs. (In my case there is no `go.sum` at all, so I key on `go.mod`, which is the closest deterministic input available.)

**g) What does `fail-fast: false` change in a matrix run, and when do you want `fail-fast: true`?**
With `fail-fast: true` (the GitHub default), the moment one matrix cell fails, GitHub cancels all the other in-progress cells. That hides information: if `test (1.23)` fails you never learn whether `test (1.24)` would also have failed. `fail-fast: false` lets every cell run to completion so you can see exactly which version/combination broke — which is what you want while diagnosing a cross-version bug. You'd switch back to `fail-fast: true` when matrix cells are expensive (lots of cells / long-running) and you only care that *everything* passes — failing fast then saves CI minutes and gives quicker feedback.

**h) What's the risk of an attacker writing a cache from a malicious PR that protected branches later read?**
A PR from a fork or untrusted contributor could run a workflow that writes a poisoned entry into the shared Actions cache (e.g. a tampered module or build artifact). If a later run on a protected branch restores that same cache key, it would silently execute the attacker's content with the protected branch's privileges — a cache-poisoning attack. GitHub mitigates this with **cache scope isolation**: caches created by a PR/branch are restricted in scope, and base/protected branches do not read caches written by feature branches across the isolation boundary. Official guidance: GitHub Docs — "Caching dependencies to speed up workflows" (cache scope restrictions section).

---

## Bonus — Pipeline Performance Investigation

### Profile (per-step, from the CI UI)

For a typical job (`vet (1.24)`):
- Runner **start** ("Set up job"): ~1–2 s
- **Dependency setup** (`actions/setup-go`, Go install + cache restore): ~2–6 s (6 s on a cache-restore run, includes downloading the ~22 MB cache)
- **Actual work** (`go vet` / `go test` / `golangci-lint`): ~10–15 s
- **Cleanup / Post steps**: ~1 s

The dominant remaining cost is **runner startup + Go toolchain setup**, not the analysis work itself.

### Optimizations applied (≥ 3)

1. **`GOFLAGS=-buildvcs=false`** (workflow-level `env`) — skips embedding VCS/git stamping into the build, which CI doesn't need and which can be slow with a limited git history.
2. **`fetch-depth: 1`** on `actions/checkout` — shallow clone, fetching only the latest commit instead of the full history.
3. **Dropped the redundant `actions/setup-go` step in the `lint` job** — `golangci-lint-action` installs and manages its own Go, so a separate setup-go step was duplicated work.

### Before / after

| Optimization applied | Before (s) | After (s) | Saving |
|----------------------|-----------:|----------:|-------:|
| `GOFLAGS=-buildvcs=false` + shallow clone + lint setup-go removed (combined) | 40 | 35 | −5 |
| **Total wall-clock** | **40** | **35** | **−5** |

> The three optimizations were applied and measured together; on a project this small their individual contributions are within runner-noise of each other, so I report the combined effect (~12% faster).

### Bottleneck analysis

The single step that dominates the remaining time is **runner startup plus Go toolchain setup** — provisioning a fresh `ubuntu-24.04` VM and installing Go takes longer than the vet/test/lint work itself, which is only ~10–15 s. To make the pipeline meaningfully shorter I would have to change QuickNotes itself, not the pipeline: the work is already trivial, so there's almost nothing left to trim on the analysis side. A realistic remaining lever would be a smaller/pre-warmed base image or a self-hosted runner with Go pre-installed, removing the toolchain-install cost. My team would **stop optimizing at this point** (~35 s): the pipeline is already well under any threshold where it disrupts the dev loop, and further engineering effort (self-hosted runners, custom images) would cost more maintenance time than it saves in CI wall-clock. The 90 s target was comfortably beaten.

---

## Summary of files

- `.github/workflows/ci.yml` — the CI pipeline (vet, test, lint; pinned runner + SHA-pinned actions; cache; matrix; path filter; bonus optimizations)
- `submissions/lab3.md` — this document
- `submissions/img/` — screenshots (green run, failed run, branch protection, cache hit)
