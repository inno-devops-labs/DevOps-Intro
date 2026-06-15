# Lab 3 - CI/CD: PR-Gated Pipeline

## Chosen path:

I decided to work on Github not Gitlab since I am more familiar with Github and I have used it for my previous projects. I also find Github Actions to be more intuitive and easier to set up than Gitlab CI/CD.

## Task 1 - Write the PR gate

### CI configuration

The CI workflow is defined in:

```text
.github/workflows/ci.yml
```

The workflow is configured to run on:

- pushes to `main`
- pull requests targeting `main`

The workflow uses path filters so it runs only when the application or workflow changes:

- `app/**`
- `.github/workflows/ci.yml`

### Independent CI jobs

The workflow defines three independent GitHub Actions jobs:

- `vet` runs `go vet ./...` from `app/`
- `test` runs `go test -race -count=1 ./...` from `app/`
- `lint` runs `golangci-lint run` from `app/`

The lint job pins `golangci-lint` to:

```text
v2.5.0
```

### Runtime and permissions

The workflow pins the runner image to:

```text
ubuntu-24.04
```

The workflow declares least-privilege permissions:

```yaml
permissions:
  contents: read
```

The GitHub Actions used by the workflow are pinned to full commit SHAs with the readable version tags in comments.

### Evidence to add after pushing

Red CI run:
[Link to red CI commit](https://github.com/software-engineering-toolkit/DevOps-Intro/pull/3/changes/bb2556c0b3d30a8eea7f4f3746da2478b477eea3)
![Red CI run](../images/lab3/red_ci.png)

Green CI run image:
[Link to green CI run](https://github.com/software-engineering-toolkit/DevOps-Intro/pull/3/changes/33e23cf71d55bb68d6c44f06c78fe0e9cd7e7230)
![Green CI run](../images/lab3/green_ci.png)

Branch protection evidence:
![Branch protection](../images/lab3/branch_protection.png)

## Design questions

### Why pin the runner version instead of `ubuntu-latest`?

Pinning `ubuntu-24.04` makes the CI environment predictable. `ubuntu-latest` is a moving alias, so GitHub can retarget it to a newer image with different system packages, compiler behavior, shell behavior, OpenSSL versions, or preinstalled tools. A workflow that passed yesterday could fail after the alias changes even though the repository code did not change. Pinning the runner makes environment upgrades intentional instead of accidental.

### Why split vet, test, and lint into separate units?

Splitting `vet`, `test`, and `lint` into separate jobs makes failures easier to diagnose and lets GitHub Actions run independent checks in parallel. If all three commands were combined into one job, the first failing command would stop the rest unless extra shell handling was added. That would hide whether the other checks also fail and would make branch protection less precise because there would be only one combined status check instead of separate quality gates.

### What real attack does SHA pinning prevent?

SHA pinning prevents a workflow from silently running different action code when a tag or branch is moved. Lecture 3 cites the March 2025 `tj-actions/changed-files` supply-chain incident: the action was compromised, and the attacker rewrote tags to point to malicious code that leaked secrets from public CI runs. Pinning to a full commit SHA protects against this class of tag-rewrite attack because the workflow keeps using the exact reviewed commit instead of whatever code the tag points to later.

### What is `permissions:` and what principle is behind it?

`permissions:` controls the scopes granted to the automatic `GITHUB_TOKEN` available inside a GitHub Actions workflow or job. Setting `contents: read` gives the workflow only enough access to read repository contents. The principle is least privilege: CI jobs should receive only the permissions they need, so a compromised action or command has less ability to write code, modify pull requests, publish packages, or change repository settings.

## Task 2 - Make it fast and smart

### Timing measurements

| Scenario                                               | Wall-clock |
| ------------------------------------------------------ | ---------- |
| Baseline (no cache, single Go version, no path filter) | 37 s       |
| With cache                                             | 36 s       |
| With cache + matrix                                    | 34 s       |

### Optimizations applied

The first optimization was dependency caching through `actions/setup-go`. The workflow enables the built-in Go cache and uses `app/go.mod` as the cache dependency path because this repository does not currently contain `app/go.sum`.

The second optimization was a Go version matrix for the `vet` and `test` jobs. Those jobs now run against Go `1.23` and Go `1.24` in parallel with `fail-fast: false`, which checks compatibility across both toolchains without hiding failures in the second matrix cell.

The third optimization was path filtering. The workflow now runs only when files under `app/**` or `.github/workflows/ci.yml` change, so root-level documentation, lab notes, and submission-only edits do not spend CI minutes.

### Why cache `go.sum`-keyed inputs and not build outputs?

Dependency inputs are deterministic because Go modules are pinned by module metadata and checksums. A cache key based on dependency files changes when the dependency graph changes, so the restored cache matches the code's expected inputs. Build outputs are less safe as cache boundaries because they can depend on the Go version, compiler flags, operating system, architecture, race detector settings, and other environment details. Caching the wrong build output can create confusing or unsafe results, while caching downloaded modules just avoids repeated network work.

In this repository, `app/go.mod` is used as the cache dependency path because `app/go.sum` is not present. If `app/go.sum` appears later, it should be used as the stronger cache key input because it records exact dependency checksums.

### What does `fail-fast: false` change in a matrix run, and when do you actually want `fail-fast: true`?

With `fail-fast: false`, GitHub Actions keeps the remaining matrix jobs running even if one matrix cell fails. That is useful here because the goal is to see whether Go `1.23`, Go `1.24`, or both versions fail.

`fail-fast: true` is useful when matrix jobs are expensive and one failure is enough to make the whole result unusable. For example, a deployment matrix or a long integration-test matrix might stop early to save time and CI minutes after the first clear failure.

### What's the risk of an attacker writing a cache from a malicious PR that protected branches later read?

The risk is cache poisoning. If an attacker can cause CI to save malicious content under a cache key that trusted branches later restore, the trusted branch could run with attacker-controlled dependencies, tools, or generated files. That can turn a low-privilege pull request into a later trusted-branch compromise.

GitHub mitigates this with cache access restrictions: workflow runs can restore caches from their own branch and from the default branch, but protected branches should not read arbitrary caches written by untrusted pull request branches. This is also why caches must not contain secrets. GitHub's dependency caching documentation warns that anyone with read access can open a pull request and access cache contents, and fork pull requests can access base-branch caches.

## Bonus Task - Pipeline Performance Investigation

### Goal result

The full GitHub Actions pipeline completes under the bonus target of 90 seconds.

Final measured wall-clock time:

```text
30 s
```

### Additional optimizations beyond Task 2

The first bonus optimization was setting:

```yaml
GOFLAGS: -buildvcs=false
```

This tells Go not to stamp VCS metadata into builds or package loading work. The CI pipeline does not need build-time Git metadata, so skipping it reduces unnecessary repository inspection during CI.

The second bonus optimization was narrowing the workflow path filters. Instead of triggering on every file under `app/**`, the workflow now triggers on Go source files, Go module files, `app/Makefile`, `app/seed.json`, and `.github/workflows/ci.yml`. This keeps CI active for code and build-relevant changes while avoiding a full pipeline for app documentation-only edits such as `app/README.md`.

The third attempted optimization was explicit shallow checkout with disabled persisted credentials. This changed the run from 32 seconds to 40 seconds, so it was removed because it made the pipeline slower.

The final kept optimization was limiting Go cache restore/save to the `test` matrix only. The smaller `vet` and `lint` jobs no longer pay cache overhead, while the race-enabled test job still benefits from caching.

### Before and after measurements

| Optimization applied                                                   | Before (s) | After (s) | Saving |
| ---------------------------------------------------------------------- | ---------: | --------: | -----: |
| `GOFLAGS=-buildvcs=false`                                              |         34 |        32 |     -2 |
| Narrow app path filters                                                |         32 |        32 |      0 |
| Explicit shallow checkout and disabled persisted credentials, reverted |         32 |        40 |     +8 |
| Limit Go cache restore/save to `test` job                              |         32 |        30 |     -2 |
| **Total wall-clock, kept optimizations**                               |     **34** |    **30** | **-4** |

### Bottleneck analysis

The remaining time appears to be dominated by GitHub Actions job orchestration and tool setup rather than the QuickNotes application code itself. QuickNotes is a small Go service with a small test suite, so `go vet` and `go test -race` have little application work to do once the runner and Go toolchain are ready. To make the pipeline shorter by changing QuickNotes itself, the main option would be keeping tests focused and avoiding slow integration-style tests in the PR gate unless they are split into a separate job. I would stop optimizing this PR gate around 30 seconds because it is already far below the 90 second target and further changes risk adding complexity for very small savings. If the project grows later, I would optimize again only when the slowest step is clearly identified from per-step GitHub Actions timings.
