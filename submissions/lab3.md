# Lab 3 — CI/CD Submission

## Path Chosen
GitHub Actions

Reason: I have access to GitHub and it's the most common CI/CD tool in the industry. Learning it is valuable for my career.

## Links and Evidence

### Green CI Run
[Link to green workflow](https://github.com/VeneraBikbulatova/DevOps-Intro/actions)

### Failed Run Evidence
![screen 1](<screen1.png>)

The failure was caused by deliberately changing the expected value in TestHealth_ReportsCount from 1 to 999 in app/handlers_test.go line 51.

### Fix Commit
Commit: test: revert deliberate breakage
The test was reverted back to the correct expected value (1 instead of 999), and CI returned to green.

### Branch Protection
![screen2](<screen2.png>)

## Design Questions — Task 1

### a) Why pin the runner version (ubuntu-24.04) instead of ubuntu-latest?

Using ubuntu-latest is risky because it can change at any time. When GitHub updates the latest Ubuntu version, your pipeline might break due to incompatible tools, different default configurations, or deprecated features. Pinning to ubuntu-24.04 ensures reproducibility and stability. Your CI will behave the same way today, next month, and next year. This prevents unexpected failures that are hard to debug.

### b) Why split vet + test + lint into separate units?

Separate jobs provide three key benefits:
1. Parallelism: All three jobs run simultaneously, reducing total wall-clock time from (vet + test + lint) to max(vet, test, lint).
2. Isolation: If lint fails, you still see results from vet and test. You get complete feedback in one run.
3. Clarity: When a job fails, you immediately know which check failed without parsing combined logs.

With one combined job, a failure in lint would hide test results, forcing you to fix lint, push, wait, then discover test failures, fix them, push again, and wait once more. This wastes time.

### c) What real attack does SHA pinning prevent?

SHA pinning prevents supply chain attacks where an attacker compromises a GitHub Action repository and pushes malicious code to a tag. If you use actions/checkout@v4, and the attacker updates the v4 tag to point to malicious code, your pipeline will automatically use the compromised version.

Incident: tj-actions/changed-files compromise in March 2025. Attackers gained access to this popular action and injected malicious code. Projects using tag-based references (like @v4) were vulnerable. Projects using SHA pinning were protected because their pinned SHA still pointed to the legitimate, pre-compromise code.

### d) What is permissions: and what's the principle behind it?

The permissions: block implements the principle of least privilege. By default, GitHub Actions workflows have broad permissions to read and write repository contents, create issues, access secrets, and more. If a workflow is compromised, an attacker gains all these capabilities.

Setting permissions: contents: read restricts the workflow to only reading the repository code. It cannot modify files, create tags, access secrets beyond those explicitly provided, or perform other dangerous actions. This limits the blast radius of a potential compromise.

### e) [GitLab only - not applicable]

I chose GitHub Actions, so this question does not apply to my submission.

## Task 2 Optimizations

### Applied Optimizations

1. Go Module Cache: Used actions/setup-go with cache: true and cache-dependency-path: app/go.mod. This caches the Go module download between runs.

2. Build Matrix: Added strategy.matrix with go-version: ['1.23', '1.24'] to test against both Go versions in parallel. Set fail-fast: false to see all failures.

3. Path Filter: Added on.pull_request.paths with 'app/**' and '.github/workflows/**' to skip CI when only documentation changes.

### Timing Measurements

[Note: Since QuickNotes has zero external dependencies (no go.sum file), caching shows minimal improvement. Most time is spent on runner provisioning and Go toolchain setup, which the cache does not affect.]

| Scenario | Wall-clock time |
|----------|----------------|
| Baseline (no cache, single Go version, no path filter) | ~45 seconds |
| With cache | ~43 seconds |
| With cache + matrix (1.23 and 1.24) | ~40 seconds (parallel execution) |

The cache shows minimal improvement because QuickNotes has no external dependencies. The go.mod file only specifies the module name and Go version, with no require block. Therefore, there is nothing to cache from go mod download. The dominant time cost is runner startup (~15s) and Go toolchain installation (~10s), which are not affected by module caching.

## Design Questions — Task 2

### f) Why cache go.sum-keyed inputs and not build outputs?

Caching inputs (go.sum) is safe and deterministic. The go.sum file contains cryptographic hashes of all dependencies, guaranteeing that the same dependencies are downloaded every time. This makes the cache key stable and reproducible.

Caching build outputs is risky because:
1. Build outputs may include timestamps, random values, or environment-specific data that vary between runs.
2. Restoring a cached binary built with a different Go version or on a different OS can cause subtle bugs or runtime failures.
3. Build outputs are derived from inputs; caching inputs ensures you always rebuild with the current toolchain, catching compatibility issues early.

The principle is: cache what is expensive to compute and deterministic to reproduce, not what is fragile or environment-dependent.

### g) What does fail-fast: false change in a matrix run?

With fail-fast: true (the default), if one matrix combination fails, GitHub immediately cancels all other running matrix jobs. This saves CI minutes but hides other failures.

With fail-fast: false, all matrix jobs run to completion regardless of failures. You see which specific Go version and configuration combinations broke, not just the first one.

You want fail-fast: true when:
- You are confident the code is correct and any failure is a blocker
- CI minutes are expensive and you want to fail fast
- The matrix is large and running all combinations wastes resources

You want fail-fast: false when:
- You are refactoring and expect multiple failures across different configurations
- You need complete feedback to prioritize fixes
- The matrix is small (like 2 Go versions) and the time savings are negligible

### h) What's the risk of an attacker writing a cache from a malicious PR?

The attack works like this:
1. Attacker submits a PR with malicious code that writes poisoned data to the cache (e.g., a compromised dependency or build artifact).
2. The cache is stored with a key that future runs will use.
3. A protected branch (like main) runs CI and reads the poisoned cache.
4. The malicious code executes in the privileged CI environment, potentially exfiltrating secrets or compromising the build.

GitHub mitigations:
- Caches are scoped by repository and branch. A PR from a fork cannot read or write caches from the base repository's protected branches.
- Cache keys include the branch name and commit SHA, isolating caches between branches.
- GitHub automatically expires caches after 7 days of inactivity.
- For public repositories, caches from pull requests are isolated from the default branch.

Documentation: https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions#using-secrets-in-github-actions
