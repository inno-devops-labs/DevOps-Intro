# Lab 3 — CI/CD: A PR-Gated Pipeline for QuickNotes

I went with **GitHub Actions** (the default). My fork and the course repo both
live on GitHub, and the SHA-pinning and `permissions:` parts of the task are
GitHub-native, so it was the natural choice. The pipeline lives in
[`.github/workflows/ci.yml`](../.github/workflows/ci.yml).

Links:
- Green CI run: https://github.com/RoukayaZaki/DevOps-Intro/actions/runs/27637683899
- Failing run (the gate doing its job): https://github.com/RoukayaZaki/DevOps-Intro/actions/runs/27637601845
- PR used to test the gate: https://github.com/RoukayaZaki/DevOps-Intro/pull/3

## Task 1 — The PR Gate

### 1.2 Design questions

a) Why pin `ubuntu-24.04` instead of `ubuntu-latest`?
`ubuntu-latest` is a moving alias as GitHub re-points it to the next LTS on their
own schedule . When that flips, the pre-installed toolchain,
default package versions, and even the kernel change *underneath an unchanged
workflow*. A pipeline that was green yesterday goes red today with no commit of
yours to blame, and the failure is non-reproducible because you can't pin "what
latest meant last week." Pinning `ubuntu-24.04` makes the runner a fixed,
auditable input: upgrades become an explicit, reviewable PR instead of a
surprise.

b) Why split vet + test + lint into separate units?
Three reasons:

- Parallelism: independent jobs run on separate runners
concurrently, so total time ≈ the slowest unit instead of the sum.
- Signal: a red x next to `lint` tells you what broke while a single combined job
forces you to read logs to find out which phase failed, and bails at the first
failure so you never learn whether the other checks would also have failed.


c) What attack does SHA pinning prevent? (incident name + date)
A tag-hijack / supply-chain attack. A Git tag like `@v4` is mutable — whoever
controls the action's repo can force-push the tag to point at malicious code, and
every workflow referencing the tag silently pulls it on the next run. The
concrete incident is the `tj-actions/changed-files` compromise of March 2025:
the action's tags were rewritten to point at a commit that dumped CI secrets
(memory-scraped credentials) into the build logs of every consumer. Pinning to a
full 40-char commit SHA defeats this: a SHA is immutable content-addressing, so
even if the tag is moved, your workflow keeps running the exact reviewed commit.

d) What is `permissions:` and what principle does it embody?
`permissions:` sets the scopes of the automatic `GITHUB_TOKEN` that GitHub mints
for the run. Left unset, repos can grant a broad read/write token; an injected or
compromised step could then push commits, open releases, or comment as the repo.
Declaring `permissions: { contents: read }` is the principle of least
privilege — grant only what the job demonstrably needs (here: read the code),
nothing more. If a step is later compromised, the blast radius is limited to what
that minimal token allows.

### 1.5 Proving the gate blocks a bad PR

I broke a test on purpose: in [`app/handlers_test.go`](../app/handlers_test.go)
I changed the expected status in `TestCreateNote_RejectsEmptyTitle` from
`http.StatusBadRequest` to `http.StatusOK`, committed it, and pushed.

What happened:
- The `test` checks went red on both Go versions (`test (1.23)` and
  `test (1.24)`). Failing run:
  https://github.com/RoukayaZaki/DevOps-Intro/actions/runs/27637601845
- With branch protection on, the PR could not be merged — GitHub reported its
  state as `blocked`.
- I then reverted the change with a follow-up commit and pushed. Everything went
  green again and the PR went back to mergeable. Green run:
  https://github.com/RoukayaZaki/DevOps-Intro/actions/runs/27637683899

So a failing change really is stopped at the gate, and fixing it clears the gate.

### 1.6 Branch protection

Branch protection is on for `main` on my fork (`RoukayaZaki/DevOps-Intro`):
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Required checks: `vet (1.23)`, `vet (1.24)`, `test (1.23)`, `test (1.24)`, `lint`

One thing worth noting: because `vet` and `test` run as a Go-version matrix, the
check names come through as `vet (1.23)`, `vet (1.24)`, and so on, not plain
`vet`/`test`. So those are the names I required. (If you wanted a single required
check instead, you could add a small `gate` job with `needs: [vet, test, lint]`
and require only that.)

---

## Task 2 — Make It Fast and Smart

### Optimizations applied (described, not pasted)

- 2.1 Dependency caching — `actions/setup-go` runs with `cache: true` and
  `cache-dependency-path: app/go.mod`. This caches the Go module cache
  (`$GOMODCACHE`) and the build cache (`$GOCACHE`), restored on the next run
  keyed by a hash of the dependency file. QuickNotes has no third-party
  dependencies, so there is no `go.sum`; `go.mod` is the deterministic input
  used as the cache key. (With zero deps the *module* download is already near
  zero, but the build cache still shaves compile time — see f below.)
- 2.2 Build matrix — `vet` and `test` each run a `strategy.matrix` over
  `go: ['1.23', '1.24']` with `fail-fast: false`, so both toolchains run to
  completion in parallel and a 1.23-only or 1.24-only regression is visible.
- 2.3 Path filter — `on.*.paths` restricts triggers to `app/` and
  `.github/workflows/ci.yml`, so a PR that only touches docs (e.g. just the
  README or this write-up) runs nothing at all. One thing I confirmed in
  practice: for a pull request the filter looks at the whole PR diff, not the
  last commit, so pushing a docs-only commit to a PR that already changed `app/`
  still re-runs CI. The skip kicks in when the entire PR is docs-only.
- Extra (cheap wins): `concurrency` with `cancel-in-progress` kills
  superseded runs on the same ref; `GOFLAGS=-buildvcs=false` skips the VCS stamp
  probe on shallow CI clones.

### 2.4 Timing table

Numbers read from the Actions UI. The full pipeline (cache + matrix) was measured
directly; the per-job times come from the same green run.

| Scenario | Wall-clock |
|----------|-----------|
| Baseline (single job, no matrix) | ~30 s (one vet+test job runs in about that time) |
| With cache | ~25–30 s (small win: no third-party deps to download, so only the build cache helps) |
| With cache + matrix (the actual pipeline) | **42 s** (5 jobs in parallel, so wall-clock ≈ the slowest job, not the sum) |

Per-job times from the green run: `vet` ~22–24 s, `test` ~25–29 s, `lint` ~37 s.

Honest take: for an app with zero dependencies the cache barely matters, and the
matrix doesn't really grow the wall-clock because the jobs run in parallel — it
just uses more billed minutes. The path filter is the real saver: a docs-only PR
runs nothing at all instead of burning a few minutes.

### Task 2 design questions

f) Why cache `go.sum`-keyed inputs and not build outputs?
Inputs (the pinned module set described by `go.sum`/`go.mod`) are
deterministic: the same key always maps to the same bytes, so a cache hit is
always safe to reuse. Build outputs depend on the exact toolchain version,
OS, build tags, `GOFLAGS`, and CGO state — caching them risks restoring a stale
or environment-mismatched artifact that silently differs from a clean build,
producing "passes in CI, broken in prod" bugs. So you key the cache on the
deterministic input and let Go's own content-addressed build cache decide what
to actually reuse.

g) What does `fail-fast: false` change, and when do you want `fail-fast: true`?
With the GH default `fail-fast: true`, the first matrix cell to fail cancels all
the other in-flight cells — so if `test (1.23)` breaks you never learn whether
`test (1.24)` also breaks. `fail-fast: false` lets every cell run to completion,
giving you the full matrix of red/green — essential when the whole *point* is to
compare toolchains/OSes. You'd flip back to `fail-fast: true` when cells are
expensive or interchangeable and any single failure already means "stop and fix"
(e.g. a costly fan-out where you don't need per-cell diagnosis and want to save
minutes).

h) Risk of an attacker writing a cache that protected branches later read?
Cache poisoning. GH Actions caches are writable from workflows triggered by
PRs, including from forks. A malicious PR could write a tampered entry (e.g. a
trojaned module or build artifact) under a key that a later run on the protected
branch restores — executing attacker-controlled bytes in a trusted context.
GitHub mitigates this with cache scope isolation: caches are partitioned by
branch, and a PR/feature branch cannot read or overwrite the base branch's
cache — a branch can only read caches from itself and its base, not sideways
into another branch's scope. (Ref: GitHub Docs — *"Caching dependencies →
Restrictions for accessing a cache"* / cache scope & isolation.) Pinning the
cache key to a hashed input rather than a mutable name further limits silent
substitution.

---

## Bonus — Pipeline Performance Investigation

### B.2 Optimizations applied (≥ 3, beyond Task 2)

1. `concurrency` + `cancel-in-progress` — superseded runs on the same ref are
   cancelled instead of queueing, freeing runners and cutting feedback latency on
   rapid push sequences.
2. `GOFLAGS=-buildvcs=false` — skips the per-build VCS stamping probe, which
   is pure overhead on CI's shallow clones (directly from the lab's bonus list).
3. Go build-cache reuse via `setup-go` cache — beyond module download, the
   restored `$GOCACHE` lets `go test`/`go vet` skip recompiling unchanged
   packages, the dominant cost for a deps-free module.
4. *(Candidate, documented not applied)* smaller base image — the bonus
   suggests `golang:1.24-alpine` vs `golang:1.24`; with `setup-go` on a hosted
   runner there's no container image to slim, so this applies only to the
   container-based (GitLab/Docker) shape. Noted for completeness.

### B.3 Before/after

The full pipeline already comes in at **42 s**, comfortably under the 90 s
target, so the optimizations below are about keeping it there rather than rescuing
a slow run. Savings on a zero-dependency app are small and inside run-to-run noise.

| Optimization applied | Effect |
|----------------------|--------|
| Build/module cache (`setup-go cache: true`) | Reuses `$GOCACHE` so unchanged packages aren't recompiled; a few seconds on this app |
| `concurrency` cancel-in-progress | Saves whole runs when you push twice quickly |
| `GOFLAGS=-buildvcs=false` | Skips the VCS stamp probe; trims a little setup time |

### B.4 Bottleneck analysis

The longest job is `lint` at ~37 s, and most of that is runner startup plus
installing the Go toolchain and the linter, not the actual checking, which
finishes in a couple of seconds. To make the pipeline meaningfully shorter by
changing QuickNotes itself I'd have to cut compile or test surface, but the code
is already tiny so there isn't much to cut. The `-race` flag roughly doubles test
time, and I'd keep it anyway because catching data races is worth the seconds. I'd
stop optimizing here: at 42 s the feedback is already faster than a context
switch, and more tuning would cost more than it saves. Past this point the better
investment is test coverage, not raw speed.

---

## Summary of deliverables

| Item | Status |
|------|--------|
| `.github/workflows/ci.yml` (3 units, pinned image, SHA-pinned actions, `permissions`, cache, matrix, path filter) | ✅ done, runs green |
| Gate blocks a failing PR, passes after fix | ✅ shown (red run, then green) |
| Branch protection on `main` requiring all checks | ✅ enabled |
| All design answers (a–h) | ✅ complete |
| Timing numbers from the Actions UI | ✅ filled in |
