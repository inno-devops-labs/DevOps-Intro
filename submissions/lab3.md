# Lab 3 Submission — CI/CD: A PR-Gated Pipeline for QuickNotes

## Chosen Path

I chose the GitHub Actions path because the course repository and my fork are hosted on GitHub, and the previous labs were already submitted through GitHub pull requests.

## Task 1 — PR Gate

### CI workflow

CI configuration file:

    .github/workflows/ci.yml

The workflow is named `ci` and runs on pull requests targeting `main` and pushes to `main`.

The workflow uses path filters so CI runs only when these paths change:

    app/**
    .github/workflows/ci.yml

### Jobs configured

The workflow defines three independent jobs:

- `vet`
- `test`
- `lint`

The `vet` job runs:

    go vet ./...

The `test` job runs:

    go test -race -count=1 ./...

The `lint` job runs `golangci-lint` with version:

    v2.5.0

### Runtime and security settings

The workflow uses the pinned runner:

    ubuntu-24.04

The workflow uses least-privilege permissions:

    permissions:
      contents: read

Pinned actions used:

    actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
    actions/setup-go@d35c59abb061a4a6fb18e82ac0862c26744d6ab5  # v5.5.0
    golangci/golangci-lint-action@7119f3d5ddced62a10a044847a6c6bb0f7a5e76a  # v7.0.0

### PR links

Fork PR with working GitHub Actions checks:

    https://github.com/tivdzualubem/DevOps-Intro/pull/3

Course PR:

    https://github.com/inno-devops-labs/DevOps-Intro/pull/967

### Green CI run evidence

The fork PR showed all five checks passing:

- `ci / lint`
- `ci / test-go-1.23`
- `ci / test-go-1.24`
- `ci / vet-go-1.23`
- `ci / vet-go-1.24`

The successful checks confirm that the workflow runs the required independent units of work and that the PR gate is functional on my fork.

### Local validation

YAML validation command:

    python3 - <<'PY'
    import yaml
    with open(".github/workflows/ci.yml", "r", encoding="utf-8") as f:
        yaml.safe_load(f)
    print("YAML OK")
    PY

Output:

    YAML OK

Local Go checks:

    cd app
    go vet ./...
    go test -race -count=1 ./...

Output:

    ok      quicknotes      1.031s

### Design questions

#### a) Why pin the runner version (`ubuntu-24.04`) instead of `ubuntu-latest`?

Pinning `ubuntu-24.04` makes the CI environment predictable. `ubuntu-latest` can move to a newer runner image when GitHub updates its hosted environment. That can change installed packages, system libraries, compiler behavior, or default tooling. A workflow that passed yesterday could fail today without any change in the repository. Pinning the runner reduces this moving-target risk.

#### b) Why split vet + test + lint into separate units?

Splitting `vet`, `test`, and `lint` makes failures easier to diagnose because each check reports independently. It also allows the jobs to run in parallel, which reduces wall-clock feedback time. If everything were combined into one job, the first failure could stop the later checks from running, hiding other problems and making the feedback less useful.

#### c) What real attack does SHA pinning prevent?

SHA pinning prevents a workflow from silently executing changed or malicious action code when a tag is moved. Lecture 3 discussed the March 2025 `tj-actions/changed-files` compromise, where attackers rewrote tags to malicious versions that leaked secrets from public CI runs. Pinning actions to full commit SHAs makes the referenced action code immutable, so a moved tag cannot change what the workflow executes.

#### d) What is `permissions:` and what principle is behind it?

`permissions:` controls what access the automatically provided `GITHUB_TOKEN` has during a workflow run. Setting `contents: read` gives the workflow only the access needed to read the repository contents. This follows the principle of least privilege: automation should receive only the minimum permissions needed to do its job, so the damage is limited if a workflow step or action is compromised.

#### e) GitLab path question

I used the GitHub Actions path, not GitLab CI. In GitLab, a stage is a pipeline phase such as `test`, `scan`, or `publish`, while a job is an individual unit of work inside a stage. Jobs in the same stage can run in parallel, while stages usually run in order. `dependencies:` controls which artifacts from previous jobs are downloaded by a later job; it does not define the overall execution order the way `stages:` does.

## Task 2 — Make It Fast and Smart

### Optimizations applied

The workflow uses Go dependency caching through `actions/setup-go`:

    cache: true
    cache-dependency-path: app/go.sum

The workflow runs `vet` and `test` as a matrix across two Go versions:

    Go 1.23
    Go 1.24

The matrix uses:

    fail-fast: false

The workflow also uses path filters so CI runs only when `app/**` or `.github/workflows/ci.yml` changes.

### Timing table

I measured three workflow states from the GitHub PR checks UI.

| Scenario | Configuration | Wall-clock |
|----------|---------------|-----------:|
| Baseline | Single Go 1.24, no dependency cache, no path filter | 27s |
| With cache | Single Go 1.24, dependency cache enabled, no matrix | 34s |
| With cache + matrix + path filters | Go 1.23/1.24 matrix, dependency cache, path filters, parallel jobs | 29s |

Detailed measured checks:

| Scenario | Check | Time |
|---|---|---:|
| Baseline | lint-baseline | 27s |
| Baseline | test-baseline-go-1.24 | 23s |
| Baseline | vet-baseline-go-1.24 | 23s |
| Cache-only | lint-cache | 23s |
| Cache-only | test-cache-go-1.24 | 34s |
| Cache-only | vet-cache-go-1.24 | 24s |
| Final optimized | lint | 29s |
| Final optimized | test-go-1.23 | 27s |
| Final optimized | test-go-1.24 | 28s |
| Final optimized | vet-go-1.23 | 22s |
| Final optimized | vet-go-1.24 | 24s |

The cache-only run was slower than the baseline in this measurement because hosted runner scheduling and cache restore behavior vary between runs. The final optimized pipeline still meets the performance target because the matrix jobs run in parallel and the total feedback time is determined by the slowest job.

### Docs-only skip demonstration

I added a temporary documentation-only commit:

    cc8ffeb docs(lab3): demonstrate docs-only CI skip

The changed file was outside both workflow trigger paths:

    app/**
    .github/workflows/ci.yml

The PR did not start a new application CI run for that docs-only change. The PR continued showing the previous required optimized checks as successful. This demonstrates that the path filter skips documentation-only changes.

### Design questions for Task 2

#### f) Why cache `go.sum`-keyed inputs and not build outputs?

`go.sum` identifies the exact module dependencies used by the project. Caching dependency inputs is safe because those modules are versioned and reproducible. Build outputs are generated artifacts and may depend on operating system, compiler flags, architecture, or local state. Caching generated outputs as trusted inputs can create subtle correctness and security problems.

#### g) What does `fail-fast: false` change in a matrix run, and when would `fail-fast: true` be useful?

`fail-fast: false` allows all matrix jobs to finish even if one matrix cell fails. This is useful when testing multiple Go versions because it shows exactly which version fails and which still passes. `fail-fast: true` is useful when the matrix is expensive and one failure is enough to invalidate the whole run, such as a deployment pipeline where continuing would waste time or CI minutes.

#### h) What is the risk of malicious PR cache poisoning?

A malicious pull request could try to write dangerous or corrupted cache content that later trusted branches restore and use. This is a supply-chain risk because cache content can cross workflow boundaries if not controlled. GitHub mitigates this by restricting cache access patterns, especially around protected and default branches, but workflows should still avoid caching untrusted generated outputs.

## Task 1.5 — Failure and Fix Evidence

I intentionally broke the test suite in commit:

    e7f828c test(lab3): demonstrate failing PR gate

The failing change modified `app/handlers_test.go` so that `TestCreateNote_RoundTrip` failed even though the application returned HTTP 201.

Local failure output:

    --- FAIL: TestCreateNote_RoundTrip (0.00s)
        handlers_test.go:64: expected 201, got 201
    FAIL
    FAIL    quicknotes      0.020s

On the fork pull request, GitHub Actions showed:

    Some checks were not successful
    2 failing, 3 successful checks
    ci / test-go-1.23 failed
    ci / test-go-1.24 failed
    Merging is blocked

This demonstrates that the PR gate blocks a broken change.

I then restored the test in commit:

    4c73fff test(lab3): restore passing PR gate

After the restore commit, the fork pull request showed:

    All checks have passed
    5 successful checks
    ci / lint passed
    ci / test-go-1.23 passed
    ci / test-go-1.24 passed
    ci / vet-go-1.23 passed
    ci / vet-go-1.24 passed

This confirms that the PR gate recovers after the fix and allows only passing code.

## Branch Protection Evidence

The fork repository has a branch protection rule for `main`.

The rule requires:

    Pull request before merging
    1 approval
    Status checks to pass before merging
    Branches to be up to date before merging
    Signed commits
    Linear history

The required status checks configured on the fork are:

    lint
    test-go-1.23
    test-go-1.24
    vet-go-1.23
    vet-go-1.24

This means a PR cannot be merged into `main` unless the CI pipeline passes and the protected branch requirements are satisfied.

## Bonus Task — Pipeline Performance Investigation

### Performance target

The target was to keep PR feedback under 90 seconds. The final optimized run completed in about 29 seconds wall-clock time, so the pipeline is comfortably within the target.

### Additional optimizations beyond Task 2

The final workflow includes these extra optimizations and hardening choices beyond the basic cache + matrix + path filter requirements:

1. Independent `vet`, `test`, and `lint` jobs run in parallel.
2. `GOFLAGS=-buildvcs=false` is set to avoid unnecessary VCS stamping work in CI.
3. `concurrency` cancels older duplicate runs when a newer commit is pushed to the same PR.
4. Full SHA pinning is used for actions, making the pipeline reproducible and reducing supply-chain risk.
5. Least-privilege `permissions: contents: read` limits the workflow token.

### Before/after timing table

| Optimization applied | Before | After | Saving |
|---|---:|---:|---:|
| Parallel independent jobs | Serial-style total would be about 73s using baseline check sum | 27s wall-clock baseline parallel run | about 46s |
| Add cache-only setup | 27s baseline wall-clock | 34s measured cache-only wall-clock | no saving in this run |
| Restore final matrix + path-filter workflow | 34s cache-only wall-clock | 29s optimized wall-clock | about 5s |
| Docs-only path filter | Full CI run would be about 29s | skipped app CI for docs-only commit | about 29s saved |

### Bottleneck analysis

The dominant remaining cost is the test job, especially `go test -race -count=1 ./...`, because the race detector adds runtime compared with a normal test run. I kept the race detector because the lab explicitly requires it and because it is a useful quality gate for catching concurrency issues. To make QuickNotes itself faster, the application tests would need to reduce unnecessary setup work, avoid slow integration-style paths where unit tests are enough, and keep test data minimal. I would stop optimizing this pipeline below roughly 30 seconds because the remaining time is mostly runner startup and required quality checks, and further reduction would not justify weakening the gate.

