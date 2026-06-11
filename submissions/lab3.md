# Lab 3 Submission - Yury Rybenko

## Path: GitHub Actions

---

## Task 1 - PR Gate

### CI config

`.github/workflows/ci.yml` - three independent jobs (`vet`, `test`, `lint`) triggered on push to `main` and every PR targeting `main`.

### Green CI run

<!-- TODO: paste link to green CI run after first push, e.g.:
https://github.com/<your-fork>/DevOps-Intro/actions/runs/<run-id>
-->

### Failed run evidence (Task 1.5)

<!-- TODO: paste screenshot or log URL of the red run (broken handlers_test.go),
     plus the revert commit SHA that turned it green again -->

### Branch protection screenshot

<!-- TODO: paste screenshot of Settings -> Branches -> branch protection rule for main -->

---

### Design questions (1.2)

**a) Why pin the runner version (`ubuntu-24.04`) instead of `ubuntu-latest`?**

`ubuntu-latest` is a moving pointer that GitHub can silently update to a new Ubuntu release. When that happens, pre-installed tool versions change and builds break without any code change. Pinning `ubuntu-24.04` keeps the environment reproducible across every run.

**b) Why split `vet`, `test`, and `lint` into separate jobs?**

A single combined job stops on first failure — if `vet` fails you never see whether tests pass. Separate jobs run in parallel (faster wall-clock) and give independent pass/fail signals, so branch protection can require each one and you know exactly which check broke.

**c) What real attack does SHA pinning prevent?**

The **tj-actions/changed-files supply-chain attack (March 14-15, 2025)**. An attacker compromised the tj-actions account and force-pushed malicious code onto existing version tags like `v45`. Any workflow using `@v45` fetched the poisoned commit and leaked secrets into public logs. SHA pinning prevents this — a tag can be repointed, but a pinned commit hash cannot be silently swapped.

**d) What is `permissions:` and what principle is behind it?**

`permissions:` restricts what the auto-injected `GITHUB_TOKEN` can do. By default the token has broad write access. Setting `permissions: contents: read` applies **least privilege** — the token can only read the repo, so a compromised action cannot push code or modify issues using it.
