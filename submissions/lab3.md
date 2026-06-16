# Lab 3 — CI/CD: A PR-Gated Pipeline for QuickNotes

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

### 1.5 Proving the gate blocks a bad PR — PENDING PUSH

The mechanism is in place (all three checks are required, job failure fails the
run). To produce the required red-run evidence after pushing:

1. On `feature/lab3`, break a test — e.g. in
   [`app/handlers_test.go:78`](../app/handlers_test.go) change the expected
   `http.StatusBadRequest` to `http.StatusOK`.
2. `git commit -S -s -m "test(lab3): deliberately break to prove the gate"` and push.
3. The `test` check goes red; with branch protection (1.6) the Merge button
   is disabled ("Required statuses must pass"). → screenshot here.
4. Revert with a follow-up commit (`git revert` or restore the value); the check
   returns green and merge is re-enabled. → screenshot here.

*Not executed in this session because pushing was explicitly out of scope.*

### 1.6 Branch protection — PENDING PUSH

On the fork (`RoukayaZaki/DevOps-Intro`): Settings → Branches → Add branch
ruleset / rule for `main`:
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Required checks: `vet`, `test`, `lint`

> ⚠️ Matrix naming caveat. Because `vet` and `test` use a Go-version matrix,
> GitHub reports their checks as `vet (1.23)`, `vet (1.24)`, `test (1.23)`,
> `test (1.24)` — not bare `vet`/`test`. So the required checks to select are
> those four plus `lint`. (Alternatively, add a tiny `gate` job with
> `needs: [vet, test, lint]` and require only `gate` — a clean single required
> check that aggregates the matrix.)

→ branch-protection screenshot here after configuring.

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
  `.github/workflows/ci.yml`. A README-only PR matches nothing and the pipeline
  is skipped entirely.
- Extra (cheap wins): `concurrency` with `cancel-in-progress` kills
  superseded runs on the same ref; `GOFLAGS=-buildvcs=false` skips the VCS stamp
  probe on shallow CI clones.

### 2.4 Timing table — NUMBERS PENDING PUSH

Wall-clock must be read from the Actions UI (median of 3–5 runs, per the lab's
guidance that runners vary). Capture by temporarily disabling each optimization
with a commit, screenshotting, then restoring. Expected directional result for
this tiny, dependency-free module:

| Scenario | Wall-clock |
|----------|-----------|
| Baseline (no cache, single Go version, no path filter) | _≈ TBD s_ |
| With cache | _≈ TBD s (small win — no deps to download; build-cache only)_ |
| With cache + matrix | _≈ TBD s (matrix runs in parallel, so wall-clock ≈ baseline; total CPU-minutes ↑)_ |

> Honest expectation: for a zero-dependency app the cache win is modest and the
> matrix barely moves *wall-clock* (parallel) while doubling *billed minutes*.
> The path filter is the biggest real saver — it takes docs PRs from ~minutes to
> 0 s.

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

### B.3 Before/after — NUMBERS PENDING PUSH

| Optimization applied | Before (s) | After (s) | Saving |
|----------------------|-----------:|----------:|-------:|
| Build/module cache (`setup-go cache: true`) | TBD | TBD | -TBD |
| `concurrency` cancel-in-progress | TBD | TBD | -TBD |
| `GOFLAGS=-buildvcs=false` | TBD | TBD | -TBD |
| Total wall-clock | TBD | TBD | -TBD |

### B.4 Bottleneck analysis

For a module this small, the dominant *remaining* cost is runner startup +
toolchain provisioning (`setup-go` installing the Go toolchain and restoring
the cache), not the actual `vet`/`test`/`lint` work, which finishes in a couple
of seconds. The only way to shrink the pipeline by changing QuickNotes itself
would be to reduce compile/test surface — but the code is already tiny, so
there's little to cut; the realistic lever is the `-race` flag, which roughly
doubles test time (you'd keep it: catching data races is worth the seconds).
We'd stop optimizing once the full pipeline is comfortably under ~60–90 s:
below that, feedback is already faster than a developer's context-switch, and
further engineering effort costs more than the seconds it saves. Past that point
the right move is to spend the budget on *coverage and signal quality*, not raw
speed.

---

## Summary of deliverables

| Item | Status |
|------|--------|
| `.github/workflows/ci.yml` (3 units, pinned image, SHA-pinned actions, `permissions`, cache, matrix, path filter) | ✅ written & YAML-validated locally |
| Local `go vet` / `go test -race` green | ✅ verified |
| All design answers (a–h) | ✅ complete |
| Green-run link, red-run screenshot, branch-protection screenshot, real timing numbers | ⏳ PENDING PUSH (out of scope this session) |
