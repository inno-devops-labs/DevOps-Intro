# Lab 3 — CI/CD Pipeline

## Path: GitHub Actions. 
I chose GitHub Actions because my fork is on GitHub and it works without extra setup. It is also the default path recommended in the lab instructions.

## PR link:https://github.com/linxel/DevOps-Intro/pull/3

<img width="1033" height="537" alt="image" src="https://github.com/user-attachments/assets/3af62d6f-6c7d-4080-b86c-ffa287c7a98d" />

<img width="1013" height="993" alt="image" src="https://github.com/user-attachments/assets/8dc38d8a-3fcd-463a-99c4-0829e25504b2" />

<img width="864" height="557" alt="image" src="https://github.com/user-attachments/assets/004ac78d-0396-4a9e-ab46-f20164f5d590" />


a) Why pin the runner version (ubuntu-24.04) instead of ubuntu-latest? What breaks otherwise?
ecause ubuntu-latest changes over time. Today it points to Ubuntu 24.04. Tomorrow it may point to Ubuntu 26.04. New Ubuntu versions have different system packages, different Go versions, different libraries. Your pipeline that works today may break tomorrow without any code change. Pinning to ubuntu-24.04 makes sure every run uses the exact same environment. This is called reproducibility.

b) Why split vet + test + lint into separate units? What would happen with one combined job?
First, they run in parallel so the total time is only as long as the longest job, not the sum of all three. Second, if lint fails but tests pass you see immediately which one broke. In one big job you only see something failed. Third, you can restart only the failed job instead of running all three again.

c) GH path: what real attack does SHA pinning prevent? Cite the date + name of the incident from Lecture 3
SHA pinning prevents a supply chain attack. An attacker who gains access to a GitHub Action maintainers account can overwrite a Git tag like v4 to point to malicious code. When your pipeline uses at v4 it automatically downloads the malicious version and runs it. The incident is tj-actions changed-files in March 2025. The attacker rewrote all tags to a malicious version exposing secrets from thousands of public CI runs.

d) GH path: what is permissions: and what's the principle behind it?
Permissions controls what the GITHUB_TOKEN is allowed to do. The principle is least privilege. Give only the permissions that are absolutely needed nothing more. For example contents read means the token can read code but cannot write or delete anything. This limits damage if a malicious action runs or secrets leak.

e) GitLab path: what's the difference between a stage and a job? What would dependencies: do that stages: doesn't?
In GitLab CI, a stage is a group of jobs that run at the same time. Stages run in order. For example, you might have a test stage and then a deploy stage. All jobs in the test stage finish before any job in the deploy stage starts. A job is a single unit of work, like running go test or building a binary. The dependencies keyword does something different. It controls which artifacts from previous jobs get downloaded into the current job. For example, a deploy job might depend on a build job and download the binary artifact. Stages controls the order of execution. Dependencies controls which data flows between jobs, even between jobs in different stages. Stages alone cannot control artifact flow. Dependencies is more granular and lets you skip downloading artifacts you do not need.

## Task 2 — Make It Fast and Smart

### Optimizations applied:
1. Cache — added cache: true to actions/setup-go
2. Matrix — run vet and test on Go 1.23 and 1.24 in parallel with fail-fast: false
3. Path filter — pipeline only runs on changes to app/ or .github/workflows/ci.yml

### Timing table:
| Scenario | Time (s) |
| Baseline | 26 |
| With cache | 23 |
| With cache + matrix | 41 |

### Answers:

f) Because go.sum is deterministic. The same go.sum always downloads the same modules. Build outputs depend on Go version, CPU architecture, OS, and compiler flags. Caching outputs is unreliable.

g) With fail-fast: true, if one matrix job fails GitHub cancels all other running jobs. With fail-fast: false, all jobs run to completion even if some fail. You want false to see results for all Go versions. You want true when jobs are expensive and you want to stop early after first failure.

h) An attacker could poison the cache with malicious code. GitHub mitigates this by isolating caches from forks. Caches from PRs in forks are not accessible to protected branches.
