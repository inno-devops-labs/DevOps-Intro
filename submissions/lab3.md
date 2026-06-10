# Lab 3 — CI/CD Pipeline
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


## Path: GitHub Actions


## PR link:https://github.com/linxel/DevOps-Intro/pull/3

