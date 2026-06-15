# Platform choice

I picked GitHub way since I can login on it.

# Task 1 — Write the PR Gate

## 1.2: Design questions

1. Why pin the runner version (ubuntu-24.04) instead of ubuntu-latest? What breaks otherwise?

Answer:
When new Ubuntu version is released, some dependency updates can break my CI, which can result in long time of new code delivery.

2. Why split vet + test + lint into separate units? What would happen with one combined job?

Answer:
Firstly, splitting these jobs leads to parallelizing them and spending less time for CI. Secondly, if I run then in one job (hence sequentially), then if first job failed, I don't see the feedback for second and third.

3. GH path: what real attack does SHA pinning prevent? Cite the date + name of the incident from Lecture 3

Answer:
Incident CVE-2025-30066 took place on March 14, 2025. Attackers added malicious commit that printed secrets to logs. Ones that did not specify the exact SHA version of `tj-actions/changed-files` could automatically get malicious version of this action. That's why it's important to set exact hash of used GitHub Action.

4. GH path: what is permissions: and what's the principle behind it?

Answer:
In GitHub Actions `permissions` are used to set correct permissions for different operations within workflow. For example, `deployments: write` allows to create a new deployment. I decided to choose `contents: read` since I need nothing but listing the commits within `go vet`, `go test`, `go lint`.

## Link to green CI run

https://github.com/ilnarkhasanov/DevOps-Intro/actions/runs/27507991821/job/81302633680

## Screenshot of the failed run from 1.5, plus the fix commit

![alt text](static/failed-ci.png)

Fix commit: ![alt text](static/fix-commit.png)

## Branch protection rules

![alt text](static/branch-protection.png)

Additionally, I removed the possibility to bypass checks:

![alt text](static/no-bypass.png)

# Task 2 — Make It Fast and Smart

## Timing table

| Scenario | Wall-clock |
|----------|-----------:|
| Baseline: no cache, single Go version, no path filter | 36s |
| With cache | 41s |
| With cache + matrix | 40s |

## Description of optimizations

- Caching: actually there are no dependencies, therefore there is nothing to cache. Hence, adding hashing did not speed up CI. Probably, the caching work in CI is the reason why there are 5 seconds more.
- Matrix: matrix increased the time, but CI now compares several versions. It shifts-left the situation when our program fail on some Go versions.

## Design questions

Why cache go.sum-keyed inputs and not build outputs?

Answer:
`go.sum` can be used as a hash for cache and it does not depend on environment. Build outputs do. Therefore, better to use `go.sum`-keyed inputs.

What does `fail-fast: false` change in a matrix run, and when do you actually want fail-fast: true?

Answer:

`fail-fast: false` makes all matrix values run even if some of them fail. We want it if we want to get a feedback for all version. Probably we do not want it if jobs are expensive and we only care if anything is broken.

What's the risk of an attacker writing a cache from a malicious PR that protected branches later read?

Answer:

Attacker can craft a cache where backdoored package included. If this cache will be used on a protected branch, app can be deployed with attacker's code.
