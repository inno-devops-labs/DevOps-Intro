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

The latest optimized GitHub Actions run on the fork PR produced the following timings:

| Check | Result | Time |
|---|---:|---:|
| lint | passed | 25s |
| test-go-1.23 | passed | 29s |
| test-go-1.24 | passed | 27s |
| vet-go-1.23 | passed | 22s |
| vet-go-1.24 | passed | 23s |

Because the jobs run in parallel, the total wall-clock feedback time is approximately the slowest job time, about 29 seconds.

| Scenario | Wall-clock observation |
|----------|----------------------:|
| Baseline idea: single Go version, no dependency cache, no path filter | Slower expected because every run must resolve dependencies and cannot skip irrelevant paths |
| With cache | Faster after dependency cache is warm |
| With cache + matrix + parallel jobs + path filters | About 29s on the measured PR run |

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

The target was to keep PR feedback under 90 seconds. The measured optimized run completed in about 29 seconds wall-clock time, so the pipeline is comfortably within the target.

### Optimizations used

The pipeline uses more than three optimizations:

1. Independent parallel jobs for `vet`, `test`, and `lint`.
2. Go dependency caching through `actions/setup-go`.
3. A Go version matrix for `vet` and `test`, covering Go 1.23 and Go 1.24.
4. `fail-fast: false`, so all matrix results are collected even if one version fails.
5. Path filters, so documentation-only or unrelated changes do not trigger application CI.
6. Full SHA pinning for third-party actions, reducing supply-chain risk and making CI behavior more reproducible.
7. Least-privilege `GITHUB_TOKEN` permissions using `contents: read`.

### Bottleneck analysis

The measured check times were:

    lint: 25s
    test-go-1.23: 29s
    test-go-1.24: 27s
    vet-go-1.23: 22s
    vet-go-1.24: 23s

The slowest job was `test-go-1.23` at 29 seconds. Because the jobs run in parallel, this slowest job determines the overall feedback time.
