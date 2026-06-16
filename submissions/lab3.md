# Lab 3 Submission — CI/CD: A PR-Gated Pipeline for QuickNotes

## Path Choice and Rationale

**Path chosen: GitHub Actions.**

The repository already lives on GitHub (fork `1AM6ADA/DevOps-Intro` + upstream
`inno-devops-labs/DevOps-Intro`), so GitHub Actions needs no extra hosting or
runner setup, integrates directly with PR status checks and branch protection,
and supports SHA-pinned third-party actions — the supply-chain control this lab
emphasises. The GitLab path would require mirroring to
`gitlab.pg.innopolis.university` for no engineering benefit here.

The pipeline lives in [.github/workflows/ci.yml](../.github/workflows/ci.yml).

---

## Task 1 — The PR Gate

### What the pipeline does

| Requirement | How it is met |
|---|---|
| Trigger on push to `main` + PRs targeting `main` | `on.push.branches: [main]` and `on.pull_request.branches: [main]` |
| `vet` runs `go vet ./...` against `app/` | `vet` job, `working-directory: app` |
| `test` runs `go test -race -count=1 ./...` against `app/` | `test` job, `working-directory: app` |
| `lint` runs `golangci-lint run` pinned to v2.5.0 against `app/` | `lint` job, `golangci-lint-action` with `version: v2.5.0`, `working-directory: app` |
| Pinned runtime image | `runs-on: ubuntu-24.04` (not `ubuntu-latest`) |
| Third-party actions by 40-char SHA + tag comment | `actions/checkout@11bd71…f683 # v4.2.2`, `actions/setup-go@3041bf…122a # v5.2.0`, `golangci/golangci-lint-action@9fae48…495fa # v7.0.1` |
| `permissions: contents: read` | declared at workflow (top) level |
| Block merging on failure | branch protection on `main` requires the `ci-ok` check (below) |

> Note on the build matrix and the `go` directive: `app/go.mod` declares
> `go 1.24`. On the `1.23` matrix leg, Go's default `GOTOOLCHAIN=auto` transparently
> fetches the `1.24` toolchain to satisfy the directive, so both legs stay green
> without editing the shared app. If a *true* 1.23 compile is required, lower the
> `go` directive in `app/go.mod` to `1.23` — but that is an app change outside the
> scope of this lab's PR, so it is intentionally not done here.

### Evidence (you must fill these in from your own runs)

- **Passing CI run:** <!-- TODO: paste the URL of a green Actions run on feature/lab3 -->
- **Deliberate breakage — failed run:** <!-- TODO: paste URL + screenshot of the red run -->
  - I broke the gate by changing the expectation on
    [app/handlers_test.go:63](../app/handlers_test.go#L63) from `http.StatusCreated`
    (201) to `http.StatusOK` (200), so `go test` fails on `POST /notes`.
  - **Fix commit:** <!-- TODO: paste the SHA/URL of the revert commit that turns CI green again -->
- **Branch protection configuration:** <!-- TODO: screenshot of Settings → Branches → main rule requiring the `ci-ok` check -->

### Design Questions

**a) Why avoid `ubuntu-latest`? What becomes unreliable?**
`ubuntu-latest` is a moving alias that GitHub periodically repoints to a newer
Ubuntu major (e.g. 22.04 → 24.04). Pre-installed tool versions, system libraries,
default compilers and even available packages change underneath you, so a run that
was green yesterday can break today for reasons unrelated to your code, and you
cannot reproduce a past run. Pinning `ubuntu-24.04` makes the environment
deterministic; image upgrades become an explicit, reviewable change.

**b) Why separate vet, test, and lint instead of combining them?**
Each catches a different class of problem (vet: suspicious constructs; test:
behaviour and data races; lint: style/correctness rules). Separate jobs (1) run in
parallel, shortening wall-clock time; (2) give a clear red/green signal per concern;
(3) report *all* failures in one run instead of aborting at the first; and (4) can be
required, cached, and permissioned independently. A single combined step would mask
later failures behind the first one to fail.

**c) What specific attack does SHA pinning mitigate? (named incident from Lecture 3)**
A **mutable-tag supply-chain attack**. Git tags like `v4` — and even `v4.2.2` — are
pointers that the action's maintainer (or an attacker who compromises the action's
repo) can force-move to malicious code; your workflow then executes that code with
your `GITHUB_TOKEN` and secrets. Pinning to an immutable 40-char commit SHA freezes
exactly what runs. Named incident: the **tj-actions/changed-files** compromise of
**14 March 2025** (CVE-2025-30066), where many version tags were retro-pointed at a
malicious commit that dumped CI secrets to logs across thousands of repos;
SHA-pinned consumers were unaffected.
<!-- TODO: confirm this matches the incident named on the Lecture 3 slide; if the
slide cites a different one (e.g. Codecov bash-uploader, April 2021), use that name/date. -->

**d) Define `permissions:` and its underlying security principle.**
`permissions:` sets the scopes granted to the automatic `GITHUB_TOKEN` for the
workflow or a job (e.g. `contents`, `pull-requests`, `packages`, each `read`/`write`/`none`).
Declaring `contents: read` and nothing else applies the **principle of least
privilege**: the token can clone the repo but cannot push commits, cut releases,
edit issues, or publish packages. If a step or a third-party action is compromised,
the blast radius is limited to read-only access instead of the broad default token.

**e) (GitLab path) stages vs jobs; purpose of `dependencies:` beyond `stages:`.**
Not applicable — this submission uses the GitHub Actions path. For completeness:
*stages* are ordered phases that run sequentially; *jobs* live inside a stage and run
in parallel by default. `stages:` only controls ordering, whereas `dependencies:`
controls which earlier jobs' **artifacts** a job downloads (decoupling artifact flow
from stage order), and `needs:` builds a DAG so a job can start before its whole
stage completes.

---

## Task 2 — Optimization and Intelligence

### What was added

- **Caching:** `actions/setup-go` caching is enabled and keyed on the dependency
  lockfile. QuickNotes has **zero** dependencies so there is no `go.sum`; the cache
  key therefore falls back to `app/go.mod` (`cache-dependency-path` lists `go.sum`
  then `go.mod`). This caches `$GOMODCACHE`/`$GOCACHE` between runs.
- **Build matrix:** `vet` and `test` run against Go **1.23** and **1.24** in
  parallel with `fail-fast: false`, so both legs always complete.
- **Aggregation gate `ci-ok`:** because matrix jobs report as `vet (1.23)`,
  `test (1.24)`, etc., the single `ci-ok` job (`needs: [vet, test, lint]`,
  `if: always()`) is the one stable context name to require in branch protection.
- **Path filtering:** `on.pull_request.paths` restricts PR runs to changes under
  `app/**` or the workflow file, so a docs-only PR skips the pipeline.

> Trade-off worth noting: when a docs-only PR is filtered out, the required `ci-ok`
> check never reports, which on a strictly-protected branch can leave the PR
> "waiting". Demonstrate the filter on a throwaway docs-only PR; for real merges,
> either relax the requirement for docs paths or keep CI cheap enough to always run.

### Timing table (you must measure — median of 3–5 runs)

| Scenario | Duration |
|----------|----------|
| Baseline (no optimizations) | <!-- TODO --> seconds |
| With caching enabled | <!-- TODO --> seconds |
| With caching + matrix | <!-- TODO --> seconds |

**Expected finding (explain in your own words once measured):** QuickNotes has no
production dependencies, so module caching saves almost nothing — wall-clock time is
dominated by runner provisioning and the Go toolchain download, neither of which
`setup-go` caches. Caching mainly helps the build/test cache (`$GOCACHE`), a small
effect on a tiny codebase.

### Design Questions

**f) Why cache `go.sum`-keyed *inputs* versus build *outputs*?**
`go.sum`/`go.mod` are deterministic inputs: the same dependency set hashes to the
same key, so the cache is valid across machines and time and invalidates *exactly*
when dependencies change. Caching build outputs keyed on something unstable risks
staleness — outputs also depend on source, compiler version and flags — and a stale
or poisoned output cache can yield wrong or non-reproducible builds. Key on the
lockfile so you never restore artifacts that don't match the current dependencies.

**g) What does `fail-fast: false` change? When is `fail-fast: true` appropriate?**
With the default `fail-fast: true`, the first failing matrix leg cancels all the
others. `fail-fast: false` lets every combination finish, so you learn *which*
versions fail (e.g. green on 1.24 but red on 1.23) in a single run — essential for a
compatibility matrix. `fail-fast: true` is appropriate when legs are expensive or
redundant and you only need a fast "something is broken" signal — e.g. costly
self-hosted runners, or where any single failure means the change is dead anyway.

**h) What security risk does a malicious cache entry pose? (GitHub's mitigation)**
**Cache poisoning:** an attacker (e.g. via a PR from a fork, or a compromised step)
writes malicious content under a cache key that a later, more-privileged job
restores and executes — leading to code execution or secret theft. GitHub's
mitigations: caches are **scoped/isolated by branch** — a feature/PR branch may read
caches from its base or the default branch, but the default branch cannot read a PR
branch's cache, so untrusted branches can't poison what protected branches consume;
cache entries are **immutable** (a key can't be overwritten once created); and cache
access is restricted across repositories. Keying on the lockfile hash adds integrity.

---

## Bonus Task — Performance Investigation (optional, +2)

<!-- TODO (optional): if attempting the bonus, fill the table and analysis below. -->

### Optimizations applied (≥3)

1. <!-- e.g. GOFLAGS=-buildvcs=false to skip VCS stamping on shallow CI clones -->
2. <!-- e.g. run lint and test concurrently with a tightened needs: graph -->
3. <!-- e.g. skip lint on docs-only commits / pre-install linter to cut setup time -->

### Before / After

| Optimization | Before | After | Savings |
|--------------|--------|-------|---------|
| _Optimization 1_ | _X_ s | _X_ s | -_X_ s |
| _Optimization 2_ | _X_ s | _X_ s | -_X_ s |
| _Optimization 3_ | _X_ s | _X_ s | -_X_ s |
| **Total** | **_X_** | **_X_** | **-_X_** |

### Bottleneck analysis (4–6 sentences)

<!-- TODO: identify the dominant remaining step (typically runner provisioning +
toolchain download), what *code* change (not pipeline change) would help further,
and the threshold at which the team should stop optimizing. -->

---

## Submission Checklist

- [ ] `.github/workflows/ci.yml` committed on branch `feature/lab3`
- [ ] `submissions/lab3.md` (this file) with all five Task-1 answers + f/g/h
- [ ] Link to a passing CI run
- [ ] Screenshot/log of the deliberately-broken run + the fix commit
- [ ] Branch-protection screenshot requiring `ci-ok`
- [ ] Timing table filled with measured medians
- [ ] PR `feature/lab3 → main` opened against **upstream** and against **your fork**
- [ ] Both PR URLs submitted to Moodle
