# Lab 3 Submission

Chosen path: GitHub Actions

I chose GitHub Actions because the repository is hosted on GitHub and this is the default path for the lab.

## Task 1 Evidence

### Failed CI run

I deliberately introduced a breaking change to prove that the PR gate blocks bad commits. The CI checks failed as expected.

Failed run screenshot: https://gyazo.com/71cab95128f4fa3e7352b166059ba309

### Fixed CI run

After confirming the gate failed correctly, I reverted/fixed the breaking change and pushed the correction. The CI checks passed again.

Fixed / green run screenshot: https://gyazo.com/e17d7fcf32959171edd8bb25d9e53be2

### Branch protection

Branch protection was enabled on `main` in my fork. The rule requires status checks to pass before merging, so the PR cannot be merged unless the CI pipeline is green.

Branch protection screenshot: https://gyazo.com/6681bd00b8b3d6b65055b93f69626a57


## Design Questions

### a) Why pin the runner version instead of ubuntu-latest?

Pinning `ubuntu-24.04` makes the CI environment predictable. `ubuntu-latest` can move to a newer Ubuntu image later, which may change installed packages, shell behavior, Go toolchain defaults, or dependency versions. That can break a previously green pipeline without any code change.

### b) Why split vet, test, and lint into separate units?

Splitting them gives clearer failure reports and allows the jobs to run in parallel. If everything is in one combined job, one early failure hides later failures, and the CI output becomes slower and less useful.

### c) What real attack does SHA pinning prevent?

SHA pinning protects against supply-chain attacks where an attacker compromises or retags a GitHub Action version tag. The lab references the `tj-actions/changed-files` supply-chain incident from March 2025. If a workflow used a mutable tag, it could suddenly execute malicious action code. A full commit SHA points to one exact immutable commit.

### d) What is permissions: and what principle is behind it?

`permissions:` controls what the GitHub Actions token is allowed to do inside the workflow. Setting `contents: read` follows least privilege: the workflow only gets the access it needs to read the repository, not broad write permissions it does not need.

### e) GitLab path: what's the difference between a stage and a job? What would dependencies: do that stages: doesn't?

A GitLab job is one unit of work, such as running tests or linting. A stage is a group/order level that controls when jobs run; for example, all jobs in the `test` stage can run before jobs in the `deploy` stage. `stages:` controls execution order, while `dependencies:` controls which previous job artifacts are downloaded by a job. So `dependencies:` is about artifact flow, not just job ordering.

## Task 2: Make It Fast and Smart

### Optimizations applied

I enabled Go caching through `actions/setup-go` by setting `cache: true` and using `app/go.mod` as the cache dependency path. Since the Go module is inside `app/`, this makes the cache key depend on the actual module file used by the project.

I added a Go version matrix for `vet` and `test`, running both jobs on Go `1.23` and Go `1.24`. This helps detect problems that only appear under one Go version.

I added path filters so the workflow only runs when files inside `app/` or `.github/workflows/ci.yml` change. This prevents documentation-only changes from wasting CI minutes.

I added a `ci-ok` aggregation job and made it the required branch-protection check. This avoids having to manually require every matrix check name such as `test (1.23)` and `test (1.24)`.

### Timing table

| Scenario | Wall-clock |
|----------|-----------:|
| Baseline: no cache, single Go version, no path filter | 1m 11s |
| With cache | 1m 5s |
| With cache + matrix | 1m 9s |

Caching slightly reduced the total wall-clock time, but the improvement was small because QuickNotes has no third-party dependencies. Most of the workflow time is spent on runner startup, checkout, Go setup, and installing/running tools rather than downloading modules. The matrix version still completed in a similar time because the Go 1.23 and Go 1.24 jobs run in parallel, although it starts more jobs overall.

### f) Why cache `go.sum`-keyed inputs and not build outputs?

Caching should be based on deterministic inputs. In a Go project, `go.sum` records exact dependency versions and checksums, so it is a safe basis for deciding whether the module cache can be reused. Build outputs are less safe to cache blindly because they can depend on the operating system, CPU architecture, Go version, compiler flags, and environment. Reusing the wrong build outputs could hide real build problems or make the CI behave inconsistently.

### g) What does `fail-fast: false` change in a matrix run, and when do you actually want `fail-fast: true`?

`fail-fast: false` means that if one matrix job fails, GitHub Actions still continues running the other matrix jobs. This is useful here because I want to see whether a failure happens only on Go `1.23`, only on Go `1.24`, or on both versions. `fail-fast: true` is useful when jobs are expensive and one failure already proves the pipeline is unusable, because cancelling the remaining jobs saves time and CI minutes.

### h) What is the risk of an attacker writing a cache from a malicious PR that protected branches later read?

The risk is cache poisoning. A malicious pull request could try to store attacker-controlled files in a cache, and then a later trusted workflow might restore that cache and use those files. This is dangerous if the cached content affects the build, test, or release process. GitHub reduces this risk by limiting cache access depending on the branch and event context, but workflows should still avoid caching sensitive files or generated executables from untrusted code.