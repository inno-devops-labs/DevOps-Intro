# Lab 3 — CI/CD: A PR-Gated Pipeline for QuickNotes

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-CI%2FCD-blue)
![points](https://img.shields.io/badge/points-10%2B2-orange)
![tech](https://img.shields.io/badge/tech-GH%20Actions%20or%20GitLab%20CI-informational)

> **Goal:** Wire `vet + test + lint` as a required PR gate for QuickNotes. Cache the Go module download. Investigate where your pipeline spends its wall-clock time.
> **Deliverable:** A PR from `feature/lab3` to the course repo with a working CI pipeline + `submissions/lab3.md`. Submit the PR link via Moodle.

---

## Pick Your Path

Two **equivalent** paths. You pick **one** and complete the same Tasks 1+2 on it — same engineering, same 10 points.

| Path | Choose this if… | You write |
|------|----------------|-----------|
| **GitHub Actions** *(default)* | You can sign in to github.com | `.github/workflows/ci.yml` |
| **GitLab CI** | You can't access GitHub (sanctions, account locks). Innopolis runs an internal GitLab at `gitlab.pg.innopolis.university` | `.gitlab-ci.yml` |

> 📝 **Pick *one*.** Doing both does not earn extra points — the Bonus task is a different challenge.

State your chosen path at the top of `submissions/lab3.md`.

---

## Overview

By the end of this lab:
- Every PR to `main` automatically runs `go vet`, `go test -race`, and `golangci-lint`
- A failing PR is **blocked** from merging
- Your pipeline is fast enough that you don't dread it (Task 2 + Bonus)

You won't be handed the YAML. The skill of this lab is **writing it yourself** from requirements + docs. That's a marketable skill; "copy-pasted from a tutorial" isn't.

---

## Project State

**Starting point:** QuickNotes runs locally (Lab 1); your fork's `main` mirrors upstream.

**After this lab:** Your fork's `main` is branch-protected; PRs cannot merge without a green CI run.

---

## Prerequisites

- Lab 1 + Lab 2 complete (signed commits, your fork up to date)
- GitHub *or* GitLab account
- ~5 free hours of CI minutes/month (both platforms' free tiers cover this lab comfortably)

---

## Task 1 — Write the PR Gate (6 pts)

### 1.1: Requirements your pipeline must meet

Your CI configuration MUST:

1. **Trigger** on:
   - Push to `main`
   - Every pull request targeting `main`
2. **Run three independent units of work** (jobs in GH Actions; jobs-within-stages in GitLab CI):
   - **vet** → `go vet ./...` against `app/`
   - **test** → `go test -race -count=1 ./...` against `app/`
   - **lint** → `golangci-lint run` against `app/`, using **golangci-lint v2.5.0** (pinned)
3. **Pin the runtime environment** — not `:latest`, not `ubuntu-latest`. Pick a specific Ubuntu LTS or Go image tag and stick with it
4. **GH Actions only:** every third-party action (anything not prefixed `actions/` from GitHub itself, and even those for hardening) must be referenced by **full 40-character commit SHA**, with the human-readable tag in a trailing comment:
   ```yaml
   - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.2.2
   ```
5. **GH Actions only:** declare `permissions:` at the workflow or job level — start with `contents: read` (least privilege)
6. The pipeline **MUST FAIL** the PR if any of the three units fails

### 1.2: Design questions — answer these in your submission

Don't skip these. The answers matter more than the YAML.

- a) **Why pin the runner version** (`ubuntu-24.04`) instead of `ubuntu-latest`? What breaks otherwise?
- b) **Why split vet + test + lint into separate units?** What would happen with one combined job?
- c) **GH path:** what real attack does **SHA pinning** prevent? Cite the date + name of the incident from Lecture 3
- d) **GH path:** what is `permissions:` and what's the principle behind it?
- e) **GitLab path:** what's the difference between a *stage* and a *job*? What would `dependencies:` do that `stages:` doesn't?

### 1.3: Where to start (docs, not copy-paste)

- **GitHub Actions:**
  - [Quickstart](https://docs.github.com/en/actions/quickstart)
  - [Workflow syntax reference](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
  - [`actions/setup-go`](https://github.com/actions/setup-go)
  - [`golangci/golangci-lint-action`](https://github.com/golangci/golangci-lint-action)
- **GitLab CI:**
  - [CI/CD YAML syntax reference](https://docs.gitlab.com/ee/ci/yaml/)
  - [Get started with GitLab CI/CD](https://docs.gitlab.com/ee/ci/quick_start/)
  - [`golang` Docker image tags](https://hub.docker.com/_/golang) for the test image
- **Both platforms:** find the official "setup Go" example in the docs for your platform and adapt it. Your QuickNotes module lives in `app/` — your pipeline will need to change directory or set a working directory.

### 1.4: Iterate to green

```bash
git switch -c feature/lab3
# write your CI config
git add .github/workflows/ci.yml   # OR .gitlab-ci.yml
git commit -S -s -m "ci(lab3): add PR-gate"
git push -u origin feature/lab3
```

Open a draft PR. Read the CI output. Fix until green. **Then** mark the PR ready for review.

### 1.5: Prove the gate works

Make a commit that deliberately breaks something (e.g. change an expected value in `app/handlers_test.go`). Push. Confirm:

- The check is **red**
- The PR **cannot merge** (see 1.6)

Revert the breakage with a follow-up commit. Confirm the check is green again.

### 1.6: Branch protection

On your fork: **Settings → Branches → Add rule for `main`**:
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Required checks: `vet`, `test`, `lint` (or your stage names)

GitLab equivalent: **Settings → Repository → Protected branches** + **Push rules**.

### 1.7: Document

In `submissions/lab3.md`:
- Which path you picked (GitHub or GitLab) and why
- Link to a **green** CI run
- Screenshot or log of the *failed* run from 1.5, plus the fix commit
- Branch-protection screenshot
- Written answers to all 5 design questions in 1.2

---

## Task 2 — Make It Fast and Smart (4 pts)

### 2.1: Cache the dependency download

Caching what you can:
- Go module cache (everything `go mod download` produces)
- Go build cache (compilation outputs from `go install`/`go build`)

The key insight: **cache *inputs*, not *outputs***. Inputs (`go.sum`-pinned modules) are deterministic; outputs may vary subtly.

Find the right cache mechanism on your platform:
- **GH Actions:** look at the documented options on `actions/setup-go`
- **GitLab CI:** read [Caching in GitLab CI/CD](https://docs.gitlab.com/ee/ci/caching/) — pay attention to `cache.key.files`

### 2.2: Add a build matrix

Run `vet + test` against **two Go versions** in parallel: `1.23` and `1.24`. Catch "works on my machine" bugs that depend on the toolchain.

Tips:
- GH: `strategy.matrix`
- GitLab: `parallel:matrix:`
- Set `fail-fast: false` (GH) or equivalent so a single bad cell doesn't cancel the others — you want to *see* which combo broke

> ⚠️ **The matrix renames your checks — update branch protection (1.6) or your PR blocks forever.** A matrixed `test` job reports as `test (1.23)` and `test (1.24)`; the old required check named `test` will sit at *"Expected — Waiting for status to be reported"* indefinitely, even though every real check is green. Two fixes:
>
> 1. **Quick:** in the branch-protection rule, replace `vet`/`test` with the matrixed names (`vet (1.23)`, `vet (1.24)`, `test (1.23)`, `test (1.24)`).
> 2. **Robust (recommended):** add one aggregation job and require *only* it — then the matrix can change freely without touching protection settings:
>
> ```yaml
> ci-ok:
>   if: always()
>   needs: [vet, test, lint]
>   runs-on: ubuntu-24.04
>   steps:
>     - run: |
>         test "${{ contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled') }}" = "false"
> ```
>
> The `if: always()` matters — without it, a failed `needs` job *skips* `ci-ok`, and a skipped required check lets the PR through on some configurations.

### 2.3: Skip docs-only changes

Edit your trigger so the pipeline runs **only** when something in `app/` or your CI config itself changes. README edits should not burn 4 minutes of CI time.

- GH: `on.pull_request.paths`
- GitLab: `rules:` with `changes:`

### 2.4: Measure

Capture wall-clock times from the CI UI for three scenarios:

| Scenario | Wall-clock |
|----------|-----------|
| Baseline (no cache, single Go version, no path filter) | XX s |
| With cache | XX s |
| With cache + matrix | XX s |

> 💡 To get a clean baseline, temporarily disable each optimization with a commit, take a screenshot of the run time, then restore.

> 🧪 **Expect the cache rows to be boring — that's the finding, not a failure.** QuickNotes has **zero third-party dependencies** (look at `app/go.mod` — no `require` block, no `go.sum`), so the module cache has nothing to store and total wall-clock barely moves with `cache: true` vs `cache: false`. Most of your 60–80 s is runner provisioning, checkout, and the Go toolchain download — none of which `setup-go`'s cache touches. Report what you measured and *explain why* (that's design question **f** in disguise). To see where caching *would* pay, compare the **per-step** durations (`setup-go`, `go test`) instead of job totals, and note which step a real dependency-heavy project would save on.

### 2.5: Document

In `submissions/lab3.md`:
- The 3-row timing table above
- A description (not the YAML) of each optimization you applied
- Design questions for Task 2:
  - f) **Why cache `go.sum`-keyed inputs and not build outputs?**
  - g) **What does `fail-fast: false` change in a matrix run, and when do you actually want `fail-fast: true`?**
  - h) **What's the risk** of an attacker writing a cache from a malicious PR that protected branches later read? (Hint: GH has mitigations — find the official doc on this)

---

## Bonus Task — Pipeline Performance Investigation (2 pts)

**Goal:** make your full pipeline complete in **≤ 90 s** wall-clock, or document the dominant cost if you can't.

### B.1: Profile

Use the CI UI's per-step timing breakdown. For each unit:
- How long does the runner take to **start**?
- How long does **dependency setup** take (Go install, module download)?
- How long does **the actual work** take (vet, test, lint)?
- How long does **cleanup / artifact upload** take?

### B.2: Apply ≥ 3 additional optimizations beyond Task 2

Choices (pick at least 3; you don't have to apply all):
- Use a **smaller base image** (`golang:1.24-alpine` vs `golang:1.24`)
- **Run lint and tests in parallel** with the right dependency graph
- **Skip lint** on docs-only commits within `app/` (e.g. only the README changed)
- Switch to **BuildKit** for any Docker-related steps (Lab 6 territory but applies if you build a probe image)
- Use a **self-hosted runner** — probably overkill for this lab, but mention it
- Avoid `go install` on every run — pre-install the linter in a base image or `actions/cache` the `$GOBIN`
- Use **`GOFLAGS=-buildvcs=false`** when CI clones with limited git history

### B.3: Present before/after

| Optimization applied | Before (s) | After (s) | Saving |
|----------------------|-----------:|----------:|-------:|
| Optimization 1 — name it | XX | XX | -XX |
| Optimization 2 — name it | XX | XX | -XX |
| Optimization 3 — name it | XX | XX | -XX |
| **Total wall-clock** | **XX** | **XX** | **-XX** |

### B.4: Bottleneck analysis

Answer in 4-6 sentences:
- Which single step dominates the *remaining* time?
- What would you have to change about QuickNotes itself (the code, not the pipeline) to make it shorter?
- At what wall-clock would your team *stop* optimizing? Why?

---

## How to Submit

1. CI config (`.github/workflows/ci.yml` *or* `.gitlab-ci.yml`) committed to your fork
2. `submissions/lab3.md` covers all attempted tasks, including written answers to the design questions
3. PR opened from `feature/lab3` → course repo's `main`
4. Submit the PR URL via Moodle

---

## Acceptance Criteria

### Task 1 (6 pts)
- ✅ CI config exists and runs all three units (vet, test, lint)
- ✅ Pinned runtime image (no `:latest`)
- ✅ (GH path) All third-party actions pinned by full SHA
- ✅ (GH path) `permissions:` set
- ✅ Branch protection enabled requiring CI to pass
- ✅ Evidence of a deliberate failure being **blocked**, then fixed
- ✅ Written answers to all 5 design questions in 1.2

### Task 2 (4 pts)
- ✅ Caching active (and verifiable in the run log)
- ✅ Matrix runs Go 1.23 + 1.24 in parallel
- ✅ Path filter excludes docs-only PRs (demonstrate with one PR that *should* skip)
- ✅ Timing table comparing baseline / cached / cached+matrix
- ✅ Written answers to design questions f, g, h

### Bonus Task (2 pts)
- ✅ ≥ 3 additional optimizations applied beyond Task 2
- ✅ Before/after timing table
- ✅ Bottleneck analysis (4-6 sentences)
- ✅ (Optional but appreciated) Target ≤ 90 s hit, or honest explanation of why not

---

## Rubric

| Task | Points | Criteria |
|------|-------:|----------|
| **Task 1** — PR gate with vet+test+lint | **6** | All 3 units, pinned versions, SHA pinning (GH) or correct stages (GitLab), branch protection, failure+fix evidence, design questions answered |
| **Task 2** — Cache + matrix + path filter | **4** | All three optimizations verified, timing table, design questions answered |
| **Bonus** — Performance investigation | **2** | ≥ 3 optimizations, before/after table, bottleneck analysis |
| **Total** | **10 + 2 bonus** | |

---

## Common Pitfalls

- 🪤 **Used `actions/checkout@v4` instead of a 40-char SHA** — works, but defeats the point of the requirement and doesn't prepare you for the tj-actions class of incident
- 🪤 **Forgot `working-directory` (or `cd app`) for Go commands** — Go modules live in `app/`, not the repo root; commands run from the root will fail with "no Go files"
- 🪤 **`fail-fast: true` (the GH Actions default) in a matrix** — one fail cancels the others; you can't see *which* combo broke
- 🪤 **Branch protection set on someone else's fork's `main`** — you can only protect *your* fork's `main`. The upstream course repo has its own protection
- 🪤 **PR stuck on "Expected — Waiting for status to be reported" after adding the matrix** — the matrix renamed `test` → `test (1.23)`/`test (1.24)`, but branch protection still requires the old `test` context, which will never report again. Update the required-check names or switch to the `ci-ok` aggregation job (see §2.2)
- 🪤 **"Caching didn't speed anything up"** — on a zero-dependency module that's the *correct* result, not a mistake (see §2.4); don't pad the timing table with numbers you didn't observe
- 🪤 **`golangci-lint` version not pinned** — "latest" pulls a new release tomorrow that may flag your code with new rules. Pin `v2.5.0` exactly
- 🪤 **GitLab CI: incorrect anchor syntax** (`<<: *name`) — GitLab is strict; use the in-platform CI Lint tool (`Project → CI/CD → Editor → Validate`)
- 🪤 **Cache hits expire after 7 days of inactivity on GH** — that's expected; the cache key is what protects you against poisoning
- 🪤 **Time the pipeline once and call it baseline** — measure 3-5 runs and use the median; runners vary

---

## Guidelines

- This lab's **skill is writing the YAML yourself**. Tutorials and docs are fine; copy-pasting a complete file from the lecture is not
- For every change you make to the pipeline, ask *"what does this protect against?"* — if you can't answer, you don't need it
- Take CI seriously: the most senior engineers in any team have strong opinions about pipeline shape, because broken pipelines cost everyone all day
- "Make it work" → "make it fast" → "make it correct" is the natural order. Don't optimize before it's green

---

## Resources

- 📖 [GitHub Actions — Security guides](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
- 📖 [GitHub Actions — Caching dependencies](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- 📖 [GitLab CI/CD — Caching](https://docs.gitlab.com/ee/ci/caching/)
- 📖 [GitLab CI/CD — Parallel matrix jobs](https://docs.gitlab.com/ee/ci/yaml/index.html#parallelmatrix)
- 📝 [tj-actions/changed-files supply-chain incident (March 2025)](https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised)
- 📕 *Continuous Delivery* — Humble & Farley (2010) — Chapters 1-5
- 🛠️ [`pinact`](https://github.com/suzuki-shunsuke/pinact) — auto-pin actions by SHA
- 🛠️ [`act`](https://github.com/nektos/act) — run GH Actions locally
- 🛠️ [GitLab CI Lint](https://docs.gitlab.com/ee/ci/lint.html) — validate `.gitlab-ci.yml` before pushing
