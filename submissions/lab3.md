# Lab 3 Submission

## Chosen Path

GitHub Actions.

I picked GitHub Actions because the lab uses GitHub by default and the course flow is built around pull requests on GitHub.

## Task 1

### Green CI Runs

Green run after the deliberate failure was fixed:

https://github.com/lime413/DevOps-Intro/actions/runs/27573596586

Final green run after Task 2 and Bonus changes:

https://github.com/lime413/DevOps-Intro/actions/runs/27575284056

GitHub Actions summary for this run:

```text
ci: completed, success
lint: success
vet (go 1.23): success
vet (go 1.24): success
test (go 1.23): success
test (go 1.24): success
```

Local command output:

```text
$ cd app && go vet ./...
# no output, exit code 0

$ cd app && go test -race -count=1 ./...
ok  	quicknotes	2.259s
```

### Failed Run And Fix

Failed run:

https://github.com/lime413/DevOps-Intro/actions/runs/27573354392

Screenshot:

![Failed CI run](failure.png)

Deliberate failing commit:

`f6a5ec746b0f66fc1930813ffcc85b3c6153766a`

Fix commit:

`28aa5363378e13e7b8783e70c3d522acce6dbe4e`

### Branch Protection

Branch protection rule for `main`:

![Branch protection rule](branch_protection.png)

The screenshot shows that status checks are required and branches must be up to date before merging.

The required checks are:

- `vet (go 1.23)`
- `vet (go 1.24)`
- `test (go 1.23)`
- `test (go 1.24)`
- `lint`

### Design Answers

#### a) Why pin the runner version instead of using `ubuntu-latest`?

`ubuntu-latest` can change at any time. If GitHub moves it to a newer image, the pipeline may start failing even when the project code did not change. A pinned version makes the environment stable and easier to debug.

#### b) Why split `vet`, `test`, and `lint` into separate jobs?

Separate jobs show exactly what failed. They can also run in parallel, so the total wall-clock time is lower. If everything is inside one job, one early failure hides the rest of the results and the whole pipeline is slower.

#### c) What real attack does SHA pinning prevent?

SHA pinning protects the workflow from a supply-chain attack where a tag or release reference points to changed or malicious code. A clear example is the `tj-actions/changed-files` compromise from March 2025. With a full commit SHA, the workflow runs one exact version of the action, not whatever code the tag points to later.

Command output showing the action pins:

```text
$ rg -n "uses: [^@]+@[^ ]+" .github/workflows/ci.yml
36:      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
37:      - uses: actions/setup-go@4a3601121dd01d1626a1e23e37211e3254c1c06c # v6.4.0
55:      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
56:      - uses: actions/setup-go@4a3601121dd01d1626a1e23e37211e3254c1c06c # v6.4.0
70:      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
83:      - uses: actions/setup-go@4a3601121dd01d1626a1e23e37211e3254c1c06c # v6.4.0
91:        uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
95:      - uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
```

#### d) What is `permissions:` and what principle is behind it?

`permissions:` defines what the GitHub token inside the workflow can do. The right principle is least privilege: give the workflow only the smallest access it needs. For this lab, `contents: read` is enough.

#### e) GitLab-only question

I used GitHub Actions, so this question does not apply.

## Task 2

### Optimizations Applied

1. Added Go cache through `actions/setup-go`.
2. Added a matrix for Go `1.23` and `1.24` on `vet` and `test`.
3. Added path filters so a separate docs-only PR does not start the pipeline.

Note: this project has no `app/go.sum` file because it has no direct external module dependencies. For this reason, the cache key uses `app/go.mod`, which is the stable input available in this repository.

I also changed `app/go.mod` from `go 1.24` to `go 1.23`. Without this, the Go `1.23` matrix cells were not a real compatibility check with the newer `setup-go` action.

The final report-only commit still started CI because this PR already contains changes in `app/` and `.github/workflows/ci.yml`. The path filter is meant for a PR where the whole diff is documentation outside those paths.

### Timing Table

| Scenario | Wall-clock |
| --- | --- |
| Baseline (no cache, single Go version, no path filter) | 70 s |
| With cache | 77 s |
| With cache + matrix | 72 s |

Measurement runs:

- Baseline: https://github.com/lime413/DevOps-Intro/actions/runs/27574112361
- With cache: https://github.com/lime413/DevOps-Intro/actions/runs/27574230082
- With cache + matrix: https://github.com/lime413/DevOps-Intro/actions/runs/27573596586

The cache-only run was slower than the baseline because the cache was still cold and GitHub runner startup time changed between runs. The important result is not only this one number, but that later runs can reuse the cache.

Relevant workflow output from the latest run:

```text
Cache hit for: Linux-go-1.24-golangci-lint-v2.5.0
Run go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@${GOLANGCI_LINT_VERSION}: skipped
0 issues.
```

### Design Answers

#### f) Why cache `go.sum`-keyed inputs and not build outputs?

Inputs such as module versions are deterministic and safe to reuse when the dependency file does not change. Build outputs are less stable because they depend on the platform, toolchain, flags, and environment details. Caching inputs gives speed without mixing old compiled artifacts into a new run.

#### g) What does `fail-fast: false` change, and when do you want `fail-fast: true`?

`fail-fast: false` lets all matrix cells continue even if one cell fails. That is useful in this lab because we want to see whether both Go versions fail or only one. `fail-fast: true` is better when saving CI time is more important than collecting all results.

#### h) What is the risk of cache poisoning from a malicious PR?

A malicious PR may try to write bad data into a cache and then make protected branches restore it later. If that happens, trusted runs could use files prepared by untrusted code. The defense is to scope caches carefully and avoid sharing writable caches from untrusted contexts with protected branches.

## Bonus Task

### Profile

Final bonus run:

https://github.com/lime413/DevOps-Intro/actions/runs/27575284056

Total wall-clock time: 45 s.

| Unit | Runner and actions setup | Dependency setup | Actual work | Cleanup | Unit total |
| --- | ---: | ---: | ---: | ---: | ---: |
| `vet` | about 1-2 s | about 3-8 s | about 1-9 s | less than 1 s | 21-33 s |
| `test` | about 1-2 s | about 3-8 s | about 20 s | less than 1 s | 30-34 s |
| `lint` | about 1-2 s | about 5 s | about 4-21 s | about 1-2 s | 11 s in the latest run |

The test command is slower than the Go output suggests because CI also spends time compiling with the race detector. Lint was the biggest setup problem before the bonus work because `go install` for `golangci-lint` took about 42 s on a cold run.

### Extra Optimizations

1. Cached the `golangci-lint` binary in `~/go/bin/golangci-lint`.
2. Cached the `golangci-lint` analysis cache in `~/.cache/golangci-lint`.
3. Added `GOFLAGS=-buildvcs=false`.
4. Skipped the expensive lint setup when a PR changes only `app/README.md`.
5. Updated pinned official actions to current full-SHA versions: `checkout` v6.0.3, `setup-go` v6.4.0, and `cache` v5.0.5.

### Before And After

| Optimization applied | Before (s) | After (s) | Saving |
| --- | ---: | ---: | ---: |
| Cache `golangci-lint` binary | 42 | 0 | -42 |
| Cache linter analysis data | 21 | 21 | 0 in this small app |
| Skip lint for `app/README.md` only | 11 | about 2-4 | about -7 |
| Total wall-clock | 63 | 45 | -18 |

The total comparison uses the first bonus run before the linter binary cache was warm and the latest run after the cache was warm.

### Bottleneck Analysis

The remaining slow parts are the race-test jobs and lint. They take similar time, and because jobs run in parallel, the slowest one decides the total wall-clock time. To make QuickNotes itself faster, I would reduce expensive race-test setup, split slow tests if the test suite grows, and keep handlers and store tests focused. I would stop optimizing this lab around 45-60 s because GitHub runner startup and action setup are now a large part of the total time. More changes would add complexity without much benefit for such a small app.

## What Still Needs To Be Done On GitHub

1. Mark the course PR as ready for review if it is still a draft.
2. Submit the course PR link in Moodle.
